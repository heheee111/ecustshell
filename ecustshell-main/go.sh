#!/bin/bash
# ecustshell 一键安装+编译+测试脚本
# 在 Ubuntu 终端中运行: bash /mnt/hgfs/ecustshell/go.sh
# 如果共享文件夹不可用: bash ~/ecustshell/go.sh

echo ">>> 安装编译工具..."
sudo apt install -y gcc make 2>/dev/null

echo ""
echo ">>> 编译 ecustshell..."
cd ~/ecustshell
make clean 2>/dev/null
gcc -w -o ecustshell shell.c 2>&1

if [ ! -f "./ecustshell" ]; then
    echo "编译失败！"
    exit 1
fi
echo "编译成功！"

echo ""
echo "============================================"
echo "  分工1 & 分工2 自动验证"
echo "============================================"

PASS=0
FAIL=0
run_test() {
    local name="$1"
    local input="$2"
    local expected="$3"
    local result
    result=$(printf "${input}\nexit\n" | ./ecustshell 2>/dev/null)
    if echo "$result" | grep -q "$expected"; then
        echo "[PASS] $name"
        PASS=$((PASS+1))
    else
        echo "[FAIL] $name"
        FAIL=$((FAIL+1))
    fi
}

cd /tmp
rm -rf test_ecust 2>/dev/null
mkdir -p test_ecust
cd test_ecust
echo "hello world" > test.txt
echo "line2" >> test.txt
mkdir subdir

echo ""
echo "--- 分工1 ---"
run_test "help"      "help"              "ecustshell"
run_test "pwd"       "pwd"               "test_ecust"
run_test "echo VAR"  'echo $HOME'        "/home"
run_test "type ls"   "type ls"           "builtin"
run_test "type bash" "type bash"         "/"
run_test "alias"     "alias xx='ls'\nalias"  "xx"
run_test "ls"        "ls"                "test.txt"
run_test "ls -a"     "ls -a"             "\.\."
run_test "wc"        "wc test.txt"       "total lines"
run_test "tree"      "tree . 2"          "subdir"
run_test "ps"        "ps"                "PID"
run_test "history"   "pwd\nls\nhistory"  "Input History"
run_test "shells"    "shells"            "Registered"
run_test "shell"     "shell current"     "ecustshell"
run_test "pipe"      "echo hi | wc"      "total lines"

echo ""
echo "--- 分工2 ---"
run_test "background &"  "sleep 1 &"       "\[.*\]"
run_test "!!"            "echo xyz\n!!"    "xyz"
run_test "!n"            "echo first\n!1"  "first"
run_test "!?string?"     "echo hello999\n!?hello?"  "hello999"
run_test "!! no history" "!!"              "no history"
run_test "!n out range"  "echo t\n!99"     "no such history"
run_test "3-level pipe"  "echo a | grep a | wc"  "total lines"

echo ""
echo "============================================"
echo "  结果: 通过=$PASS  失败=$FAIL  共=$((PASS+FAIL))"
echo "============================================"

cd /
rm -rf /tmp/test_ecust
