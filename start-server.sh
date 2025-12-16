#!/bin/bash
# Start the Image Enhancement API Server

# Get project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# Activate virtual environment
source venv/bin/activate

# Start the server
echo "Starting Image Enhancement API Server on http://localhost:8000"
python server.py
