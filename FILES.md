# 项目文件说明

## 核心文件

### 运行脚本
- **run.sh** - 主运行脚本，执行完整的图像增强 pipeline
  - 使用方法: `./run.sh input/your_image.jpg`
  - 自动调用 GFPGAN 和 Real-ESRGAN

### 文档
- **README.md** - 原始学习计划（中文）
- **PROJECT_SUMMARY.md** - 项目总结和技术说明
- **USAGE.md** - 详细使用指南
- **INSTALLATION_LOG.md** - 安装过程记录
- **FILES.md** - 本文件，项目文件清单

## 目录结构

### input/
输入图片目录
- 放置需要处理的原始图片
- 支持 JPG、PNG 等常见格式

### output/
最终输出目录
- 存放经过完整 pipeline 处理的图片
- 文件名格式: `原文件名_enhanced.png`

### tmp/
临时文件目录
- `tmp/restored_imgs/` - GFPGAN 修复后的完整图片
- `tmp/restored_faces/` - 提取的修复后人脸

### GFPGAN/
GFPGAN 源码和资源
- `inference_gfpgan.py` - 推理脚本
- `gfpgan/weights/` - 模型权重文件
- `inputs/` - 示例图片

### Real-ESRGAN/
Real-ESRGAN 源码和资源
- `inference_realesrgan.py` - 推理脚本
- `weights/` - 模型权重文件
- `inputs/` - 示例图片

### venv/
Python 虚拟环境
- 包含所有依赖包
- 使用 `source venv/bin/activate` 激活

## 模型文件位置

### GFPGAN 模型
路径: `GFPGAN/gfpgan/weights/`
- GFPGANv1.4.pth (332MB)
- detection_Resnet50_Final.pth (104MB)
- parsing_parsenet.pth (81.4MB)

### Real-ESRGAN 模型
路径: `Real-ESRGAN/weights/`
- RealESRGAN_x4plus.pth (63.9MB)

## 配置文件

### GFPGAN 配置
- `GFPGAN/options/` - 训练和测试配置

### Real-ESRGAN 配置
- `Real-ESRGAN/options/` - 训练和测试配置

## 使用流程

1. **准备**: 将图片放入 `input/`
2. **运行**: `./run.sh input/your_image.jpg`
3. **查看**: 结果在 `output/` 目录

## 文件大小参考

- 单个模型文件: 60-330MB
- 处理后的图片: 取决于原图和放大倍数
- 临时文件: 约为原图的 2-4 倍

## 清理命令

清理临时文件:
```bash
rm -rf tmp/*
```

清理所有输出:
```bash
rm -rf output/* tmp/*
```

## 备份建议

重要文件（建议版本控制）:
- run.sh
- PROJECT_SUMMARY.md
- USAGE.md
- INSTALLATION_LOG.md

不需要备份（可重新生成）:
- venv/
- tmp/
- output/
- GFPGAN/results/
- Real-ESRGAN/results/

模型文件（大文件，可选备份）:
- GFPGAN/gfpgan/weights/
- Real-ESRGAN/weights/
