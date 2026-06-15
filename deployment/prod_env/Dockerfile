# syntax=docker/dockerfile:1
# ==========================================
# MinerU PDF 解析服务 - 生产环境 Dockerfile
# ==========================================
# 与 dev/test 共用代码，仅通过环境变量区分运行时参数

FROM docker.m.daocloud.io/library/python:3.10-slim

# 禁用 Python 字节码和缓冲，便于排查；pip 缓存通过 BuildKit cache mount 单独管理
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN if [ -f /etc/apt/sources.list.d/debian.sources ]; then \
        sed -i 's|http://deb.debian.org|http://mirrors.aliyun.com|g' /etc/apt/sources.list.d/debian.sources && \
        sed -i 's|http://security.debian.org|http://mirrors.aliyun.com|g' /etc/apt/sources.list.d/debian.sources; \
    elif [ -f /etc/apt/sources.list ]; then \
        sed -i 's|http://deb.debian.org|http://mirrors.aliyun.com|g' /etc/apt/sources.list && \
        sed -i 's|http://security.debian.org|http://mirrors.aliyun.com|g' /etc/apt/sources.list; \
    fi && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        fonts-noto-core \
        fonts-noto-cjk \
        fontconfig \
        libgl1 \
        libglib2.0-0 \
        libsm6 \
        libxext6 \
        libxrender-dev \
        libgomp1 \
        libcurl4-openssl-dev \
        && \
    fc-cache -fv && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

# 安装 Python 依赖，使用 BuildKit cache mount 缓存 pip 下载的 wheel
# 既避免 wheel 缓存进入镜像层，又能在多次构建间复用下载缓存
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --timeout 300 --retries 5 -e ".[pipeline]" -i https://pypi.tuna.tsinghua.edu.cn/simple && \
    mkdir -p /app/output /app/logs

EXPOSE 8000
CMD ["mineru-api", "--host", "0.0.0.0", "--port", "8000"]
