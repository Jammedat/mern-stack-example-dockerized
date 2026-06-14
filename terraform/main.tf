provider "aws" {
  region = "us-east-1"
}

# ==========================================
# INPUT VARIABLES & CONFIGURATION
# ==========================================
variable "mongo_atlas_uri" {
  type        = string
  description = "The production MongoDB Atlas connection string"
  sensitive   = true
}

# ==========================================
# PRIVATE SECURITY VAULT (SECRETS MANAGER)
# ==========================================
resource "aws_secretsmanager_secret" "db_secret" {
  name                    = "production-mongodb-uri"
  recovery_window_in_days = 0 
}

resource "aws_secretsmanager_secret_version" "db_secret_val" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = var.mongo_atlas_uri
}

# ==========================================
# SECURE NETWORK ISOLATION ENGINE (VPC)
# ==========================================
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# ==========================================
# FIREWALL AND SECURITY CONTROL GROUPS
# ==========================================
resource "aws_security_group" "alb_sg" {
  name   = "mern-alb-security-group"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_tasks_sg" {
  name   = "mern-ecs-tasks-security-group"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.alb_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ==========================================
# IMAGE MANAGEMENT (REGISTRIES)
# ==========================================
resource "aws_ecr_repository" "backend" { name = "mern-backend" }
resource "aws_ecr_repository" "frontend" { name = "mern-frontend" }

# ==========================================
# TRAFFIC COP ENGINE (LOAD BALANCER)
# ==========================================
resource "aws_lb" "main" {
  name               = "mern-prod-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public.id, aws_subnet.private.id]
}

resource "aws_lb_target_group" "frontend" {
  name        = "tg-mern-frontend"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  health_check { path = "/" }
}

resource "aws_lb_target_group" "backend" {
  name        = "tg-mern-backend"
  port        = 5050
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  health_check { 
    path = "/record" 
    port = "5050"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener_rule" "api_routing" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
  condition {
    path_pattern {
      values = ["/record", "/record/*"]
    }
  }
}

# ==========================================
# ORCHESTRATION CLUSTER (SERVERLESS FARGATE)
# ==========================================
resource "aws_ecs_cluster" "prod_cluster" {
  name = "mern-production-cluster"
}

# HARDENED BACKEND COMPONENT
resource "aws_ecs_task_definition" "backend" {
  family                   = "mern-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name      = "backend"
    image     = "${aws_ecr_repository.backend.repository_url}:latest"
    essential = true
    portMappings = [{
      containerPort = 5050
      hostPort      = 5050
    }]
    readonlyRootFilesystem = true
    mountPoints = [{
      sourceVolume  = "tmp-storage"
      containerPath = "/tmp"
    }]
    secrets = [{
      name      = "ATLAS_URI"
      valueFrom = aws_secretsmanager_secret.db_secret.arn
    }]
  }])

  volume {
    name = "tmp-storage"
  }
}

# HARDENED FRONTEND COMPONENT
resource "aws_ecs_task_definition" "frontend" {
  family                   = "mern-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name      = "frontend"
    image     = "${aws_ecr_repository.frontend.repository_url}:latest"
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
  }])
}

# RUNTIME LIVE SERVICES
resource "aws_ecs_service" "backend" {
  name            = "backend-service"
  cluster         = aws_ecs_cluster.prod_cluster.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = [aws_subnet.private.id]
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = 5050
  }
}

resource "aws_ecs_service" "frontend" {
  name            = "frontend-service"
  cluster         = aws_ecs_cluster.prod_cluster.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = [aws_subnet.public.id]
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = 80
  }
}

# OUTPUTS: Prints your public URL to your screen when done
output "load_balancer_url" {
  value       = "http://${aws_lb.main.dns_name}"
  description = "The public web address to visit your live production stack"
}
