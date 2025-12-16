# 使用指南

## 快速开始

### 1. 准备输入图片

将要处理的图片放入 `input/` 目录：

```bash
cp your_photo.jpg input/
```

### 2. 运行增强 Pipeline

```bash
./run.sh input/your_photo.jpg
```

### 3. 查看结果

处理完成后，增强后的图片会保存在 `output/` 目录。

## 详细说明

### Pipeline 处理流程

```
原始图片
    ↓
[GFPGAN] 人脸修复
    ↓
中间结果 (tmp/)
    ↓
[Real-ESRGAN] 整图超分辨率 (2x)
    ↓
最终结果 (output/)
```

### 输出说明

- **tmp/restored_imgs/**: GFPGAN 的人脸修复结果
- **tmp/restored_faces/**: 提取的修复后人脸
- **output/**: 最终的增强图片（含后缀 `_enhanced.png`）

### 参数调整

如需自定义参数，可以修改 `run.sh` 脚本：

#### GFPGAN 参数
```bash
python GFPGAN/inference_gfpgan.py \
  -i "$INPUT_FILE" \
  -o tmp \
  -v 1.4 \          # 模型版本 (1.4 / 1.3 / 1.2)
  -s 1              # 放大倍数 (1 = 不放大，仅增强)
```

#### Real-ESRGAN 参数
```bash
python Real-ESRGAN/inference_realesrgan.py \
  -n RealESRGAN_x4plus \  # 模型名称
  -i "$GFPGAN_OUTPUT" \
  -o output \
  -s 2 \                   # 放大倍数 (2x / 4x)
  --suffix "_enhanced"     # 输出文件后缀
```

### 可用的 Real-ESRGAN 模型

- `RealESRGAN_x4plus`: 通用增强模型（推荐）
- `RealESRGAN_x4plus_anime_6B`: 动漫/插画专用
- `RealESRNet_x4plus`: 无 GAN 的版本（更保守）

## 批量处理

创建批量处理脚本 `batch_enhance.sh`:

```bash
#!/bin/bash
for img in input/*.jpg input/*.png; do
    if [ -f "$img" ]; then
        echo "Processing: $img"
        ./run.sh "$img"
    fi
done
```

## 性能建议

### CPU vs GPU

- **CPU 模式**：约 30-60 秒/张（取决于图片大小）
- **GPU 模式**：约 5-10 秒/张

### Apple Silicon (M1/M2/M3)

PyTorch 已自动启用 MPS 后端，性能接近 GPU。

### 内存优化

对于大图片（>4K），可以考虑：
1. 先缩小图片尺寸
2. 分块处理
3. 使用较小的放大倍数

## 常见问题

### Q: 为什么处理速度很慢？
A: 默认使用 CPU 模式。如有 GPU，PyTorch 会自动使用。确保安装了正确的 PyTorch 版本。

### Q: 没有检测到人脸怎么办？
A: Pipeline 会自动跳过 GFPGAN，直接使用 Real-ESRGAN 处理。

### Q: 输出图片太大了
A: 修改 Real-ESRGAN 的 `-s` 参数，降低放大倍数。

### Q: 结果不满意
A: 尝试：
- 调整 GFPGAN 的版本参数（-v 1.4 / 1.3 / 1.2）
- 尝试不同的 Real-ESRGAN 模型
- 调整放大倍数

## 对比测试

建议创建三个版本进行对比：

1. **原图** - 输入图片
2. **仅 Real-ESRGAN** - 跳过 GFPGAN
3. **完整 Pipeline** - GFPGAN + Real-ESRGAN

可以清楚看到 GFPGAN 对人脸的改善效果。

## 下一步探索

1. 尝试 CodeFormer（另一个人脸修复模型）
2. 调整不同的模型组合
3. 实现自动化批量处理
4. 开发 Web UI 界面
