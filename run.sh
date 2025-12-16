#!/bin/bash
# Image Enhancement Pipeline
# Combines GFPGAN (face restoration) and Real-ESRGAN (full image super-resolution)

set -e  # Exit on error

# Get project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# Activate virtual environment
source venv/bin/activate

# Get input file
INPUT_FILE=${1:-"input/test.jpg"}

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found"
    echo "Usage: ./run.sh <input_image>"
    exit 1
fi

# Extract filename without path and extension
FILENAME=$(basename "$INPUT_FILE")
BASENAME="${FILENAME%.*}"

echo "===================================="
echo "Image Enhancement Pipeline"
echo "===================================="
echo "Input: $INPUT_FILE"
echo ""

# Step 1: GFPGAN - Face Restoration
echo "Step 1/2: Running GFPGAN for face restoration..."
python GFPGAN/inference_gfpgan.py \
  -i "$INPUT_FILE" \
  -o tmp \
  -v 1.4 \
  -s 1

# Check if face restoration succeeded
if [ -d "tmp/restored_imgs" ]; then
    # GFPGAN outputs with original extension
    if [ -f "tmp/restored_imgs/${BASENAME}.png" ]; then
        GFPGAN_OUTPUT="tmp/restored_imgs/${BASENAME}.png"
    elif [ -f "tmp/restored_imgs/${BASENAME}.jpg" ]; then
        GFPGAN_OUTPUT="tmp/restored_imgs/${BASENAME}.jpg"
    else
        # Fallback to first file in directory
        GFPGAN_OUTPUT=$(ls tmp/restored_imgs/ | head -1)
        GFPGAN_OUTPUT="tmp/restored_imgs/$GFPGAN_OUTPUT"
    fi
    echo "✓ Face restoration completed"
else
    echo "⚠ No faces detected, using original image"
    GFPGAN_OUTPUT="$INPUT_FILE"
fi

# Step 2: Real-ESRGAN - Full Image Super-Resolution
echo ""
echo "Step 2/2: Running Real-ESRGAN for image enhancement (GPU accelerated)..."
python Real-ESRGAN/inference_realesrgan.py \
  -n RealESRGAN_x4plus \
  -i "$GFPGAN_OUTPUT" \
  -o "$PROJECT_ROOT/output" \
  -s 2 \
  -g 0 \
  --suffix "_enhanced"

echo ""
echo "===================================="
echo "✓ Enhancement complete!"
echo "Output: output/${BASENAME}_enhanced.png"
echo "===================================="
echo ""
echo "To view the result:"
echo "  open output/${BASENAME}_enhanced.png"

# Cleanup temporary files
# rm -rf tmp/*
