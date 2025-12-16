# Image Enhancement API Guide

API 服务器运行在 `http://localhost:8000`

## 快速开始

### 1. 启动服务器

```bash
./start-server.sh
```

或者手动启动：

```bash
source venv/bin/activate
python server.py
```

## API 端点

### 1. 健康检查

**GET** `/health`

检查服务器是否正常运行。

```bash
curl http://localhost:8000/health
```

响应：
```json
{
  "status": "ok",
  "message": "Image Enhancement API is running"
}
```

---

### 2. 图像增强

**POST** `/api/enhance`

上传图片并进行增强处理。

**请求参数：**
- `file` (必需): 图片文件
- `skipEsrgan` (可选): 设置为 `"true"` 跳过 Real-ESRGAN 步骤

**支持的文件格式：** png, jpg, jpeg, webp

**使用 curl：**

```bash
# 完整处理（GFPGAN + Real-ESRGAN）
curl -X POST http://localhost:8000/api/enhance \
  -F "file=@input/test.jpg"

# 仅人脸修复（跳过 Real-ESRGAN）
curl -X POST http://localhost:8000/api/enhance \
  -F "file=@input/test.jpg" \
  -F "skipEsrgan=true"
```

**成功响应：**
```json
{
  "success": true,
  "message": "Image enhanced successfully",
  "downloadUrl": "/api/download/abc123_test_enhanced.png",
  "filename": "abc123_test_enhanced.png",
  "skipEsrgan": false
}
```

**错误响应：**
```json
{
  "error": "No file provided"
}
```

---

### 3. 下载增强后的图片

**GET** `/api/download/<filename>`

下载处理后的图片。

```bash
curl -O http://localhost:8000/api/download/abc123_test_enhanced.png
```

---

### 4. 列出所有输出文件

**GET** `/api/list`

获取所有已处理的图片列表。

```bash
curl http://localhost:8000/api/list
```

**响应：**
```json
{
  "success": true,
  "files": [
    {
      "filename": "abc123_test_enhanced.png",
      "size": 358400,
      "modified": 1702742400.0,
      "downloadUrl": "/api/download/abc123_test_enhanced.png"
    }
  ],
  "count": 1
}
```

---

## Next.js 集成示例

### 方式 1: 使用 FormData（推荐）

```typescript
// app/api/enhance/route.ts 或页面组件中
async function enhanceImage(file: File, skipEsrgan: boolean = false) {
  const formData = new FormData();
  formData.append('file', file);
  if (skipEsrgan) {
    formData.append('skipEsrgan', 'true');
  }

  try {
    const response = await fetch('http://localhost:8000/api/enhance', {
      method: 'POST',
      body: formData,
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Enhancement failed');
    }

    const result = await response.json();
    console.log('Success:', result);

    // 下载增强后的图片
    const downloadUrl = `http://localhost:8000${result.downloadUrl}`;
    return downloadUrl;
  } catch (error) {
    console.error('Error:', error);
    throw error;
  }
}
```

### 方式 2: React 组件示例

```tsx
'use client';

import { useState } from 'react';

export default function ImageEnhancer() {
  const [file, setFile] = useState<File | null>(null);
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<string | null>(null);
  const [skipEsrgan, setSkipEsrgan] = useState(false);

  const handleUpload = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!file) return;

    setLoading(true);
    const formData = new FormData();
    formData.append('file', file);
    if (skipEsrgan) {
      formData.append('skipEsrgan', 'true');
    }

    try {
      const response = await fetch('http://localhost:8000/api/enhance', {
        method: 'POST',
        body: formData,
      });

      const data = await response.json();

      if (data.success) {
        setResult(`http://localhost:8000${data.downloadUrl}`);
      } else {
        alert(`Error: ${data.error}`);
      }
    } catch (error) {
      console.error('Upload failed:', error);
      alert('Upload failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-4">Image Enhancement</h1>

      <form onSubmit={handleUpload} className="space-y-4">
        <div>
          <input
            type="file"
            accept="image/*"
            onChange={(e) => setFile(e.target.files?.[0] || null)}
            className="block w-full text-sm"
          />
        </div>

        <div className="flex items-center gap-2">
          <input
            type="checkbox"
            id="skipEsrgan"
            checked={skipEsrgan}
            onChange={(e) => setSkipEsrgan(e.target.checked)}
          />
          <label htmlFor="skipEsrgan">
            Skip Real-ESRGAN (face restoration only)
          </label>
        </div>

        <button
          type="submit"
          disabled={!file || loading}
          className="px-4 py-2 bg-blue-500 text-white rounded disabled:bg-gray-300"
        >
          {loading ? 'Processing...' : 'Enhance Image'}
        </button>
      </form>

      {result && (
        <div className="mt-8">
          <h2 className="text-xl font-semibold mb-2">Result:</h2>
          <img src={result} alt="Enhanced" className="max-w-full" />
          <a
            href={result}
            download
            className="inline-block mt-4 px-4 py-2 bg-green-500 text-white rounded"
          >
            Download Enhanced Image
          </a>
        </div>
      )}
    </div>
  );
}
```

### 方式 3: Next.js API Route 代理

如果你想通过 Next.js API route 来代理请求（避免 CORS 问题）：

```typescript
// app/api/enhance/route.ts
import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const formData = await request.formData();

    // 转发到 Python API
    const response = await fetch('http://localhost:8000/api/enhance', {
      method: 'POST',
      body: formData,
    });

    const data = await response.json();
    return NextResponse.json(data, { status: response.status });
  } catch (error) {
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
```

然后在客户端调用：

```typescript
const response = await fetch('/api/enhance', {
  method: 'POST',
  body: formData,
});
```

---

## 测试 API

使用提供的测试脚本：

```bash
# 测试完整 pipeline
curl -X POST http://localhost:8000/api/enhance \
  -F "file=@input/test.jpg" \
  | jq

# 测试仅人脸修复
curl -X POST http://localhost:8000/api/enhance \
  -F "file=@input/test.jpg" \
  -F "skipEsrgan=true" \
  | jq
```

---

## 错误处理

API 返回的错误格式：

```json
{
  "error": "错误描述",
  "details": "详细信息（可选）"
}
```

常见错误码：
- `400` - 请求错误（缺少文件、文件类型不支持等）
- `404` - 文件未找到
- `500` - 服务器内部错误
- `504` - 处理超时（超过 5 分钟）

---

## 注意事项

1. **文件大小限制**：默认无限制，但建议不超过 10MB
2. **超时时间**：单次请求最长 5 分钟
3. **并发处理**：建议不要同时处理过多图片，可能导致内存不足
4. **临时文件**：上传的原始图片会在处理完成后自动删除
5. **CORS**：API 已启用 CORS，支持跨域请求
