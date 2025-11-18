#!/bin/bash

# 设置分支参数
BRANCH_NAME="${1:-release/1030}"

# 服务列表文件
SERVICE_FILE="services.txt"

# 保存当前工作目录
INITIAL_DIR="$(pwd)"

# 检查服务列表文件是否存在
if [ ! -f "$SERVICE_FILE" ]; then
    echo "错误：服务列表文件 $SERVICE_FILE 不存在"
    exit 1
fi

# 读取服务列表
services=()
while IFS= read -r service || [[ -n "$service" ]]; do
    # 跳过空行和注释行
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

echo "将使用分支: $BRANCH_NAME"
echo "开始处理服务列表..."
echo "初始工作目录: $INITIAL_DIR"

# 遍历所有服务
for service in "${services[@]}"; do
    echo "========================================"
    echo "处理服务: $service"

    # 确保每次循环都在初始目录开始
    cd "$INITIAL_DIR" || { echo "错误: 无法返回初始目录"; exit 1; }

    # 1. 检查tar包是否存在
    TAR_FILE="${service}.tar.gz"
    if [ ! -f "$TAR_FILE" ]; then
        echo "警告: 未找到文件 $TAR_FILE，跳过此服务"
        continue
    fi

    # 2. 解压tar包（覆盖现有文件）
    echo "解压文件: $TAR_FILE"
    if ! tar -xf "$TAR_FILE"; then
        echo "错误: 解压失败，跳过此服务"
        continue
    fi

    # 3. 进入服务目录
    if [ ! -d "$service" ]; then
        echo "错误: 解压后服务目录不存在，跳过此服务"
        continue
    fi

    echo "进入目录: $service"
    cd "$service" || { echo "错误: 无法进入目录 $service"; continue; }

    # 记录当前目录，用于错误处理
    SERVICE_DIR="$(pwd)"

    # 4. 检查是否是Git仓库
    if [ ! -d ".git" ]; then
        echo "错误: 不是Git仓库，跳过此服务"
        cd "$INITIAL_DIR" || exit 1
        continue
    else
      tee .gitattributes << EOF
*.yaml text eol=lf
*.yml text eol=lf
*.sh text eol=lf
*.py text eol=lf
*.md text eol=lf
* text=auto
EOF
      git config --global --add safe.directory ${INITIAL_DIR}/${service}
      git config --global core.autocrlf input
    fi

    # 5. 查看远程分支，检查目标分支是否存在
    echo "查看远程分支..."
    if ! git branch -r -v >/dev/null; then
        echo "错误: 获取远程分支失败，跳过此服务"
        cd "$INITIAL_DIR" || exit 1
        continue
    fi

    # 检查远程分支是否存在目标分支
    if ! git branch -r | grep -q "origin/$BRANCH_NAME"; then
        echo "警告: 远程分支 origin/$BRANCH_NAME 不存在，跳过此服务"
        cd "$INITIAL_DIR" || exit 1
        continue
    fi

    # 6. 切换到指定分支
    echo "切换到分支: $BRANCH_NAME"
    if ! git checkout "$BRANCH_NAME"; then
        echo "错误: 切换分支失败，跳过此服务"
        cd "$INITIAL_DIR" || exit 1
        continue
    fi

    # 7. 移除原有远程仓库
    echo "移除原有远程仓库"
    if ! git remote remove origin; then
        echo "错误: 移除远程仓库失败，跳过此服务"
        cd "$INITIAL_DIR" || exit 1
        continue
    fi

    # 8. 添加新的远程仓库
    NEW_ORIGIN="http://aigitlab.zj.chinamobile.com/agent_platform/${service}.git"
    echo "添加新的远程仓库: $NEW_ORIGIN"
    if ! git remote add origin "$NEW_ORIGIN"; then
        echo "错误: 添加远程仓库失败，跳过此服务"
        cd "$INITIAL_DIR" || exit 1
        continue
    fi

    # 9. 推送到远程仓库
    echo "推送到远程仓库分支: $BRANCH_NAME"
    if ! git push --set-upstream origin "$BRANCH_NAME"; then
        echo "错误: 推送失败，跳过此服务"
        cd "$INITIAL_DIR" || exit 1
        continue
    fi

    # 10. 返回初始目录
    echo "返回初始目录"
    cd "$INITIAL_DIR" || { echo "错误: 无法返回初始目录"; exit 1; }

    echo "完成处理服务: $service"
    echo "========================================"
    echo
done

echo "所有服务处理完成！"
echo "最终工作目录: $(pwd)"
