# 问题排查指南

## 问题：output/test_enhanced.png 不存在

### 根本原因分析

1. **Real-ESRGAN 在 CPU 模式下非常慢**
   - 处理一张普通图片可能需要 30-60 分钟甚至更长
   - CPU 使用率会达到 100%
   - 这是正常现象，不是bug

2. **输出路径问题（已修复）**
   - 原始脚本使用相对路径，导致 Real-ESRGAN 输出到错误位置
   - 现在已修改为使用绝对路径：`$PROJECT_ROOT/output`

### 解决方案

#### 方案 1：使用快速测试模式（推荐）

仅运行 GFPGAN，跳过慢速的 Real-ESRGAN：

```bash
./quick_test.sh input/test.jpg
```

输出：`output/test_gfpgan_only.jpg`（仅人脸增强，无整图放大）

#### 方案 2：等待完整 Pipeline 完成

如果你需要完整的增强效果（人脸 + 整图超分辨率）：

```bash
./run.sh input/test.jpg
```

**预计时间**：
- GFPGAN: ~5 秒
- Real-ESRGAN: **30-60 分钟**（CPU 模式）

检查进度：
```bash
# 查看进程状态
ps aux | grep realesrgan

# 监控输出目录
watch -n 5 ls -lh output/
```

#### 方案 3：使用 GPU 加速（最快）

如果你有兼容的 GPU（Apple Silicon / NVIDIA / AMD）：

PyTorch 会自动检测并使用 GPU，处理时间可缩短到 **5-10 秒**。

检查 PyTorch 是否使用 GPU：
```bash
python -c "import torch; print('MPS available:', torch.backends.mps.is_available())"
```

对于 Apple Silicon Mac，MPS 应该自动启用。

### 当前文件状态

运行 `./quick_test.sh` 后：
```
output/
└── test_gfpgan_only.jpg  ← GFPGAN 人脸修复结果（已生成）
```

运行完整 `./run.sh` 后（需等待很久）：
```
output/
├── test_gfpgan_only.jpg      ← 快速测试结果
└── test_enhanced.png          ← 完整 pipeline 结果
```

### 如何验证文件已生成

```bash
# 检查输出目录
ls -lh output/

# 查看图片信息
file output/*.jpg output/*.png 2>/dev/null

# 在 macOS 上打开图片
open output/test_gfpgan_only.jpg
```

### 性能对比

| 模式 | GFPGAN | Real-ESRGAN | 总时间 |
|------|--------|-------------|--------|
| CPU (当前) | ~5秒 | **30-60分钟** | 30-60分钟 |
| GPU | ~2秒 | 5-10秒 | 7-12秒 |
| 仅GFPGAN | ~5秒 | 跳过 | 5秒 |

### 修复后的变化

**修改前的问题**：
- ❌ 输出文件不在 `output/` 目录
- ❌ Real-ESRGAN 输出到 `Real-ESRGAN/results/`

**修改后**：
- ✅ 所有输出统一到 `output/` 目录
- ✅ 使用绝对路径避免路径混乱
- ✅ 脚本自动检测 GFPGAN 输出的文件扩展名
- ✅ 提供快速测试模式

### 建议

对于日常使用：
1. **快速预览**：使用 `quick_test.sh` (5秒)
2. **最终质量**：如果满意效果，再运行完整 `run.sh` (需等待)
3. **批量处理**：考虑使用 GPU 或云服务器

对于生产环境：
- 必须使用 GPU
- 或使用云 API 服务（如 Replicate, Hugging Face）
- CPU 模式仅适合测试和理解原理
