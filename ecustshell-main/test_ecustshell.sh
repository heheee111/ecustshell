#!/bin/bash
# ============================================================
# ecustshell 分工1 + 分工2 功能验证脚本
# 在 Ubuntu VM 中运行此脚本
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

pass() { echo -e "${GREEN}[PASS]${NC} $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}[FAIL]${NC} $1"; FAIL=$((FAIL+1)); }

echo "============================================"
echo "  ecustshell 功能验证测试"
echo "============================================"
echo ""

# ---- 编译 ----
echo -e "${YELLOW}[1] 编译项目...${NC}"
cd ~/ecustshell 2>/dev/null || { echo "请先将代码复制到 ~/ecustshell"; exit 1; }
make clean 2>/dev/null
make 2>&1
if [ -f "./ecustshell" ]; then
    pass "编译成功"
else
    fail "编译失败"
    exit 1
fi

# ---- 准备测试环境 ----
echo ""
echo -e "${YELLOW}[2] 准备测试环境...${NC}"
rm -rf /tmp/test_ecust 2>/dev/null
mkdir -p /tmp/test_ecust
cd /tmp/test_ecust
echo "hello world" > test1.txt
echo "line2" >> test1.txt
echo "HELLO AGAIN" > test2.txt
mkdir subdir
echo "sub file" > subdir/sub.txt
pass "测试环境已就绪"

# ============================================================
# 分工1 测试
# ============================================================
echo ""
echo "============================================"
echo "  分工1 功能验证"
echo "============================================"

# --- 1.1 help ---
echo ""
echo "--- 1.1 help 命令 ---"
result=$(echo "help" | ~/ecustshell/ecustshell 2>/dev/null)
if echo "$result" | grep -q "ecustshell"; then
    pass "help 显示 ecustshell 信息"
else
    fail "help 未正确显示"
fi

# --- 1.2 pwd ---
echo ""
echo "--- 1.2 pwd 命令 ---"
result=$(echo "pwd" | ~/ecustshell/ecustshell 2>/dev/null)
if echo "$result" | grep -q "/tmp/test_ecust"; then
    pass "pwd 正确显示当前目录"
else
    fail "pwd 未正确显示"
fi

# --- 1.3 cd ---
echo ""
echo "--- 1.3 cd 命令 ---"
result=$(printf "cd /tmp\ntree . 1\nexit\n" | ~/ecustshell/ecustshell 2>/dev/null)
if echo "$result" | grep -q "/tmp"; then
    pass "cd 切换目录成功"
else
    fail "cd 切换目录失败"
fi

# --- 1.4 echo (含 $VAR 展开) ---
echo ""
echo "--- 1.4 echo 命令 ---"
result=$(echo 'echo $HOME' | ~/ecustshell/ecustshell 2>/dev/null)
if echo "$result" | grep -q "/home/"; then
    pass "echo \$HOME 展开成功"
else
    fail "echo \$HOME 展开失败"
fi

# --- 1.5 type ---
echo ""
echo "--- 1.5 type 命令 ---"
result=$(echo "type ls" | ~/ecustshell/ecustshell 2>/dev/null)
if echo "$result" | grep -q "builtin"; then
    pass "type 正确识别内置命令"
else
    fail "type 未正确识别"
fi

result=$(echo "type bash" | ~/ecustshell/ecustshell 2>/dev/null)
if echo "$result" | grep -q "/"; then
    pass "type 正确识别外部命令"
else
    fail "type 外部命令识别失败"
fi

# --- 1.6 alias / unalias ---
echo ""
echo "--- 1.6 alias / unalias ---"
result=$(printf "alias ll='ls -l'\nalias\nexit\n" | ~/ecustshell/ecustshell 2>/dev/null)
if echo "$result" | grep -q "ll"; then
    pass "alias 创建和列表成功"
else
    fail "alias 失败"
fi

# --- 1.7 ls (-a, -l) ---
echo ""
echo "--- 1.7 ls 命令 ---"
result=$(echo "ls" | ~/ecustshell/ecustshell 2>/dev/null)
if echo "$result" | grep -q "test1.txt"; then
    pass "ls 列出文件成功"
else
    fail "ls 列出文件失败"
fi

result=$(echo "ls -a" | ~/ecustshell/ecustshell 2>/dev/null)
if echo "$result" | grep -q "\.\."; then
    pass "ls -a 显示隐藏文件"
else
    fail "ls -a 失败"
fi

# --- 1.8 cp ---
echo ""
echo "--- 1.8 cp 命令 ---"
result=$(printf "cp test1.txt test1_copy.txt\nls\nexit\n" | ~/ecustshell/ecustshell 2>/dev/null)
if echo "$result" | grep -q "test1_copy.txt"; then
    pass "cp 复制文件成功"
else
    fail "cp 复制文件失败"
fi
rm -f test1_copy.txt

# --- 1.9 mv ---
echo ""
echo "--- 1.9 mv 命令 ---"
echo "move test" > mv_src.txt
result=$(printf "mv mv_src.txt mv_dst.txt\nls\nexit\n" | ~/ecustshell/ecustshell 2>/dev/null)
if echo "$result" | grep -q "mv_dst.txt" && ! echo "$result" | grep -q "mv_src.txt"; then
    pass "mv 重命名成功"
else
    fail "mv 重命名失败"
fi
rm -f mv_dst.txt

# --- 1.10 rm ---
echo ""
echo "--- 1.10 rm 命令 ---"
echo "to be removed" > rm_test.txt
result=$(printf "rm rm_test.txt\nls\nexit\n" | ~/ecustshell/ecustshell 2>/dev/null)
if ! echo "$result" | grep -q "rm_test.txt"; then
    pass "rm 删除文件成功"
else
    fail "rm 删除文件失败"
fi

# --- 1.11 wc ---
echo ""
echo "--- 1.11 wc 命令 ---"
result=$(echo "wc test1.txt" | ~/ecustshell/ecustshell 2>/dev/null)
if echo "$result" | grep -q "total lines"; then
    pass "wc 统计行数成功"
else
    fail "wc 统计行数失败"
fi

# --- 1.12 tree ---
echo ""
echo "--- 1.12 tree 命令 ---"
result=$(printf "tree . 2\nexit\n" | ~/ecustshell/ecustshell 2>/dev/null)
if echo "$result" | grep -q "subdir"; then
    pass "tree 显示目录树成功"
else
    fail "tree 显示目录树失败"
fi

# --- 1.13 ps ---
echo ""
echo "--- 1.13 ps 命令 ---"
result=$(echo "ps" | ~/ecustshell/ecustshell 2>/dev/null)
if echo "$result" | grep -q "PID"; then
    pass "ps 显示进程成功"
else
    fail "ps 显示进程失败"
fi

# --- 1.14 time ---
echo ""
echo "--- 1.14 time 命令 ---"
result=$(echo "time ls" | ~/ecustshell/ecustshell 2>/dev/null)
if echo "$result" | grep -q "running time"; then
    pass "time 测量时间成功"
else
    fail "time 测量时间失败"
fi

# --- 1.15 history ---
echo ""
echo "--- 1.15 history 命令 ---"
result=$(printf "ls\npwd\nhistory\nexit\n" | ~/ecustshell/ecustshell 2>/dev/null)
if echo "$result" | grep -q "Input History"; then
    pass "history 显示历史成功"
else
    fail "history 显示历史失败"
fi

# --- 1.16 shells / shell / use ---
echo ""
echo "--- 1.16 shells / shell / use ---"
result=$(echo "shells" | ~/ecustshell/ecustshell 2>/dev/null)
if echo "$result" | grep -q "Registered shells"; then
    pass "shells 列出 shell 成功"
else
    fail "shells 失败"
fi

result=$(echo "shell current" | ~/ecustshell/ecustshell 2>/dev/null)
if echo "$result" | grep -q "ecustshell"; then
    pass "shell current 成功"
else
    fail "shell current 失败"
fi

# --- 1.17 管道 ---
echo ""
echo "--- 1.17 管道 (|) ---"
result=$(echo 'echo hello world | wc' | ~/ecustshell/ecustshell 2>/dev/null)
if echo "$result" | grep -q "total lines"; then
    pass "管道功能正常"
else
    fail "管道功能异常"
fi

# --- 1.18 输出重定向 > ---
echo ""
echo "--- 1.18 输出重定向 (>) ---"
rm -f /tmp/redirect_test.txt
result=$(printf "echo redirect_test > /tmp/redirect_test.txt\nexit\n" | ~/ecustshell/ecustshell 2>/dev/null)
if [ -f /tmp/redirect_test.txt ]; then
    pass "输出重定向成功"
else
    fail "输出重定向失败（可能用了系统 echo，检查 /tmp/redirect_test.txt）"
fi

# --- 1.19 追加重定向 >> ---
echo ""
echo "--- 1.19 追加重定向 (>>) ---"
rm -f /tmp/append_test.txt
printf "echo line1 > /tmp/append_test.txt\necho line2 >> /tmp/append_test.txt\nexit\n" | ~/ecustshell/ecustshell 2>/dev/null
line_count=$(wc -l < /tmp/append_test.txt 2>/dev/null)
if [ "$line_count" = "2" ]; then
    pass "追加重定向成功"
else
    fail "追加重定向失败 (预期2行，实际${line_count}行)"
fi

# --- 1.20 输入重定向 < ---
echo ""
echo "--- 1.20 输入重定向 (<) ---"
# 输入重定向需要调用外部命令 cat
result=$(printf "cat < test1.txt\nexit\n" | ~/ecustshell/ecustshell 2>/dev/null)
if echo "$result" | grep -q "hello world"; then
    pass "输入重定向成功"
else
    fail "输入重定向失败"
fi

# ============================================================
# 分工2 测试
# ============================================================
echo ""
echo "============================================"
echo "  分工2 功能验证"
echo "============================================"

# --- 2.1 后台运行 & ---
echo ""
echo "--- 2.1 后台运行 (&) ---"
# 使用 sleep 1 快速测试
result=$(printf "sleep 1 &\nexit\n" | ~/ecustshell/ecustshell 2>/dev/null)
if echo "$result" | grep -q '\[.*\]'; then
    pass "后台运行打印 PID 成功"
else
    fail "后台运行未打印 PID"
fi

# --- 2.2 !! ---
echo ""
echo "--- 2.2 !! (重复上条命令) ---"
result=$(printf "echo first_cmd\n!!\nexit\n" | ~/ecustshell/ecustshell 2>/dev/null)
count=$(echo "$result" | grep -c "first_cmd")
if [ "$count" -ge 2 ]; then
    pass "!! 重复命令成功 (出现 ${count} 次)"
else
    fail "!! 重复命令失败 (仅出现 ${count} 次)"
fi

# --- 2.3 !n ---
echo ""
echo "--- 2.3 !n (执行第n条历史) ---"
result=$(printf "echo cmd_one\npwd\n!1\nexit\n" | ~/ecustshell/ecustshell 2>/dev/null)
if echo "$result" | grep -q "cmd_one"; then
    pass "!n 执行历史命令成功"
else
    fail "!n 执行历史命令失败"
fi

# --- 2.4 !?string? ---
echo ""
echo "--- 2.4 !?string? (模糊匹配) ---"
result=$(printf "echo hello_world_xyz\n!?world?\nexit\n" | ~/ecustshell/ecustshell 2>/dev/null)
count=$(echo "$result" | grep -c "hello_world_xyz")
if [ "$count" -ge 2 ]; then
    pass "!?string? 模糊匹配成功"
else
    fail "!?string? 模糊匹配失败"
fi

# --- 2.5 空历史 !! ---
echo ""
echo "--- 2.5 !! 空历史 ---"
result=$(printf "!!\nexit\n" | ~/ecustshell/ecustshell 2>/dev/null)
if echo "$result" | grep -q "no history"; then
    pass "!! 空历史正确提示"
else
    fail "!! 空历史未正确提示"
fi

# --- 2.6 !n 越界 ---
echo ""
echo "--- 2.6 !n 越界 ---"
result=$(printf "echo test\n!99\nexit\n" | ~/ecustshell/ecustshell 2>/dev/null)
if echo "$result" | grep -q "no such history"; then
    pass "!n 越界正确提示"
else
    fail "!n 越界未正确提示"
fi

# --- 2.7 三级管道 ---
echo ""
echo "--- 2.7 三级管道 ---"
result=$(printf "echo 'aaa\nbbb\nccc' | grep a | wc\nexit\n" | ~/ecustshell/ecustshell 2>/dev/null)
if echo "$result" | grep -q "total lines"; then
    pass "三级管道正常"
else
    fail "三级管道异常"
fi

# --- 2.8 后台命令无僵尸 ---
echo ""
echo "--- 2.8 后台命令无僵尸 ---"
result=$(printf "sleep 1 &\nsleep 1 &\nsleep 1 &\nexit\n" | ~/ecustshell/ecustshell 2>/dev/null)
zombie_count=$(echo "$result" | grep -c "defunct" 2>/dev/null || echo 0)
if [ "$zombie_count" -eq 0 ]; then
    pass "后台命令无僵尸进程 ($zombie_count)"
else
    fail "发现 $zombie_count 个僵尸进程"
fi

# ============================================================
# 汇总
# ============================================================
echo ""
echo "============================================"
echo "  测试结果汇总"
echo "============================================"
echo -e "${GREEN}通过: $PASS${NC}"
echo -e "${RED}失败: $FAIL${NC}"
echo "总计: $((PASS + FAIL))"
echo ""

if [ "$FAIL" -eq 0 ]; then
    echo -e "${GREEN}🎉 所有测试通过！分工1和分工2功能均正常！${NC}"
else
    echo -e "${RED}⚠️  有 $FAIL 个测试失败，请检查上述输出${NC}"
fi

# 清理
cd /
rm -rf /tmp/test_ecust
