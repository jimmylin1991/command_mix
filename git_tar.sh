#!/bin/bash

# 脚本文件名（用于排除自身）
SCRIPT_NAME=$(basename "$0")

# 服务列表文件
SERVICE_FILE="services.txt"

# 第一步：清理当前目录（保留脚本和services.txt）
echo "第一步：清理当前目录..."
echo "将删除除 $SCRIPT_NAME 和 $SERVICE_FILE 外的所有文件和文件夹"

# 安全提示
read -p "确认要清理当前目录吗？此操作不可恢复！(y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "操作已取消"
    exit 1
fi

# 执行清理
find . -mindepth 1 -maxdepth 1 ! -name "*sh" ! -name "$SERVICE_FILE" -exec rm -rf {} +
echo "目录清理完成！"
echo "----------------------------------------"

# 检查服务列表文件是否存在
if [ ! -f "$SERVICE_FILE" ]; then
    echo "错误：服务列表文件 $SERVICE_FILE 不存在"
    echo "请创建包含服务名称的文件，每行一个服务名"
    exit 1
fi

# 读取服务列表
services=()
while IFS= read -r service || [[ -n "$service" ]]; do
    # 跳过空行和注释行（以#开头）
    if [[ -z "$service" || "$service" =~ ^[[:space:]]*# ]]; then
        continue
    fi
    services+=("$service")
done < "$SERVICE_FILE"

# 检查是否有服务需要处理
if [ ${#services[@]} -eq 0 ]; then
    echo "错误：服务列表为空"
    exit 1
fi

# 创建输出目录
OUTPUT_DIR="service_packages"
mkdir -p "$OUTPUT_DIR"

# 遍历所有服务
for service in "${services[@]}"; do
    echo "处理服务: $service"
    
    # 根据服务名判断克隆路径
    if [[ $service == *front ]]; then
        repo_url="http://172.16.168.245:28080/MaaS/front/$service.git"
    else
        repo_url="http://172.16.168.245:28080/MaaS/server/$service.git"
    fi
    
    # 克隆仓库
    echo "正在克隆: $repo_url"
    git clone "$repo_url" 2>/dev/null
    
    # 检查克隆是否成功
    if [ ! -d "$service" ]; then
        echo "错误：克隆失败，跳过打包 $service"
        continue
    fi
    
    # 打包目录
    echo "正在打包: $service"
    tar -czf "$OUTPUT_DIR/$service.tar.gz" "$service"
    
    # 清理克隆的目录
    echo "清理临时目录: $service"
    rm -rf "$service"
    
    echo "完成处理: $service.tar.gz"
    echo "----------------------------------------"
done

echo "所有服务处理完成！打包文件保存在 $OUTPUT_DIR 目录中"
