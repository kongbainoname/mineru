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
        && \
    fc-cache -fv && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 复制本地代码（利用 .dockerignore 排除无关文件）
COPY . .

RUN pip install --timeout 300 --retries 5 -e ".[pipeline]" -i https://pypi.tuna.tsinghua.edu.cn/simple

# 下载模型（可选；如果本地已有模型建议挂载，注释掉此行以减小镜像）
RUN mineru-models-download -s modelscope -m pipeline

ENV MINERU_MODEL_SOURCE=modelscope
ENTRYPOINT ["/bin/bash", "-c", "export MINERU_MODEL_SOURCE=modelscope && exec \"$@\"", "--"]