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
  local max_tries=60
  local try=1

  # Atlas Local uses a replica set — wait until a writable primary is elected,
  # not just until mongod responds to ping (which happens before primary election).
  until node --input-type=module -e "
    import { MongoClient } from 'mongodb';
    const c = new MongoClient(process.env.ATLAS_URI);
    await c.connect();
    const h = await c.db('admin').command({ hello: 1 });
    await c.close();
    if (!h.isWritablePrimary) throw new Error('no primary yet');
  " >/dev/null 2>&1; do
    if (( try >= max_tries )); then
      echo "MongoDB primary did not become ready in time."
      return 1
    fi
    echo "Waiting for MongoDB primary... ($try/$max_tries)"
    try=$((try + 1))
    sleep 2
  done
  echo "MongoDB primary is ready."
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

echo "Codespaces startup complete."
