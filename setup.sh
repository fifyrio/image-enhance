#!/bin/bash
# Setup script for Image Enhancement Pipeline
# Installs dependencies for both GFPGAN and Real-ESRGAN

set -e  # Exit on error

# Get project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

echo "===================================="
echo "Image Enhancement Pipeline Setup"
echo "===================================="
echo ""

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip

# Install GFPGAN
echo ""
echo "Installing GFPGAN dependencies..."
cd GFPGAN
pip install -r requirements.txt
# Clean up any existing .eggs directory to avoid conflicts
rm -rf .eggs
pip install -e .
cd ..

# Install Real-ESRGAN
echo ""
echo "Installing Real-ESRGAN dependencies..."
cd Real-ESRGAN
pip install -r requirements.txt
# Clean up any existing .eggs directory to avoid conflicts
rm -rf .eggs
pip install -e .
cd ..

# Download pretrained models
echo ""
echo "Downloading pretrained models..."
echo "1/2: Downloading GFPGAN models..."
cd GFPGAN
if [ -f "scripts/download_pretrained_models.py" ]; then
    python scripts/download_pretrained_models.py
else
    echo "Warning: GFPGAN download script not found, skipping..."
fi
cd ..

echo "2/2: Downloading Real-ESRGAN models..."
cd Real-ESRGAN
if [ -f "scripts/download_models.py" ]; then
    python scripts/download_models.py
else
    echo "Warning: Real-ESRGAN download script not found, skipping..."
fi
cd ..

echo ""
echo "===================================="
echo "✓ Setup complete!"
echo "===================================="
echo ""
echo "You can now run the pipeline:"
echo "  ./run.sh input/your_image.jpg"
echo ""
echo "To skip Real-ESRGAN processing:"
echo "  ./run.sh --skip-esrgan input/your_image.jpg"
