# MQTT Sparkplug B Python Client & Vue Dashboard

## Overview

This project is a full-stack application for real-time monitoring of industrial machine metrics using the Sparkplug B MQTT protocol. It consists of a Python-based backend (FastAPI) that connects to an MQTT broker, decodes Sparkplug B payloads, and exposes live tag data via REST API and WebSocket. The frontend is a Vue 3 + Vite dashboard for visualizing machine OEE (Overall Equipment Effectiveness) and related metrics in real time.

---

## Architecture

- **Backend (Python/FastAPI)**
  - Connects to an MQTT broker, subscribes to Sparkplug B topics, decodes metrics, and maintains the latest values in memory.
  - Exposes a REST API for querying tag names and values.
  - Provides a WebSocket endpoint for real-time tag updates.
  - Serves a simple web UI (or can be used with the Vue frontend).
- **Frontend (Vue 3 + Vite)**
  - Connects to the backend WebSocket for live updates.
  - Displays a dashboard of machines, showing OEE, availability, performance, quality, and status.
  - Allows sorting and visualization of machine data.
- **Dockerized**
  - Dockerfiles and a `docker-compose.yml` are provided for easy setup of both backend and frontend.

### Data Flow

1. **MQTT Client** (backend) subscribes to `spBv1.0/#` topics.
2. On receiving Sparkplug B messages, it decodes metrics and updates the in-memory state.
3. **WebSocket** clients (frontend) receive real-time updates for any tag changes.
4. **REST API** allows querying all tag names or individual tag values.
5. **Vue Dashboard** connects via WebSocket and displays live OEE and machine metrics.

---

## Features

- Real-time OEE dashboard for multiple machines
- Live updates via WebSocket
- REST API for tag queries
- MQTT Sparkplug B protocol support
- Dockerized development environment

---

## Setup Instructions

### Prerequisites
- Docker & Docker Compose (recommended)
- Or: Python 3.11+, pip, Node.js (for manual setup)
- Access to an MQTT broker (e.g., EMQX or Ignition's built-in broker)

### Quick Start (Docker Compose)

1. **Clone the repository**
2. **Start services:**
   ```sh
   docker-compose up --build
   ```
3. **Access the applications:**
   - Frontend: [http://localhost:5173](http://localhost:5173)
   - Backend API & WebSocket: [http://localhost:8000](http://localhost:8000)
   - FastAPI docs: [http://localhost:8000/docs](http://localhost:8000/docs)

### Manual Setup

#### Backend
1. Install dependencies:
   ```sh
   cd backend
   pip install -r requirements.txt
   ```
2. Connect to an MQTT broker (e.g., Ignition] on port 1883 or as configured)
3. Run the backend:
   ```sh
   python app.py
   ```
4. Backend will be available at [http://localhost:8000](http://localhost:8000)

#### Frontend
1. Install dependencies:
   ```sh
   cd frontend
   npm install
   ```
2. Run the development server:
   ```sh
   npm run dev
   ```
3. Frontend will be available at [http://localhost:5173](http://localhost:5173)

---

## API & WebSocket

### REST API (Backend)
- `GET /api/tags` — List all tag names
- `GET /api/tags/{tag_name}` — Get the current value for a tag
- `GET /` — Serves the web UI (`index.html`)

### WebSocket
- Connect to `ws://localhost:8000/ws` for real-time tag updates (used by the Vue dashboard)

---

## Configuration

The following environment variables can be set (see `docker-compose.yml` and `app.py`):

- `MQTT_HOST` (default: `host.docker.internal` or as set in Docker Compose)
- `MQTT_PORT` (default: `1883`)
- `MQTT_USERNAME`, `MQTT_PASSWORD` (for broker authentication)
- `MACHINES_TO_MONITOR` (comma-separated list of machine names)
- `OEE_GREEN_THRESHOLD`, `OEE_ORANGE_THRESHOLD` (for frontend display)

---

## Project Structure

```
vue-sparkplug/
├── backend/
│   ├── app.py                # Main FastAPI app, MQTT client, WebSocket, REST API
│   ├── requirements.txt      # Python dependencies
│   ├── sparkplug_b_pb2.py    # Protobuf definitions for Sparkplug B
│   └── ...
├── frontend/
│   ├── src/
│   │   ├── App.vue           # Main Vue app
│   │   ├── components/
│   │   │   └── MachineDashboard.vue # Dashboard component
│   │   └── ...
│   ├── package.json          # Frontend dependencies and scripts
│   └── ...
├── docker-compose.yml        # Multi-service orchestration
├── dockerfiles/              # Dockerfiles for backend and frontend
└── README.md                 # This file
```

---

## Dependencies

### Backend
- `paho-mqtt` — MQTT client
- `protobuf` — Protocol Buffers for Sparkplug B
- `fastapi` — Web framework
- `uvicorn[standard]` — ASGI server
- `websockets` — WebSocket support

### Frontend
- `vue` — Vue 3 framework
- `vite` — Build tool
- `apexcharts`, `vue3-apexcharts` — Charting components
