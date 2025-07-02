# 定义构建参数
ARG N8N_VERSION=latest

# 第一阶段：下载和准备汉化包
FROM alpine:3.22.0 AS chinese-package

# 下载并解压汉化包
RUN wget https://github.com/other-blowsnow/n8n-i18n-chinese/releases/latest/download/editor-ui.tar.gz && \
    mkdir -p /chinese-package && \
    tar -xzf editor-ui.tar.gz -C /chinese-package && \
    rm editor-ui.tar.gz

# 第二阶段：最终镜像
FROM n8nio/n8n:${N8N_VERSION}

# 从第一阶段复制汉化文件
COPY --from=chinese-package /chinese-package/ /usr/local/lib/node_modules/n8n/node_modules/n8n-editor-ui/

# 设置默认语言为中文
ENV N8N_DEFAULT_LOCALE=zh-CN
