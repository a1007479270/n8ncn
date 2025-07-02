# N8N 中文版 Docker 镜像

这个项目自动构建包含中文支持的n8n Docker镜像。基于[n8n-i18n-chinese](https://github.com/other-blowsnow/n8n-i18n-chinese)项目的汉化包。

## 使用方法

```bash
docker run -it --rm \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  你的Docker用户名/n8n-chinese:latest