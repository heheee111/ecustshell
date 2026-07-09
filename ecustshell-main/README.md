# ecustshell

ECUST 操作系统课程设计——Shell 编程项目。

基于 [MyShell](https://github.com/xiabee/MyShell) 重构，实现 Linux shell 命令解释器。

---

## 一、环境准备（VirtualBox + Ubuntu）

### 1. 安装 VirtualBox

从 [virtualbox.org](https://www.virtualbox.org/wiki/Downloads) 下载 Windows 版本安装。

### 2. 下载 Ubuntu 24.04 ISO

清华镜像（推荐）：https://mirrors.tuna.tsinghua.edu.cn/ubuntu-releases/24.04/ubuntu-24.04.4-desktop-amd64.iso

### 3. 创建虚拟机

| 配置项 | 建议值 |
|--------|--------|
| 内存 | 8 GB |
| CPU | 4 核 |
| 磁盘 | 30 GB |
| 显存 | 128 MB |

### 4. 安装 Ubuntu

虚拟机启动后，选择 Install Ubuntu → Erase disk and install Ubuntu，按提示完成。

### 5. 配置共享文件夹（可选）

```bash
sudo adduser $USER vboxsf
sudo reboot
```

### 6. 安装编译工具

```bash
sudo apt update && sudo apt install -y gcc git
```

---

## 二、编译运行

```bash
git clone https://github.com/heheee111/ecustshell.git
cd ecustshell
gcc -w -o ecustshell shell.c
./ecustshell
```

或使用 Makefile：

```bash
make        # 编译
make run    # 编译并运行
make clean  # 清理
```

> **注意：** 当前架构采用文本包含方式（shell.h `#include` 各 .c 文件），故只需编译 shell.c 一个文件。改为多文件链接编译需要在交接任务中完成。

---

## 三、功能列表

### 内置命令

| 命令 | 功能 | 用法示例 |
|------|------|----------|
| `help` | 显示所有内置命令 | `help` |
| `pwd` | 显示当前工作目录 | `pwd` |
| `cd` | 切换工作目录 | `cd /tmp`, `cd ~` |
| `exit` | 退出 shell | `exit` |
| `echo` | 输出文本，支持 `$VAR` 展开 | `echo hello`, `echo $HOME` |
| `type` | 判断命令类型（内置/外部/别名） | `type ls`, `type bash` |
| `history` | 查看命令历史 | `history` |

### 文件操作

| 命令 | 功能 | 用法示例 |
|------|------|----------|
| `ls` | 列出文件，支持 `-a` `-l` `-al` | `ls`, `ls -l`, `ls -a` |
| `cp` | 复制文件/目录（递归，含软链接） | `cp src dst` |
| `mv` | 移动或重命名文件/目录 | `mv old new` |
| `rm` | 递归强制删除文件/目录 | `rm file`, `rm dir` |
| `wc` | 统计文件或目录总行数 | `wc shell.c` |
| `tree` | 显示目录树，可指定深度(1~9) | `tree .`, `tree . 3` |

### 系统信息

| 命令 | 功能 | 用法示例 |
|------|------|----------|
| `ps` | 显示所有进程信息 | `ps` |
| `time` | 测量命令执行时间 | `time ls` |

### Shell 管理

| 命令 | 功能 | 用法示例 |
|------|------|----------|
| `shells` | 列出所有已注册的 shell | `shells` |
| `shell current` | 查看当前使用的 shell | `shell current` |
| `use` | 切换到其他 shell（exit 返回） | `use bash` |

### 别名

| 命令 | 功能 | 用法示例 |
|------|------|----------|
| `alias` | 创建别名 / 查看所有别名 | `alias ll='ls -l'`, `alias` |
| `unalias` | 删除别名 | `unalias ll` |

### 高级功能

| 功能 | 说明 | 示例 |
|------|------|------|
| 管道 `\|` | 连接多个命令 | `ls -l \| wc` |
| 输出重定向 `>` | 覆盖写入文件 | `ls > out.txt` |
| 输出追加重定向 `>>` | 追加写入文件 | `ls >> out.txt` |
| 输入重定向 `<` | 从文件读取输入 | `cat < input.txt` |

---

## 四、分工1 完成内容（基于源代码的改动）

> 基准代码：[xiabee/MyShell](https://github.com/xiabee/MyShell)（2020年）

### 4.1 命名规范化

| 改动 | 说明 |
|------|------|
| Shell 改名 | `XSLF bash` → **ecustshell**，帮助文本全部重写 |
| 命令去 my* 前缀 | `myls`→`ls`, `mycd`→`cd`, `mycp`→`cp`, `mymv`→`mv`, `myrm`→`rm`, `myps`→`ps`, `mytime`→`time`, `mytree`→`tree`, `myline`→`wc`, `myhis`→`history` |
| 文件名重命名 | `mycd.c`→`cd.c`, `mycp.c`→`cp.c` 等全部 9 个文件 |

### 4.2 系统调用修正

| 改动 | 位置 | 说明 |
|------|------|------|
| `vfork()` → `fork()` | shell.c `callCommandWithRedi()`, `callCommandWithPipe()` | POSIX 已废弃 vfork，子进程修改父进程地址空间有安全隐患 |

### 4.3 新增内置命令

| 命令 | 代码位置 | 功能 |
|------|----------|------|
| `echo` | shell.c `builtin_echo()` | 输出文本，支持 `$HOME` `$USER` 等环境变量展开 |
| `type` | shell.c `builtin_type()` | 判断命令类型：内置/外部（搜索 PATH）/别名 |
| `alias` | shell.c `builtin_alias()` | 创建别名（`alias ll='ls -l'`）、列出所有别名 |
| `unalias` | shell.c `builtin_unalias()` | 删除指定别名 |
| `shells` | shell.c `builtin_shells()` | 扫描系统 shell（bash/sh/zsh 等）并列出 |
| `shell current` | shell.c `builtin_shell()` | 显示当前使用的 shell |
| `use` | shell.c `builtin_use()` | fork+exec 切换到目标 shell，exit 后返回 |

### 4.4 Bug 修复

| 问题 | 修复 |
|------|------|
| 内置命令重定向失效（`ls > file` 仍输出到屏幕） | `inner()` 增加 `has_operator()` 预检，检测到 `>` `<` `\|` 时跳过内置处理，走 `callCommandWithRedi()` |
| `wc` 段错误（文件不存在时 `opendir(NULL)`） | wc.c 增加 `stat()` 和 `opendir()` 返回值检查 |

### 4.5 工程化

| 改动 | 说明 |
|------|------|
| 新增 `Makefile` | `make` / `make run` / `make clean`，含多文件链接的未来重构目标 |
| 新增 `.gitignore` | 忽略二进制文件和 .o 中间文件 |
| 新增 `alias_table[]` 和 `shell_registry[]` | 为后续分工的 alias / shell 管理功能预留数据结构 |

---

## 五、分工2、3 交接任务

### 分工2：后台运行 + 历史增强 + 管道修复

#### 具体任务

| 序号 | 任务 | 说明 |
|------|------|------|
| 2.1 | 后台运行 `&` | 命令末尾 `&` 时，父进程不 `wait()`，直接打印子进程 PID 并返回提示符 |
| 2.2 | 历史命令执行 | `!n` 执行第 n 条历史命令；`!!` 重复上一条；`!?string?` 模糊匹配最近一条含 string 的命令 |
| 2.3 | 管道边界测试 | 测试 `cmd1 | cmd2 | cmd3` 三级管道，修复 `callCommandWithPipe()` 递归中可能的 fd 泄漏 |

#### 涉及文件

- `shell.c` — `callCommand()`（加 `&` 检测）、`callCommandWithPipe()`
- 可能需要新增 `signal.c` 处理 `SIGCHLD` 回收僵尸进程

#### 易错点

- **`&` 的检测位置**：`mystrtok()` 分词后，需在 `callCommand()` 中判断 `arglist[argc-1]` 是否为 `"&"`，是则移除并设置后台标志。不能在 `inner()` 里判断——`inner()` 处理完就 return 了。
- **僵尸进程**：后台进程结束后变成僵尸，需在 `Init()` 中用 `waitpid(-1, &status, WNOHANG)` 轮询回收。
- **`!n` 越界**：n 可能超出 `cmd_cnt`，需做边界检查。
- **`!!` 空历史**：如果历史为空（刚启动），`!!` 应提示 "no history" 而不是崩溃。

#### 验证方法

```bash
sleep 5 &        # 应立刻返回提示符，5秒后无僵尸
ls -l &          # 应打印 PID 并返回提示符
history          # 查看历史
!1               # 执行第1条
!!               # 重复上一条
ls -l | grep ecust | wc   # 三级管道
```

---

### 分工3：新增命令 + 别名扩展 + Tab 补全

#### 具体任务

| 序号 | 任务 | 说明 |
|------|------|------|
| 3.1 | 新增 `cat` 命令 | 读取文件内容输出到屏幕，支持多个文件拼接：`cat a.txt b.txt` |
| 3.2 | 新增 `grep` 命令 | 按行匹配字符串，支持 `-i`（忽略大小写）、`-n`（显示行号） |
| 3.3 | Tab 命令补全 | 按 Tab 补全命令名/文件名，双击 Tab 列出所有候选项 |

#### 涉及文件

- 新建 `cat.c`、`grep.c`
- 修改 `shell.h`：添加 `#include "cat.c"` `#include "grep.c"` 和函数声明
- 修改 `shell.c`：在 `inner()` 中注册 `cat`、`grep` 命令
- Tab 补全可能需要引入 GNU readline 库，或自行实现简易版（见易错点）

#### 易错点

- **cat 的缓冲区**：`cat` 大文件时别一次读入全部内容，用循环 `fgets` + `printf` 逐行输出。
- **grep 的匹配算法**：最简单的实现用 `strstr()` 即可（不要求正则）。如果实现 `-i`，需将模式和行都转小写后再比较。
- **Tab 补全的实现路线**：
  - **路线A（推荐）**：链接 GNU readline 库，`#include <readline/readline.h>`，用 `rl_bind_key()` 绑定 Tab。修改 `main()` 中用 `readline()` 替代 `fgets()`。工作量小但需 `sudo apt install libreadline-dev`，编译时加 `-lreadline`。
  - **路线B（手写）**：自行实现非阻塞读取单个字符、维护输入缓冲区、前缀匹配。代码量大（~200行），但无外部依赖。

#### Tab 补全易错点（手写路线）

- **终端原始模式**：需用 `termios` 关闭行缓冲和回显（`tcgetattr`/`tcsetattr`），否则 `getchar()` 会等回车。
- **候选列表去重**：同名前缀可能有多个文件，需维护候选数组并在双击 Tab 时打印。
- **目录补全**：`cd ` 后面按 Tab 应补全目录名而非文件名。
- **输入缓冲区管理**：用户输入、退格、Tab 补全都需要正确维护缓冲区，注意光标位置。

#### 验证方法

```bash
cat shell.c                # 输出 shell.c 内容
cat shell.c shell.h        # 拼接两个文件
grep "fork" shell.c        # 搜索 fork
grep -n "fork" shell.c     # 带行号
grep -i "FORK" shell.c     # 忽略大小写
ls <Tab>                   # 补全文件名
cd <Tab>                   # 补全目录名
```

---

## 六、项目结构

```
ecustshell/
├── .gitignore         # 忽略二进制文件
├── Makefile           # 编译脚本
├── README.md          # 本文件
├── shell.h            # 头文件：库引用、常量、数据结构、命令模块 include
├── shell.c            # 主程序：main、Init、input parsing、inner、fork/exec、pipe、redirect
├── cd.c               # cd 命令
├── cp.c               # cp 命令（文件复制 + 目录递归复制 + 软链接）
├── ls.c               # ls 命令（-a 显示隐藏文件，-l 详细列表）
├── mv.c               # mv 命令（移动/重命名，含文件属性保持）
├── ps.c               # ps 命令（遍历 /proc 获取进程信息）
├── rm.c               # rm 命令（递归强制删除）
├── time_cmd.c         # time 命令（测量运行时间）
├── tree.c             # tree 命令（DFS 目录树可视化）
├── wc.c               # wc 命令（统计行数）
├── cat.c              # [分工3] cat 命令
├── grep.c             # [分工3] grep 命令
└── LICENSE            # MIT License
```

---

## 七、常见问题

| 问题 | 解决 |
|------|------|
| 编译警告太多 | 用 `gcc -w` 忽略警告，或将 `-Wall` 改为 `-w` |
| 共享文件夹权限不足 | `sudo adduser $USER vboxsf && sudo reboot` |
| `ls > file` 无效 | 分工1 已修复，确认 shell.c 为最新版 |
| `wc` 段错误 | 分工1 已修复，确认 wc.c 为最新版 |
| `use bash` 后回不来 | 输入 `exit` 即可返回 ecustshell |
