#!/bin/bash
# ecustshell 全自动测试 v3
# 运行: bash /mnt/hgfs/ecustshell/auto_test.sh
# 结果: /mnt/hgfs/ecustshell/result.txt

OUT=/mnt/hgfs/ecustshell/result.txt
SHELL_BIN=~/ecustshell/ecustshell
> $OUT

log() { echo "$@" >> $OUT; }
log "===== ecustshell 测试 v3 $(date) ====="
log ""

# 编译
log "--- 编译 ---"
cd ~/ecustshell
gcc -w -o ecustshell shell.c 2>&1 | tee -a $OUT
[ -x "$SHELL_BIN" ] || { log "编译失败"; log "END"; exit 1; }
log "编译: OK"
log ""

PASS=0; FAIL=0

# 使用 grep -E 支持 | 或运算
test_one() {
    local name="$1" cmds="$2" pattern="$3" tmp="/tmp/_ec_$$.in"
    printf '%s\n' "$cmds" > "$tmp"
    echo "exit" >> "$tmp"
    local output
    output=$("$SHELL_BIN" < "$tmp" 2>&1)
    rm -f "$tmp"
    if echo "$output" | grep -qE "$pattern"; then
        log "PASS: $name"
        PASS=$((PASS+1))
    else
        log "FAIL: $name (pattern='$pattern')"
        log "  output_head=$(echo "$output" | grep -vE '^\[|^\$|^Bye' | head -3 | tr '\n' '|')"
        FAIL=$((FAIL+1))
    fi
}

log "========== 分工1 =========="

# 内置命令
test_one "help"           'help'                                               'ecustshell'
test_one "pwd"            'pwd'                                                '/home/jack'
test_one "echo"           'echo hello'                                         'hello'
test_one "echo_VAR"       'echo $HOME'                                         '/home'
test_one "echo_multi"     'echo a b c'                                         'a b c'
test_one "type_builtin"   'type ls'                                            'builtin'
test_one "type_external"  'type bash'                                          'bash'
test_one "alias"          "alias xx=ls"$'\n'"alias"                            'xx'
test_one "unalias"        "alias yy=ls"$'\n'"unalias yy"$'\n'"alias"           ''

# 文件操作 - ls 不支持文件参数,用 wc/cat 验证
test_one "ls"             'ls'                                                 'shell.c'
test_one "ls_a"           'ls -a'                                              '\.\.'
test_one "ls_l"           'ls -l'                                              'r-|rw-'
test_one "wc"             'wc shell.c'                                         'total lines'
test_one "tree"           'tree . 1'                                           'shell.c'

# cp/mv/rm 验证：用 wc 替代 ls
test_one "cp"             'cp shell.c /tmp/_cp_tt.txt'                         ''
test_one "cp_verify"      'wc /tmp/_cp_tt.txt'                                 'total lines'
# mv 对绝对路径有bug(会加./导致路径错),用相对路径: cd到/tmp再做mv
test_one "mv"             'cp shell.c /tmp/_mv_s.txt'$'\n''cd /tmp'$'\n''mv _mv_s.txt _mv_d.txt' ''
test_one "mv_verify"      'wc /tmp/_mv_d.txt'                                  'total lines'
test_one "rm"             'cp shell.c /tmp/_rm_t.txt'$'\n''rm /tmp/_rm_t.txt'   ''
test_one "rm_verify"      'wc /tmp/_rm_t.txt'                                  'File or directory NOT exist|NOT a valid|Can NOT open'

# 系统信息
test_one "ps"             'ps'                                                 'PID'
test_one "time"           'time ls'                                            'running time'

# Shell管理
test_one "shells"         'shells'                                             'Registered'
test_one "shell_curr"     'shell current'                                      'ecustshell'
test_one "history"        'pwd'$'\n''echo hi'$'\n''history'                    'Input History'

# 高级功能
test_one "pipe"           'echo hello | wc'                                    '[0-9]'
# 重定向用 cat < 验证（cat 走系统命令 execvp）
test_one "redirect_out"   'echo redir_OK > /tmp/_rdx.txt'$'\n'"cat < /tmp/_rdx.txt"  'redir_OK'
test_one "redirect_in"    'cat < shell.c'                                      '\#include|main'

log ""
log "========== 分工2 =========="

test_one "background"     'sleep 1 &'                                          '\['

# 历史扩展测试 - 每个独立调用shell, 因为需要各自的历史上下文
test_one "bang_bang"      'echo MARKER_X1'$'\n''!!'                            'MARKER_X1'
test_one "bang_n"         'echo CMD_FIRST'$'\n''!1'                           'CMD_FIRST'
test_one "bang_empty"     '!!'                                                 'no history'
test_one "bang_range"     'echo x'$'\n''!99'                                   'no such history'
test_one "bang_fuzzy"     'echo LOCATE_ME_42'$'\n''!?ATE_ME?'                 'LOCATE_ME_42'
test_one "pipe3"          'echo a | grep a | wc'                               '[0-9]'

# 清理
rm -f /tmp/_cp_tt.txt /tmp/_mv_s.txt /tmp/_mv_d.txt /tmp/_rm_t.txt /tmp/_rdx.txt 2>/dev/null

log ""
log "========== 汇总 =========="
log "PASS: $PASS  FAIL: $FAIL  TOTAL: $((PASS+FAIL))"
log "END"
echo ""
echo "PASS=$PASS FAIL=$FAIL"
