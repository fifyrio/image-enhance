#!/bin/bash
# Quick Test - Uses smaller scale factor for faster results

set -e

# Get project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

source venv/bin/activate

INPUT_FILE=${1:-"input/test.jpg"}
FILENAME=$(basename "$INPUT_FILE")
BASENAME="${FILENAME%.*}"

echo "Quick Test - Using reduced scale for speed"
echo "Input: $INPUT_FILE"

# Step 1: GFPGAN (no upscaling)
echo "Running GFPGAN..."
python GFPGAN/inference_gfpgan.py -i "$INPUT_FILE" -o tmp -v 1.4 -s 1 2>&1 | grep -E "(Processing|Results)"

# Find the output file
if [ -f "tmp/restored_imgs/${BASENAME}.png" ]; then
    GFPGAN_OUTPUT="tmp/restored_imgs/${BASENAME}.png"
elif [ -f "tmp/restored_imgs/${BASENAME}.jpg" ]; then
    GFPGAN_OUTPUT="tmp/restored_imgs/${BASENAME}.jpg"
else
    GFPGAN_OUTPUT=$(ls tmp/restored_imgs/ | head -1)
    GFPGAN_OUTPUT="tmp/restored_imgs/$GFPGAN_OUTPUT"
fi

echo "GFPGAN output: $GFPGAN_OUTPUT"

# Step 2: Skip Real-ESRGAN for quick test, just copy result
echo "Copying result to output (skipping Real-ESRGAN for speed)..."
cp "$GFPGAN_OUTPUT" "output/${BASENAME}_gfpgan_only.${GFPGAN_OUTPUT##*.}"

echo ""
echo "✓ Quick test complete!"
echo "Output: output/${BASENAME}_gfpgan_only.${GFPGAN_OUTPUT##*.}"
ls -lh "output/${BASENAME}_gfpgan_only.${GFPGAN_OUTPUT##*.}"
