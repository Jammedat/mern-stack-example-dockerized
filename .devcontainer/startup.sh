#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="/workspaces/${localWorkspaceFolderBasename:-$(basename "$PWD")}"
SERVER_DIR="$ROOT_DIR/mern/server"
CLIENT_DIR="$ROOT_DIR/mern/client"
CONFIG_FILE="$SERVER_DIR/config.env"
ATLAS_URI_VALUE="${ATLAS_URI:-mongodb://localhost:27017/}"
PORT_VALUE="${PORT:-5050}"

ensure_config() {
  cat > "$CONFIG_FILE" <<EOF
ATLAS_URI=$ATLAS_URI_VALUE
PORT=$PORT_VALUE
EOF

  echo "Wrote $CONFIG_FILE with ATLAS_URI and PORT."
}

wait_for_mongodb() {
  local max_tries=30
  local try=1

  until node --input-type=module -e "import { MongoClient } from 'mongodb'; const c = new MongoClient(process.env.ATLAS_URI); await c.connect(); await c.db('admin').command({ ping: 1 }); await c.close();" >/dev/null 2>&1; do
    if (( try >= max_tries )); then
      echo "MongoDB did not become ready in time."
      return 1
    fi
    echo "Waiting for MongoDB... ($try/$max_tries)"
    try=$((try + 1))
    sleep 2
  done
}

seed_database() {
  (
    cd "$SERVER_DIR"
    node --env-file=config.env seed.js > /tmp/mern-seed.log 2>&1
  )

  echo "Seed completed (log: /tmp/mern-seed.log)."
}

verify_seed_data() {
  local count

  count=$(
    cd "$SERVER_DIR" &&
      node --env-file=config.env --input-type=module -e "import { MongoClient } from 'mongodb'; const c = new MongoClient(process.env.ATLAS_URI); await c.connect(); const n = await c.db('employees').collection('records').countDocuments(); console.log(n); await c.close();"
  )

  echo "Seed verification: employees.records has $count documents."

  if [[ "$count" -le 0 ]]; then
    echo "Seed verification failed: no documents found in employees.records."
    echo "Seed log tail:"
    tail -n 50 /tmp/mern-seed.log || true
    return 1
  fi
}

start_server_if_needed() {
  if pgrep -f "node --env-file=config.env server" >/dev/null; then
    echo "Express server already running."
    return
  fi

  (
    cd "$SERVER_DIR"
    nohup npm start > /tmp/mern-server.log 2>&1 &
  )
  echo "Started Express server (log: /tmp/mern-server.log)."
}

start_client_if_needed() {
  if pgrep -f "vite" >/dev/null; then
    echo "Vite dev server already running."
    return
  fi

  (
    cd "$CLIENT_DIR"
    nohup npm run dev -- --host 0.0.0.0 > /tmp/mern-client.log 2>&1 &
  )
  echo "Started Vite dev server (log: /tmp/mern-client.log)."
}

ensure_config
wait_for_mongodb
seed_database
verify_seed_data
start_server_if_needed
start_client_if_needed

echo "Codespaces startup complete."
