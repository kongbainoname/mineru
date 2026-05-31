# ==========================================
# MinerU PDF 解析服务 - 开发环境 Dockerfile
# ==========================================
# 与 prod/test 共用代码，仅通过环境变量区分运行时参数

FROM docker.m.daocloud.io/library/python:3.10-slim

# 安装系统依赖：OpenCV、中文字体、ONNXRuntime 等所需库
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
RUN pip install --timeout 300 --retries 5 -e ".[pipeline]" -i https://pypi.tuna.tsinghua.edu.cn/simple

# 创建运行必要的目录
RUN mkdir -p /app/output /app/logs

EXPOSE 8000
CMD ["mineru-api", "--host", "0.0.0.0", "--port", "8000"]
