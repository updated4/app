#!/bin/bash

# 应用检测脚本 - 支持详细信息检测

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 脚本信息
SCRIPT_VERSION="1.3.0"
SCRIPT_DATE="2024-01-15"
SCRIPT_DIR=$(pwd)
SCRIPT_NAME=$(basename "$0")

# 默认检测的应用列表
DEFAULT_APPS=(
    "python3" "python" "git" "node" "npm" "docker" 
    "java" "gcc" "g++" "make" "curl" "wget" 
    "vim" "nano" "code" "chrome" "firefox"
)

# 获取应用详细信息的函数
get_app_details() {
    local app=$1
    local app_path=""
    local version=""
    local install_date=""
    local size=""
    
    # 获取应用路径
    app_path=$(command -v "$app" 2>/dev/null)
    
    if [ -n "$app_path" ]; then
        # 获取版本信息 - 针对不同应用使用不同参数
        case "$app" in
            python|python3)
                version=$($app --version 2>&1 | head -n1)
                ;;
            git|node|npm|yarn|pnpm|deno)
                version=$($app --version 2>&1 | head -n1)
                ;;
            java)
                version=$($app -version 2>&1 | head -n1)
                ;;
            gcc|g++|go|rustc)
                version=$($app --version 2>&1 | head -n1)
                ;;
            docker)
                version=$($app --version 2>&1 | head -n1)
                ;;
            curl|wget|make|vim|nano)
                version=$($app --version 2>&1 | head -n1 2>/dev/null || $app -v 2>&1 | head -n1 2>/dev/null || echo "版本信息不可用")
                ;;
            *)
                # 尝试常见的版本参数
                version=$($app --version 2>&1 | head -n1 2>/dev/null || \
                         $app -version 2>&1 | head -n1 2>/dev/null || \
                         $app -v 2>&1 | head -n1 2>/dev/null || \
                         echo "版本信息不可用")
                ;;
        esac
        
        # 获取安装日期（在Linux上）
        if [ -f "$app_path" ]; then
            if command -v stat &> /dev/null; then
                install_date=$(stat -c %y "$app_path" 2>/dev/null | cut -d'.' -f1 2>/dev/null || echo "未知")
            else
                install_date="未知"
            fi
        else
            install_date="未知"
        fi
        
        # 获取文件大小
        if [ -f "$app_path" ] && command -v du &> /dev/null; then
            size=$(du -h "$app_path" 2>/dev/null | cut -f1)
        else
            size="未知"
        fi
        
        # 显示详细信息
        echo -e "${GREEN}✓${NC} $app"
        echo -e "  ${CYAN}状态:${NC} 已安装"
        echo -e "  ${CYAN}路径:${NC} $app_path"
        echo -e "  ${CYAN}版本:${NC} ${version:-未知}"
        echo -e "  ${CYAN}安装时间:${NC} $install_date"
        echo -e "  ${CYAN}文件大小:${NC} $size"
        echo ""
        
        return 0
    else
        echo -e "${RED}✗${NC} $app"
        echo -e "  ${CYAN}状态:${NC} ${RED}未安装${NC}"
        echo -e "  ${CYAN}路径:${NC} 未找到"
        echo -e "  ${CYAN}版本:${NC} 无"
        echo -e "  ${CYAN}安装时间:${NC} 无"
        echo -e "  ${CYAN}文件大小:${NC} 无"
        echo ""
        return 1
    fi
}

# 简单检测函数
check_app_simple() {
    local app=$1
    if command -v "$app" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $app - 已安装"
        return 0
    else
        echo -e "${RED}✗${NC} $app - 未安装"
        return 1
    fi
}

# 批量检测应用详细信息
check_apps_detailed() {
    local apps=("$@")
    local installed_count=0
    local not_installed_count=0
    local not_installed_apps=()
    
    echo "========================================"
    echo "应用详细信息检测结果"
    echo "========================================"
    echo ""
    
    for app in "${apps[@]}"; do
        if get_app_details "$app"; then
            ((installed_count++))
        else
            ((not_installed_count++))
            not_installed_apps+=("$app")
        fi
    done
    
    echo "========================================"
    echo "统计结果:"
    echo -e "${GREEN}已安装: $installed_count 个${NC}"
    echo -e "${RED}未安装: $not_installed_count 个${NC}"
    
    if [ ${#not_installed_apps[@]} -gt 0 ]; then
        echo ""
        echo "未安装的应用:"
        for app in "${not_installed_apps[@]}"; do
            echo "  - $app"
        done
    fi
}

# 批量检测应用（简化版）
check_apps_simple() {
    local apps=("$@")
    local installed_count=0
    local not_installed_count=0
    local not_installed_apps=()
    
    echo "========================================"
    echo "应用安装检测结果"
    echo "========================================"
    
    for app in "${apps[@]}"; do
        if check_app_simple "$app"; then
            ((installed_count++))
        else
            ((not_installed_count++))
            not_installed_apps+=("$app")
        fi
    done
    
    echo ""
    echo "========================================"
    echo "统计结果:"
    echo -e "${GREEN}已安装: $installed_count 个${NC}"
    echo -e "${RED}未安装: $not_installed_count 个${NC}"
    
    if [ ${#not_installed_apps[@]} -gt 0 ]; then
        echo ""
        echo "未安装的应用:"
        for app in "${not_installed_apps[@]}"; do
            echo "  - $app"
        done
    fi
}

# 交互式输入应用名称
input_apps() {
    local input_apps=()
    local app=""
    
    echo -e "${BLUE}请输入要检测的应用名称 (输入 'done' 结束输入):${NC}"
    
    while true; do
        read -p "应用名称: " app
        
        # 检查输入是否为空
        if [ -z "$app" ]; then
            echo -e "${YELLOW}请输入有效的应用名称${NC}"
            continue
        fi
        
        # 检查是否输入完成
        if [ "$app" = "done" ] || [ "$app" = "DONE" ]; then
            break
        fi
        
        # 添加到数组
        input_apps+=("$app")
        echo -e "${GREEN}已添加: $app${NC}"
        echo "当前列表: ${input_apps[*]}"
        echo ""
    done
    
    # 检测输入的应用
    if [ ${#input_apps[@]} -gt 0 ]; then
        echo ""
        echo -e "${BLUE}开始检测您输入的应用...${NC}"
        check_apps_detailed "${input_apps[@]}"
    else
        echo -e "${YELLOW}没有输入任何应用，将检测默认应用列表${NC}"
        check_apps_detailed "${DEFAULT_APPS[@]}"
    fi
}

# 显示脚本信息
show_info() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}应用检测脚本${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "${CYAN}版本: ${YELLOW}${SCRIPT_VERSION}${NC}"
    echo -e "${CYAN}创建日期: ${YELLOW}${SCRIPT_DATE}${NC}"
    echo -e "${CYAN}脚本目录: ${YELLOW}${SCRIPT_DIR}${NC}"
    echo -e "${CYAN}脚本名称: ${YELLOW}${SCRIPT_NAME}${NC}"
    echo -e "${CYAN}当前时间: ${YELLOW}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项] [应用名称...]"
    echo ""
    echo "选项:"
    echo "  -i, --input     交互式输入应用名称"
    echo "  -d, --detailed  显示详细应用信息"
    echo "  -s, --simple    简单检测模式"
    echo "  -v, --version   显示脚本信息"
    echo "  -h, --help      显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                    # 简单检测默认应用"
    echo "  $0 -d                 # 详细检测默认应用"
    echo "  $0 -d python3 git     # 详细检测指定应用"
    echo "  $0 -s python3 git     # 简单检测指定应用"
    echo "  $0 -i                 # 交互式输入并详细检测"
    echo "  $0 -v                 # 显示脚本信息"
    echo "  $0 -h                 # 显示帮助信息"
}

# 主函数
main() {
    case "$1" in
        -h|--help)
            show_help
            ;;
        -v|--version)
            show_info
            ;;
        -i|--input)
            show_info
            input_apps
            ;;
        -d|--detailed)
            show_info
            if [ "$#" -eq 1 ]; then
                # 没有指定应用，检测默认应用
                check_apps_detailed "${DEFAULT_APPS[@]}"
            else
                # 检测指定应用
                shift
                check_apps_detailed "$@"
            fi
            ;;
        -s|--simple)
            show_info
            if [ "$#" -eq 1 ]; then
                # 没有指定应用，检测默认应用
                check_apps_simple "${DEFAULT_APPS[@]}"
            else
                # 检测指定应用
                shift
                check_apps_simple "$@"
            fi
            ;;
        "")
            show_info
            # 默认使用简单检测
            check_apps_simple "${DEFAULT_APPS[@]}"
            ;;
        *)
            show_info
            # 默认使用简单检测
            check_apps_simple "$@"
            ;;
    esac
}

# 运行主函数
main "$@"
