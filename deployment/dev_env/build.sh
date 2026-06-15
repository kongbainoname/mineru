#!/bin/bash
set -e

# ==============================================================================
# MinerU PDF 解析服务 - 开发环境一键脚本
# ==============================================================================
# 核心设计：.env.dev 已配好 → 直接 ./build.sh 即可启动容器
# ==============================================================================

cd "$(dirname "$0")"

# 颜色
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

COMPOSE_FILE="docker-compose.yml"
IMAGE_TAG="mineru:dev"
PORT=8000

# docker compose 命令兼容
if docker compose version &>/dev/null; then
    DOCKER_COMPOSE="docker compose"
elif docker-compose version &>/dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    echo -e "${RED}[ERR] 未找到 docker compose 命令，请先安装 Docker${NC}"
    exit 1
fi

print_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
print_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
print_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_err()   { echo -e "${RED}[ERR]${NC} $1"; }

check_env() {
    if [ ! -f ".env.dev" ]; then
        print_err ".env.dev 不存在"
        return 1
    fi
    return 0
}

image_exists() {
    docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${IMAGE_TAG}$"
}

container_running() {
    docker ps --format "{{.Names}}" | grep -q "^mineru-api-dev$"
}

ensure_dirs() {
    mkdir -p output logs ../models
    chmod -R 777 output logs ../models 2>/dev/null || true
}

do_build() {
    local use_cache="${1:-yes}"
    print_info "构建镜像: ${IMAGE_TAG} ..."
    if [ "$use_cache" = "no" ]; then
        $DOCKER_COMPOSE -f "${COMPOSE_FILE}" build --no-cache
    else
        $DOCKER_COMPOSE -f "${COMPOSE_FILE}" build
    fi
    print_ok "镜像构建完成"
}

do_start() {
    print_info "启动容器..."
    ensure_dirs
    $DOCKER_COMPOSE -f "${COMPOSE_FILE}" up -d
    print_ok "容器已启动"

    print_info "等待服务就绪（最多 60 秒）..."
    for i in {1..30}; do
        if curl -s "http://localhost:${PORT}/health" >/dev/null 2>&1; then
            print_ok "服务已就绪"
            show_access
            return 0
        fi
        echo -n "."
        sleep 2
    done
    echo ""
    print_warn "服务可能尚未就绪，查看日志: ./build.sh logs"
}

do_stop() {
    print_info "停止容器..."
    $DOCKER_COMPOSE -f "${COMPOSE_FILE}" down
    print_ok "容器已停止"
}

do_logs()   { $DOCKER_COMPOSE -f "${COMPOSE_FILE}" logs -f; }
do_status() { $DOCKER_COMPOSE -f "${COMPOSE_FILE}" ps; }

show_access() {
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}   MinerU PDF 解析服务开发环境已启动${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo -e "  本地访问: ${BLUE}http://localhost:${PORT}${NC}"
    echo -e "  API 文档: ${BLUE}http://localhost:${PORT}/docs${NC}"
    echo -e "  健康检查: ${BLUE}http://localhost:${PORT}/health${NC}"
    echo ""
    echo -e "  ${YELLOW}常用命令:${NC}"
    echo -e "    停止      : ${YELLOW}./build.sh stop${NC}"
    echo -e "    重启      : ${YELLOW}./build.sh restart${NC}"
    echo -e "    重建+重启 : ${YELLOW}./build.sh rebuild${NC}"
    echo -e "    查看日志  : ${YELLOW}./build.sh logs${NC}"
    echo ""
    echo -e "  ${YELLOW}开发特性:${NC}"
    echo -e "    - 修改 ../../mineru/ 代码无需重建镜像（已挂载卷）"
    echo -e "    - LOG_LEVEL=DEBUG，详细日志"
    echo -e "    - 并发请求数=3，渲染线程数=1"
    echo ""
    echo -e "${GREEN}============================================${NC}"
}

show_help() {
    echo "MinerU PDF 解析服务 - 开发环境部署脚本"
    echo ""
    echo "用法: ./build.sh [命令] [选项]"
    echo ""
    echo "命令:"
    echo "  (无)          智能启动：镜像存在则直接启动，不存在则构建+启动"
    echo "  deploy        同上（显式写法）"
    echo "  up            同上（快捷写法）"
    echo "  build         仅构建镜像"
    echo "  start         仅启动（不构建，镜像须已存在）"
    echo "  stop          停止容器"
    echo "  restart       重启容器（不重建镜像）"
    echo "  rebuild       强制重新构建镜像并重启"
    echo "  logs          查看实时日志"
    echo "  status        查看容器状态"
    echo ""
}

# ==============================================================================
# 主逻辑
# ==============================================================================

CMD=""
EXTRA_ARG=""
while [[ $# -gt 0 ]]; do
    case $1 in
        deploy|up)          CMD="deploy"; shift ;;
        build|start|stop|restart|rebuild|logs|status) CMD="$1"; shift ;;
        -h|--help|help)     show_help; exit 0 ;;
        *)                  EXTRA_ARG="$1"; shift ;;
    esac
done

case "$CMD" in
    "")  CMD="deploy" ;;
esac

case "$CMD" in
    deploy)
        check_env || exit 1
        ensure_dirs
        if container_running; then
            print_warn "容器已在运行，无需操作"
            echo "如需重启: ./build.sh restart"
            echo "如需重建: ./build.sh rebuild"
            show_access
            exit 0
        fi
        if image_exists; then
            print_info "镜像已存在，直接启动容器..."
            do_start
        else
            print_info "镜像不存在，先构建再启动..."
            do_build
            do_start
        fi
        ;;
    build)
        check_env || exit 1
        ensure_dirs
        do_build
        print_ok "构建完成"
        ;;
    start)
        check_env || exit 1
        ensure_dirs
        do_start
        ;;
    stop)
        do_stop
        ;;
    restart)
        do_stop
        check_env || exit 1
        ensure_dirs
        do_start
        ;;
    rebuild)
        do_stop
        check_env || exit 1
        ensure_dirs
        do_build "no"
        do_start
        ;;
    logs)
        do_logs
        ;;
    status)
        do_status
        ;;
    *)
        show_help
        exit 1
        ;;
esac
