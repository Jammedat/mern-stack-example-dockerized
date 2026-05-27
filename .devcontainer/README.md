# Codespaces & Dev Container Setup

This project is configured to work seamlessly in GitHub Codespaces or with VS Code Dev Containers.

## Starting with Codespaces

1. **Click "Code" → "Codespaces" → "Create codespace on main"** from the GitHub repo
2. The devcontainer will automatically:
   - Spin up a MongoDB instance (Atlas Local)
   - Install all dependencies
   - Seed sample data

## Using with VS Code Dev Containers

1. **Install the Dev Containers extension** in VS Code
2. **Open the repo locally** and run: `Ctrl+Shift+P` → "Dev Containers: Reopen in Container"
3. VS Code will build the environment and start MongoDB

## Accessing Services

Once the devcontainer is running:

| Service | URL | Purpose |
|---------|-----|---------|
| React App | http://localhost:5173 | Frontend (Vite dev server) |
| Express API | http://localhost:5050 | Backend REST API |
| MongoDB | mongodb://admin:mongodb@localhost:27017 | Database (no browser UI) |
| MongoDB VS Code Extension | N/A | Query database directly in VS Code |

## Quick Start in Codespaces

Once the devcontainer is fully loaded (wait for "Poststart" to complete):

```bash
# Terminal 1: Start the Express server
cd mern/server
npm start

# Terminal 2: Start the React dev server
cd mern/client
npm run dev
```

Then open http://localhost:5173 in your browser.

## Database Credentials

- **Host**: `mongodb` (inside container) or `localhost:27017` (from host)
- **Username**: `admin`
- **Password**: `mongodb`
- **Database**: `employees`

## Seeding Sample Data

The devcontainer automatically seeds sample data on startup. To manually reseed:

```bash
cd mern/server
node seed.js
```

## VS Code Extensions

The devcontainer includes these extensions:

- **MongoDB for VS Code** — Query your MongoDB directly from VS Code
- **TypeScript** — TypeScript language support
- **Prettier** — Code formatter

## Troubleshooting

### MongoDB connection issues
```bash
# Check if MongoDB is running
mongosh -u admin -p mongodb --eval "db.adminCommand('ping')"
```

### Port conflicts
If ports 5050, 5173, or 27017 are already in use:
- **Codespaces**: Automatic port forwarding handles this
- **Local Dev Container**: Modify `docker-compose.yml` to use different ports

### Rebuild the devcontainer
```bash
# VS Code: Ctrl+Shift+P → "Dev Containers: Rebuild Container"
# CLI: devcontainer build --workspace-folder .
```
