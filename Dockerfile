# 使用官方n8n镜像作为基础镜像
ARG N8N_VERSION=latest
FROM n8nio/n8n:${N8N_VERSION}

# 设置工作目录
WORKDING /tmp

# 下载并解压汉化包
RUN apt-get update && apt-get install -y wget && \
    wget https://github.com/other-blowsnow/n8n-i18n-chinese/releases/latest/download/editor-ui.tar.gz && \
    tar -xzf editor-ui.tar.gz -C /usr/local/lib/node_modules/n8n/node_modules/n8n-editor-ui/dist/ && \
    rm editor-ui.tar.gz && \
    apt-get remove -y wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 设置默认语言为中文
ENV N8N_DEFAULT_LOCALE=zh-CN
