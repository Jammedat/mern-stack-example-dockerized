# MERN Stack Employee Records App with MongoDB Atlas

A full-stack CRUD application built with MongoDB, Express, React, and Node.js (MERN). Demonstrates how to manage employee records — create, read, update, and delete — using MongoDB Atlas as the database and a REST API backend.

Companion code for the [MERN Stack Tutorial](https://www.mongodb.com/languages/mern-stack-tutorial?utm_campaign=devrel&utm_medium=github&utm_content=mern.stack.example&utm_term=learning.fuel).

[![CI](https://github.com/mongodb-developer/mern-stack-example/actions/workflows/main.yaml/badge.svg)](https://github.com/mongodb-developer/mern-stack-example/actions/workflows/main.yaml)

## Features

- List all employee records stored in MongoDB Atlas
- Create a new employee record (name, position, level)
- Edit an existing record in place
- Delete a record
- React frontend (Vite + Tailwind CSS) communicating with an Express REST API

## Architecture Overview

```
┌─────────────────────┐       REST (JSON)      ┌──────────────────────────┐
│   React (Vite)      │ ─────────────────────► │  Express API             │
│   mern/client       │ ◄───────────────────── │  mern/server             │
│   :5173             │                        │  :5050                   │
└─────────────────────┘                        └───────────┬──────────────┘
                                                           │ MongoDB Node.js driver
                                                           ▼
                                               ┌──────────────────────────┐
                                               │  MongoDB Atlas           │
                                               │  database: employees     │
                                               │  collection: records     │
                                               └──────────────────────────┘
```

- **Frontend**: React 18, Vite, Tailwind CSS, React Router
- **Backend**: Node.js, Express 4, MongoDB Node.js Driver 6
- **Database**: MongoDB Atlas — `employees` database, `records` collection

## Quick Start

### Prerequisites

- Node.js 20+ (required for `node --env-file` support)
- A free [MongoDB Atlas](https://www.mongodb.com/atlas?utm_campaign=devrel&utm_medium=github&utm_content=mern.stack.example&utm_term=learning.fuel) cluster

### 1. Configure the server

Create `mern/server/config.env`:

```
ATLAS_URI=mongodb+srv://<username>:<password>@<cluster>.mongodb.net/
PORT=5050
```

### 2. Seed the database (optional)

```bash
cd mern/server
node seed.js
```

### 3. Start the API server

```bash
cd mern/server
npm install
npm start
```

### 4. Start the React app

```bash
cd mern/client
npm install
npm run dev
```

Open [http://localhost:5173](http://localhost:5173).

## MongoDB Features Demonstrated

| Feature | Where |
|---|---|
| [MongoDB Node.js Driver](https://www.mongodb.com/docs/drivers/node/current/?utm_campaign=devrel&utm_medium=github&utm_content=mern.stack.example&utm_term=learning.fuel) | `mern/server/db/connection.js` |
| [CRUD operations](https://www.mongodb.com/docs/manual/crud/?utm_campaign=devrel&utm_medium=github&utm_content=mern.stack.example&utm_term=learning.fuel) | `mern/server/routes/record.js` |
| [MongoDB Atlas](https://www.mongodb.com/atlas?utm_campaign=devrel&utm_medium=github&utm_content=mern.stack.example&utm_term=learning.fuel) | Atlas URI in `config.env` |
| [Server API version](https://www.mongodb.com/docs/manual/reference/stable-api/?utm_campaign=devrel&utm_medium=github&utm_content=mern.stack.example&utm_term=learning.fuel) | `ServerApiVersion.v1` in connection |

## Additional Resources

- [MERN Stack Tutorial](https://www.mongodb.com/languages/mern-stack-tutorial?utm_campaign=devrel&utm_medium=github&utm_content=mern.stack.example&utm_term=learning.fuel) — step-by-step walkthrough of this codebase

## Disclaimer

Use at your own risk; not a supported MongoDB product
