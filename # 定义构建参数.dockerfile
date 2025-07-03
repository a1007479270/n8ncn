# 定义构建参数
ARG NODE_VERSION=22                # 设置Node.js版本为22
ARG N8N_VERSION=snapshot          # 设置n8n版本为snapshot（最新开发版）
ARG LAUNCHER_VERSION=1.1.3        # 设置任务运行器启动器版本
ARG TARGETPLATFORM                # 定义目标平台参数

# 第一阶段：系统依赖和基础设置
FROM n8nio/base:${NODE_VERSION} AS system-deps  # 使用n8n基础镜像作为第一阶段

# 第二阶段：应用程序制品处理
FROM alpine:3.22.0 AS app-artifact-processor    # 使用Alpine Linux作为第二阶段基础镜像
COPY ./compiled /app/                           # 复制编译后的文件到/app目录

# 第三阶段：任务运行器启动器
FROM alpine:3.22.0 AS launcher-downloader       # 使用Alpine Linux作为第三阶段基础镜像
ARG TARGETPLATFORM                              # 再次声明目标平台参数
ARG LAUNCHER_VERSION                            # 再次声明启动器版本参数

# 下载并验证任务运行器启动器
RUN set -e; \                                   # 设置错误即退出
    case "$TARGETPLATFORM" in \                # 根据目标平台选择架构
        "linux/amd64") ARCH_NAME="amd64" ;; \
        "linux/arm64") ARCH_NAME="arm64" ;; \
        *) echo "Unsupported platform: $TARGETPLATFORM" && exit 1 ;; \
    esac; \
    mkdir /launcher-temp && cd /launcher-temp; \
    # 下载启动器和校验文件
    wget -q "https://github.com/n8n-io/task-runner-launcher/releases/download/${LAUNCHER_VERSION}/task-runner-launcher-${LAUNCHER_VERSION}-linux-${ARCH_NAME}.tar.gz"; \
    wget -q "https://github.com/n8n-io/task-runner-launcher/releases/download/${LAUNCHER_VERSION}/task-runner-launcher-${LAUNCHER_VERSION}-linux-${ARCH_NAME}.tar.gz.sha256"; \
    # 创建并验证校验和
    echo "$(cat task-runner-launcher-${LAUNCHER_VERSION}-linux-${ARCH_NAME}.tar.gz.sha256) task-runner-launcher-${LAUNCHER_VERSION}-linux-${ARCH_NAME}.tar.gz" > checksum.sha256; \
    sha256sum -c checksum.sha256; \
    # 解压到目标目录
    mkdir -p /launcher-bin; \
    tar xzf task-runner-launcher-${LAUNCHER_VERSION}-linux-${ARCH_NAME}.tar.gz -C /launcher-bin; \
    cd / && rm -rf /launcher-temp                # 清理临时文件

# 第四阶段：最终运行时镜像
FROM system-deps AS runtime                      # 使用第一阶段的系统依赖作为最终阶段基础

# 设置环境变量
ARG N8N_VERSION
ARG N8N_RELEASE_TYPE=dev
ENV NODE_ENV=production                         # 设置Node环境为生产环境
ENV N8N_RELEASE_TYPE=${N8N_RELEASE_TYPE}        # 设置发布类型
ENV NODE_ICU_DATA=/usr/local/lib/node_modules/full-icu  # 设置ICU数据路径
ENV SHELL=/bin/sh                               # 设置默认shell

WORKDIR /home/node                              # 设置工作目录

# 复制文件
COPY --from=app-artifact-processor /app /usr/local/lib/node_modules/n8n  # 复制n8n应用
COPY --from=launcher-downloader /launcher-bin/* /usr/local/bin/          # 复制启动器
COPY docker/images/n8n/docker-entrypoint.sh /                           # 复制入口脚本
COPY docker/images/n8n/n8n-task-runners.json /etc/n8n-task-runners.json  # 复制任务运行器配置

# 设置应用
RUN cd /usr/local/lib/node_modules/n8n && \
    npm rebuild sqlite3 && \                     # 重建sqlite3
    ln -s /usr/local/lib/node_modules/n8n/bin/n8n /usr/local/bin/n8n && \  # 创建命令链接
    mkdir -p /home/node/.n8n && \               # 创建数据目录
    chown -R node:node /home/node               # 设置目录权限

# 安装依赖
RUN npm install -g npm@11.4.2                   # 安装特定版本npm以修复漏洞
RUN cd /usr/local/lib/node_modules/n8n/node_modules/pdfjs-dist && npm install @napi-rs/canvas  # 安装PDF依赖

EXPOSE 5678/tcp                                 # 暴露端口
USER node                                       # 切换到非root用户
ENTRYPOINT ["tini", "--", "/docker-entrypoint.sh"]  # 设置容器入口点

# 设置镜像标签
LABEL org.opencontainers.image.title="n8n" \                # 镜像标题
      org.opencontainers.image.description="Workflow Automation Tool" \  # 描述
      org.opencontainers.image.source="https://github.com/n8n-io/n8n" \  # 源码地址
      org.opencontainers.image.url="https://n8n.io" \                   # 官网
      org.opencontainers.image.version=${N8N_VERSION}                    # 版本号