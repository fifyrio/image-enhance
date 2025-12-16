#!/bin/bash
# Image Enhancement Pipeline
# Combines GFPGAN (face restoration) and Real-ESRGAN (full image super-resolution)

set -e  # Exit on error

# Get project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# Activate virtual environment
source venv/bin/activate

# Parse arguments
ENABLE_ESRGAN=true
INPUT_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-esrgan|--no-esrgan)
            ENABLE_ESRGAN=false
            shift
            ;;
        *)
            INPUT_FILE="$1"
            shift
            ;;
    esac
done

# Use default input if not provided
INPUT_FILE=${INPUT_FILE:-"input/test.jpg"}

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found"
    echo "Usage: ./run.sh [--skip-esrgan] <input_image>"
    echo ""
    echo "Options:"
    echo "  --skip-esrgan, --no-esrgan  Skip Real-ESRGAN super-resolution step"
    exit 1
fi

# Extract filename without path and extension
FILENAME=$(basename "$INPUT_FILE")
BASENAME="${FILENAME%.*}"

echo "===================================="
echo "Image Enhancement Pipeline"
echo "===================================="
echo "Input: $INPUT_FILE"
echo "Real-ESRGAN: $([ "$ENABLE_ESRGAN" = true ] && echo "Enabled" || echo "Disabled")"
echo ""

# Step 1: GFPGAN - Face Restoration
TOTAL_STEPS=$([ "$ENABLE_ESRGAN" = true ] && echo "2" || echo "1")
echo "Step 1/${TOTAL_STEPS}: Running GFPGAN for face restoration..."
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

# Step 2: Real-ESRGAN - Full Image Super-Resolution (Optional)
if [ "$ENABLE_ESRGAN" = true ]; then
    echo ""
    echo "Step 2/2: Running Real-ESRGAN for image enhancement (GPU accelerated)..."
    python Real-ESRGAN/inference_realesrgan.py \
      -n RealESRGAN_x4plus \
      -i "$GFPGAN_OUTPUT" \
      -o "$PROJECT_ROOT/output" \
      -s 2 \
      -g 0 \
      --suffix "_enhanced"

    FINAL_OUTPUT="output/${BASENAME}_enhanced.png"
else
    echo ""
    echo "Real-ESRGAN skipped (use without --skip-esrgan to enable)"
    # Copy GFPGAN output to final output directory
    mkdir -p "$PROJECT_ROOT/output"
    cp "$GFPGAN_OUTPUT" "$PROJECT_ROOT/output/${BASENAME}_restored.png"
    FINAL_OUTPUT="output/${BASENAME}_restored.png"
fi

echo ""
echo "===================================="
echo "✓ Enhancement complete!"
echo "Output: $FINAL_OUTPUT"
echo "===================================="
echo ""
echo "To view the result:"
echo "  open $FINAL_OUTPUT"

# Cleanup temporary files
# rm -rf tmp/*
