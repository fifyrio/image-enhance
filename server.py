#!/usr/bin/env python3
"""
Image Enhancement API Server
Provides REST API endpoints for GFPGAN and Real-ESRGAN image enhancement
"""

import os
import subprocess
import uuid
from pathlib import Path
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from werkzeug.utils import secure_filename

app = Flask(__name__)
CORS(app)  # Enable CORS for Next.js frontend

# Configuration
BASE_DIR = Path(__file__).parent
INPUT_DIR = BASE_DIR / "input"
OUTPUT_DIR = BASE_DIR / "output"
TMP_DIR = BASE_DIR / "tmp"
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'webp'}

# Ensure directories exist
INPUT_DIR.mkdir(exist_ok=True)
OUTPUT_DIR.mkdir(exist_ok=True)
TMP_DIR.mkdir(exist_ok=True)


def allowed_file(filename):
    """Check if file extension is allowed"""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'ok',
        'message': 'Image Enhancement API is running'
    })


@app.route('/api/enhance', methods=['POST'])
def enhance_image():
    """
    Enhance image using GFPGAN + Real-ESRGAN pipeline

    Form data:
        - file: Image file to enhance
        - skipEsrgan: (optional) 'true' to skip Real-ESRGAN step

    Returns:
        JSON with download URL or error message
    """
    # Check if file is present
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400

    file = request.files['file']

    if file.filename == '':
        return jsonify({'error': 'No file selected'}), 400

    if not allowed_file(file.filename):
        return jsonify({
            'error': f'Invalid file type. Allowed types: {", ".join(ALLOWED_EXTENSIONS)}'
        }), 400

    try:
        # Generate unique filename to avoid conflicts
        original_filename = secure_filename(file.filename)
        file_ext = original_filename.rsplit('.', 1)[1].lower()
        unique_id = str(uuid.uuid4())[:8]
        input_filename = f"{unique_id}_{original_filename}"
        input_path = INPUT_DIR / input_filename

        # Save uploaded file
        file.save(str(input_path))

        # Check if skipEsrgan flag is set
        skip_esrgan = request.form.get('skipEsrgan', 'false').lower() == 'true'

        # Build command
        cmd = ['bash', str(BASE_DIR / 'run.sh')]
        if skip_esrgan:
            cmd.append('--skip-esrgan')
        cmd.append(str(input_path))

        # Run enhancement pipeline
        result = subprocess.run(
            cmd,
            cwd=str(BASE_DIR),
            capture_output=True,
            text=True,
            timeout=300  # 5 minute timeout
        )

        if result.returncode != 0:
            return jsonify({
                'error': 'Enhancement failed',
                'details': result.stderr
            }), 500

        # Determine output filename based on whether ESRGAN was used
        basename = input_filename.rsplit('.', 1)[0]
        if skip_esrgan:
            output_filename = f"{basename}_restored.png"
        else:
            output_filename = f"{basename}_enhanced.png"

        output_path = OUTPUT_DIR / output_filename

        if not output_path.exists():
            return jsonify({
                'error': 'Output file not found',
                'details': 'Enhancement completed but output file is missing'
            }), 500

        # Return success with download URL
        return jsonify({
            'success': True,
            'message': 'Image enhanced successfully',
            'downloadUrl': f'/api/download/{output_filename}',
            'filename': output_filename,
            'skipEsrgan': skip_esrgan
        })

    except subprocess.TimeoutExpired:
        return jsonify({
            'error': 'Enhancement timeout',
            'details': 'Processing took too long (max 5 minutes)'
        }), 504

    except Exception as e:
        return jsonify({
            'error': 'Internal server error',
            'details': str(e)
        }), 500

    finally:
        # Clean up input file
        if input_path.exists():
            input_path.unlink()


@app.route('/api/download/<filename>', methods=['GET'])
def download_file(filename):
    """
    Download enhanced image

    Args:
        filename: Name of the file to download

    Returns:
        Enhanced image file
    """
    try:
        # Secure the filename to prevent directory traversal
        safe_filename = secure_filename(filename)
        file_path = OUTPUT_DIR / safe_filename

        if not file_path.exists():
            return jsonify({'error': 'File not found'}), 404

        return send_file(
            str(file_path),
            mimetype='image/png',
            as_attachment=True,
            download_name=safe_filename
        )

    except Exception as e:
        return jsonify({
            'error': 'Download failed',
            'details': str(e)
        }), 500


@app.route('/api/list', methods=['GET'])
def list_outputs():
    """
    List all enhanced images in output directory

    Returns:
        JSON array of output files with metadata
    """
    try:
        files = []
        for file_path in OUTPUT_DIR.glob('*'):
            if file_path.is_file() and allowed_file(file_path.name):
                files.append({
                    'filename': file_path.name,
                    'size': file_path.stat().st_size,
                    'modified': file_path.stat().st_mtime,
                    'downloadUrl': f'/api/download/{file_path.name}'
                })

        # Sort by modification time (newest first)
        files.sort(key=lambda x: x['modified'], reverse=True)

        return jsonify({
            'success': True,
            'files': files,
            'count': len(files)
        })

    except Exception as e:
        return jsonify({
            'error': 'Failed to list files',
            'details': str(e)
        }), 500


if __name__ == '__main__':
    print("=" * 50)
    print("Image Enhancement API Server")
    print("=" * 50)
    print(f"Server running at: http://localhost:8000")
    print(f"API endpoints:")
    print(f"  - POST /api/enhance    - Enhance image")
    print(f"  - GET  /api/download/<filename> - Download enhanced image")
    print(f"  - GET  /api/list       - List all output files")
    print(f"  - GET  /health         - Health check")
    print("=" * 50)

    app.run(host='0.0.0.0', port=8000, debug=True)
