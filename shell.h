/**
 * ------------------shell.h-----------------------
 *  Data structure and library needed by program
 *
 *  Author: xiabee
 *  Date  : 2020.1.18
 *  Modified: 2026.7.7 - renamed to ecustshell, removed my* prefix
 *  Compiling environment: gcc version 10.2.1+ (Linux)
 * ---------------------------------------------
 */

#ifndef _SHELL_H
#define _SHELL_H

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <ctype.h>
#include <pwd.h>
#include <string.h>
#include <signal.h>
#include <fcntl.h>
#include <sys/wait.h>
#include <errno.h>
#include <dirent.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <utime.h>
#include <sys/types.h>
#include <grp.h>
#include <time.h>

/* --- Command module includes --- */
#include "cp.c"
#include "ps.c"
#include "ls.c"
#include "cd.c"
#include "time_cmd.c"
#include "tree.c"
#include "rm.c"
#include "mv.c"
#include "wc.c"

#define MAXN 1024
#define BUFFSIZE 1024
#define LEN 128

const char *COMMAND_EXIT = "exit";
const char *COMMAND_HELP = "help";
const char *COMMAND_CD  = "cd";
const char *COMMAND_IN  = "<";
const char *COMMAND_IN2 = "<<";
const char *COMMAND_OUT  = ">";
const char *COMMAND_OUT2 = ">>";
const char *COMMAND_PIPE = "|";

char *arglist[MAXN];
char history[MAXN][MAXN];
int  cmd_cnt = 0;
int  argc    = 0;

enum {
    RESULT_NORMAL,
    ERROR_FORK,
    ERROR_COMMAND,
    ERROR_WRONG_PARAMETER,
    ERROR_MISS_PARAMETER,
    ERROR_TOO_MANY_PARAMETER,
    ERROR_CD,
    ERROR_SYSTEM,
    ERROR_EXIT,
    ERROR_MANY_IN,
    ERROR_MANY_OUT,
    ERROR_FILE_NOT_EXIST,
    ERROR_PIPE,
    ERROR_PIPE_MISS_PARAMETER
};

int flag;

/* --- Alias table (used by alias/unalias) --- */
#define ALIAS_MAX 64
typedef struct {
    char name[64];
    char value[256];
} Alias;
Alias alias_table[ALIAS_MAX];
int   alias_cnt;

/* --- Shell registry (shells / shell / use) --- */
#define SHELL_MAX 32
typedef struct {
    char name[32];
    char path[256];
} ShellEntry;
ShellEntry shell_registry[SHELL_MAX];
int        shell_cnt;
char       current_shell[256];

#endif
