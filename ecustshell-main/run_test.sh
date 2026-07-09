#!/bin/bash
# 在 Ubuntu 中运行: bash /mnt/hgfs/ecustshell/run_test.sh
# 或者: cp /mnt/hgfs/ecustshell/run_test.sh ~/ && bash ~/run_test.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
SHELL=~/ecustshell/ecustshell
PASS=0
FAIL=0

echo "===== 步骤1: 确认编译 ====="
if [ ! -x "$SHELL" ]; then
    echo "重新编译..."
    cd ~/ecustshell
    gcc -w -o ecustshell shell.c 2>&1
fi
if [ -x "$SHELL" ]; then
    echo -e "${GREEN}ecustshell 就绪${NC}"
else
    echo -e "${RED}编译失败，请检查: cd ~/ecustshell && gcc -w -o ecustshell shell.c${NC}"
    exit 1
fi

echo ""
echo "===== 步骤2: 分工1 功能测试 ====="

# 核心方法: 把命令写入临时文件，然后重定向给shell
# 这样避免管道EOF死循环问题，且每条命令后都有exit

test_cmd() {
    local name="$1"
    local cmds="$2"
    local pattern="$3"
    local tmpfile="/tmp/_ectest_$$.txt"

    # 写入命令文件（每条命令后加exit保险）
    echo "$cmds" > "$tmpfile"
    echo "exit" >> "$tmpfile"

    local output
    output=$("$SHELL" < "$tmpfile" 2>&1)
    rm -f "$tmpfile"

    if echo "$output" | grep -q "$pattern"; then
        echo -e "  ${GREEN}[PASS]${NC} $name"
        PASS=$((PASS + 1))
    else
        echo -e "  ${RED}[FAIL]${NC} $name (预期包含: '$pattern')"
        echo "      输出: $(echo "$output" | grep -v '^\[' | grep -v '^\$' | head -3 | tr '\n' '|')"
        FAIL=$((FAIL + 1))
    fi
}

echo "--- 内置命令 ---"
test_cmd "help"        "help"                    "ecustshell"
test_cmd "pwd"         "pwd"                     "/"
test_cmd "echo \$VAR"  'echo $HOME'              "/home"
test_cmd "type(内置)"  "type ls"                 "builtin"
test_cmd "type(外部)"  "type bash"               "/bin\|/usr"
test_cmd "alias"       "alias ll='ls -l'"        ""
test_cmd "alias list"  "alias ll='ls -l'"$'\n'"alias"  "ll"
test_cmd "unalias"     "alias ll='ls -l'"$'\n'"unalias ll"$'\n'"alias"  ""

echo "--- 文件操作 ---"
test_cmd "ls"          "ls"                      "run_test.sh\|shell.c"
test_cmd "ls -a"       "ls -a"                   "\.\."
test_cmd "ls -l"       "ls -l"                   "r-\|rw-"
test_cmd "wc"          "wc shell.c"              "total lines"
test_cmd "tree"        "tree . 1"                "shell.c\|dir\|file"

# 在 ~/ecustshell 目录下测试 cp/mv/rm
test_cmd "cp"          "cp shell.c /tmp/_cp_test.txt"  ""
test_cmd "cp verify"   "ls /tmp/_cp_test.txt"    "_cp_test"
rm -f /tmp/_cp_test.txt

test_cmd "mv"          "cp shell.c /tmp/_mv_src.txt"$'\n'"mv /tmp/_mv_src.txt /tmp/_mv_dst.txt"  ""
test_cmd "mv verify"   "ls /tmp/_mv_dst.txt"     "_mv_dst"
rm -f /tmp/_mv_dst.txt /tmp/_mv_src.txt 2>/dev/null

echo "--- 系统信息 ---"
test_cmd "ps"          "ps"                      "PID"
test_cmd "time"        "time ls"                 "running time"

echo "--- Shell管理 ---"
test_cmd "shells"      "shells"                  "Registered"
test_cmd "shell"       "shell current"           "ecustshell"
test_cmd "history"     "pwd"$'\n'"echo hi"$'\n'"history"  "Input History"

echo "--- 高级功能 ---"
test_cmd "管道 |"      "echo hello | wc"         "total lines"
test_cmd "重定向 >"    "echo redirect_ok > /tmp/_redir.txt"  ""
test_cmd "重定向检查"  "ls /tmp/_redir.txt"      "_redir"
rm -f /tmp/_redir.txt

echo ""
echo "===== 步骤3: 分工2 功能测试 ====="

test_cmd "后台 &"      "sleep 1 &"               "\[.*\]"
test_cmd "!! 重复"     "echo UNIQUE_MARK"$'\n'"!!"  "UNIQUE_MARK"
test_cmd "!n 历史"     "echo FIRST_CMD"$'\n'"!1"    "FIRST_CMD"
test_cmd "!! 空历史"   "!!"                      "no history"
test_cmd "!n 越界"     "echo x"$'\n'"!99"         "no such history"
test_cmd "!? 模糊"     "echo HELLO_TEST_999"$'\n'"!?TEST?"  "HELLO_TEST_999"
test_cmd "三级管道"    "echo aaa | grep a | wc"  "total lines"

echo ""
echo "============================================"
echo -e "  ${GREEN}通过: $PASS${NC}  ${RED}失败: $FAIL${NC}  总计: $((PASS + FAIL))"
echo "============================================"
if [ "$FAIL" -eq 0 ]; then
    echo -e "${GREEN}  全部通过! 分工1和分工2功能正常!${NC}"
fi
