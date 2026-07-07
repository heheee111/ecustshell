/**
 * ------------------ecustshell-----------------------
 * Main Function of the shell
 * Simulate the implementation of shell
 *
 *  Author: xiabee  (original MyShell)
 *  Modified: ecustshell team, 2026.7.7
 *   - renamed to ecustshell
 *   - removed my* prefix from all commands
 *   - vfork() replaced with fork()
 *   - added echo, type, alias, unalias builtins
 *  Compiling environment: gcc (Linux)
 * ---------------------------------------------
 */

#include "shell.h"

int find(char *str, char *ch)
{
    int len1 = strlen(str);
    int len2 = strlen(ch);
    int flag = 1;
    if (len1 < len2) return -1;
    for (int i = 0; i < len1 - len2 + 1; i++) {
        flag = 1;
        for (int j = 0; j < len2; j++) {
            if (str[i + j] != ch[j]) { flag = 0; break; }
        }
        if (flag) return i;
    }
    return -1;
}

void Init()
{
    argc = 0;
    memset(arglist, 0x00, sizeof(arglist));
    char pwd[LEN], name[LEN];
    struct passwd *pass;
    gethostname(name, sizeof(name) - 1);
    pass = getpwuid(getuid());
    getcwd(pwd, sizeof(pwd) - 1);
    int len = strlen(pwd);
    char *ph = pwd + len - 1;
    while (*ph != '/' && len--) ph--;
    ph++;
    printf("\e[32;1m[%s @ %s %s]\n\e[0m\e[31;1m$ \e[0m", pass->pw_name, name, ph);
}

int execute(char *arglist[])
{
    int err = execvp(arglist[0], arglist);
    if (-1 == err) { printf("Execute Failed!\n"); exit(-1); }
    return err;
}

char *make(char *buf)
{
    char *arc = malloc(strlen(buf) + 1);
    if (arc == NULL) { fprintf(stderr, "No Memory!\n"); exit(1); }
    strcpy(arc, buf);
    return arc;
}

int mystrtok(char *str, char *delim)
{
    char *token = NULL, *save = NULL;
    argc = 0;
    char chBuffer[MAXN];
    char *token1 = NULL, *tmp = NULL, *save1 = NULL;
    char *operator[] = {">>", "<<", ">", "<", "|"};
    int opline = sizeof(operator) / sizeof(operator[0]);

    strncpy(chBuffer, str, sizeof(chBuffer) - 1);
    token = chBuffer;
    while (NULL != (token = strtok_r(token, delim, &save))) {
        for (int i = 0; i < opline; i++) {
            if (strlen(token) > 1 && find(token, operator[i]) != -1) {
                if (find(token, operator[i]) == 0) {
                    arglist[argc++] = make(operator[i]);
                    token1 = strtok_r(token, operator[i], &save1);
                    arglist[argc++] = make(token1);
                } else if (find(token, operator[i]) == strlen(token) - 1) {
                    token1 = strtok_r(token, operator[i], &save1);
                    arglist[argc++] = make(token1);
                    arglist[argc++] = make(operator[i]);
                } else {
                    token1 = strtok_r(token, operator[i], &save1);
                    arglist[argc++] = make(token1);
                    arglist[argc++] = make(operator[i]);
                    arglist[argc++] = make(save1);
                }
                token1 = NULL; save1 = NULL;
                strcmp(token, tmp);
            }
        }
        arglist[argc++] = make(token);
        token = NULL;
    }
    return argc;
}

/* ---- echo: print text, expand $VAR ---- */
int builtin_echo(int argc, char *arglist[])
{
    for (int i = 1; i < argc; i++) {
        char *s = arglist[i];
        if (s[0] == '$') {
            char *val = getenv(s + 1);
            printf("%s", val ? val : "");
        } else {
            printf("%s", s);
        }
        if (i < argc - 1) printf(" ");
    }
    printf("\n");
    return 1;
}

/* ---- type: tell what a command is ---- */
int builtin_type(int argc, char *arglist[])
{
    if (argc < 2) {
        printf("type: usage: type <command>\n");
        return 1;
    }
    const char *builtins[] = {
        "exit", "help", "cd", "pwd", "echo", "type",
        "ls", "cp", "mv", "rm", "ps", "time", "tree", "wc",
        "alias", "unalias", "history", NULL
    };
    for (int i = 0; builtins[i]; i++) {
        if (strcmp(arglist[1], builtins[i]) == 0) {
            printf("%s is a shell builtin\n", arglist[1]);
            return 1;
        }
    }
    /* check alias table */
    for (int i = 0; i < alias_cnt; i++) {
        if (strcmp(arglist[1], alias_table[i].name) == 0) {
            printf("%s is aliased to '%s'\n", arglist[1], alias_table[i].value);
            return 1;
        }
    }
    /* search PATH */
    char *path = getenv("PATH");
    if (path) {
        char *dup = strdup(path);
        char *dir = strtok(dup, ":");
        while (dir) {
            char full[512];
            snprintf(full, sizeof(full), "%s/%s", dir, arglist[1]);
            if (access(full, X_OK) == 0) {
                printf("%s is %s\n", arglist[1], full);
                free(dup);
                return 1;
            }
            dir = strtok(NULL, ":");
        }
        free(dup);
    }
    printf("type: %s: not found\n", arglist[1]);
    return 1;
}

/* ---- alias / unalias ---- */
int builtin_alias(int argc, char *arglist[])
{
    if (argc == 1) {
        for (int i = 0; i < alias_cnt; i++)
            printf("alias %s='%s'\n", alias_table[i].name, alias_table[i].value);
        return 1;
    }
    char *eq = strchr(arglist[1], '=');
    if (eq) {
        *eq = '\0';
        char *name = arglist[1];
        char *val  = eq + 1;
        if (*val == '\'' || *val == '"') { val++; val[strlen(val)-1] = '\0'; }
        /* update existing or add new */
        for (int i = 0; i < alias_cnt; i++) {
            if (strcmp(alias_table[i].name, name) == 0) {
                strcpy(alias_table[i].value, val);
                return 1;
            }
        }
        if (alias_cnt < ALIAS_MAX) {
            strcpy(alias_table[alias_cnt].name, name);
            strcpy(alias_table[alias_cnt].value, val);
            alias_cnt++;
        }
    }
    return 1;
}

int builtin_unalias(int argc, char *arglist[])
{
    if (argc < 2) { printf("unalias: usage: unalias <name>\n"); return 1; }
    for (int i = 0; i < alias_cnt; i++) {
        if (strcmp(alias_table[i].name, arglist[1]) == 0) {
            for (int j = i; j < alias_cnt - 1; j++)
                alias_table[j] = alias_table[j + 1];
            alias_cnt--;
            return 1;
        }
    }
    printf("unalias: %s: not found\n", arglist[1]);
    return 1;
}

/* ---- resolve alias before executing ---- */
char *resolve_alias(char *cmd)
{
    for (int i = 0; i < alias_cnt; i++)
        if (strcmp(cmd, alias_table[i].name) == 0)
            return alias_table[i].value;
    return NULL;
}

/* ---- shell registry: scan / register / list / use ---- */
void init_shell_registry()
{
    shell_cnt = 0;
    /* Scan common shell paths */
    const char *paths[] = {
        "/bin/sh", "/bin/bash", "/bin/dash", "/bin/zsh",
        "/bin/ksh", "/bin/csh", "/bin/tcsh",
        "/usr/bin/sh", "/usr/bin/bash", "/usr/bin/zsh",
        NULL
    };
    for (int i = 0; paths[i]; i++) {
        if (access(paths[i], X_OK) == 0 && shell_cnt < SHELL_MAX) {
            /* extract simple name from path */
            const char *p = strrchr(paths[i], '/');
            char *name = (p ? (char *)(p + 1) : (char *)paths[i]);
            /* check for duplicates */
            int dup = 0;
            for (int j = 0; j < shell_cnt; j++)
                if (strcmp(shell_registry[j].name, name) == 0) dup = 1;
            if (!dup) {
                strcpy(shell_registry[shell_cnt].name, name);
                strcpy(shell_registry[shell_cnt].path, paths[i]);
                shell_cnt++;
            }
        }
    }
    /* always include ecustshell itself */
    strcpy(shell_registry[shell_cnt].name, "ecustshell");
    strcpy(shell_registry[shell_cnt].path, "./ecustshell");
    shell_cnt++;

    strcpy(current_shell, "ecustshell");
}

int builtin_shells(int argc, char *arglist[])
{
    (void)argc; (void)arglist;
    printf("Registered shells:\n");
    for (int i = 0; i < shell_cnt; i++) {
        printf("  [%d] %-12s → %s", i, shell_registry[i].name, shell_registry[i].path);
        if (strcmp(shell_registry[i].name, current_shell) == 0)
            printf("  \e[32;1m(current)\e[0m");
        printf("\n");
    }
    printf("Use 'shell current' to see active shell, 'use <name>' to switch.\n");
    return 1;
}

int builtin_shell(int argc, char *arglist[])
{
    if (argc >= 2 && strcmp(arglist[1], "current") == 0) {
        printf("Current shell: \e[32;1m%s\e[0m\n", current_shell);
    } else {
        printf("ecustshell — ECUST OS Course Shell\n");
        printf("Current: %s  |  Registered: %d shells\n", current_shell, shell_cnt);
        printf("Usage: shell current   — show active shell\n");
        printf("       shells          — list all registered shells\n");
        printf("       use <name>      — switch to another shell\n");
    }
    return 1;
}

int builtin_use(int argc, char *arglist[])
{
    if (argc < 2) {
        printf("Usage: use <shell-name>\n");
        printf("Run 'shells' to see available shells.\n");
        return 1;
    }
    for (int i = 0; i < shell_cnt; i++) {
        if (strcmp(shell_registry[i].name, arglist[1]) == 0) {
            printf("Switching to %s ...\n", shell_registry[i].name);
            pid_t pid = fork();
            if (pid == 0) {
                execl(shell_registry[i].path, shell_registry[i].name, (char *)NULL);
                perror("execl failed");
                exit(1);
            } else if (pid > 0) {
                int status;
                waitpid(pid, &status, 0);
                printf("Returned to ecustshell.\n");
            }
            return 1;
        }
    }
    printf("Shell '%s' not found. Registered shells:\n", arglist[1]);
    for (int i = 0; i < shell_cnt; i++)
        printf("  %s\n", shell_registry[i].name);
    return 1;
}

/* check if any arg is a redirection/pipe operator */
static int has_operator(int argc, char *arglist[])
{
    for (int i = 0; i < argc; i++) {
        if (strcmp(arglist[i], "<") == 0 || strcmp(arglist[i], ">") == 0 ||
            strcmp(arglist[i], ">>") == 0 || strcmp(arglist[i], "<<") == 0 ||
            strcmp(arglist[i], "|") == 0)
            return 1;
    }
    return 0;
}

int inner(char *arglist[])
{
    /* redirectable builtins: skip inner if > < | present */
    const char *redir_ok[] = {"ls", "ps", "wc", "echo", "tree", "shells", NULL};
    int can_redirect = 0;
    for (int i = 0; redir_ok[i]; i++)
        if (strcmp(arglist[0], redir_ok[i]) == 0) can_redirect = 1;
    if (can_redirect && has_operator(argc, arglist))
        return 0;  /* let callCommand handle redirection */

    if (strcmp(arglist[0], "exit\0") == 0) {
        printf("Bye~\n"); exit(0); return 1;
    }
    if (strcmp(arglist[0], "help\0") == 0) {
        printf("ecustshell, version 1.0 (x86_64-linux-gnu)\n");
        printf("ECUST OS Course Design — Shell Project\n\n");
        printf("These shell commands are defined internally:\n\n");
        printf("  pwd       Show current working directory\n");
        printf("  cd        Change working directory\n");
        printf("  ls        List files (-a -l supported)\n");
        printf("  cat       Display file contents\n");
        printf("  cp        Copy source to destination\n");
        printf("  mv        Move or rename file/directory\n");
        printf("  rm        Remove file or directory\n");
        printf("  ps        Display process information\n");
        printf("  time      Measure running time of a process\n");
        printf("  tree      Show directory structure\n");
        printf("  wc        Count lines of a file or directory\n");
        printf("  echo      Print text (supports $VAR expansion)\n");
        printf("  type      Show command type\n");
        printf("  alias     Create or list command aliases\n");
        printf("  unalias   Remove an alias\n");
        printf("  shells    List all registered shells\n");
        printf("  shell     Show current shell info\n");
        printf("  use       Switch to another shell\n");
        printf("  history   Show input history\n");
        printf("  exit      Exit the shell\n");
        printf("\n");
        return 1;
    }
    if (strcmp(arglist[0], "pwd\0") == 0) {
        char buf[LEN]; getcwd(buf, sizeof(buf));
        printf("%s\n\n", buf); return 1;
    }
    if (strcmp(arglist[0], "echo\0") == 0)
        return builtin_echo(argc, arglist);
    if (strcmp(arglist[0], "type\0") == 0)
        return builtin_type(argc, arglist);
    if (strcmp(arglist[0], "alias\0") == 0)
        return builtin_alias(argc, arglist);
    if (strcmp(arglist[0], "unalias\0") == 0)
        return builtin_unalias(argc, arglist);
    if (strcmp(arglist[0], "shells\0") == 0)
        return builtin_shells(argc, arglist);
    if (strcmp(arglist[0], "shell\0") == 0)
        return builtin_shell(argc, arglist);
    if (strcmp(arglist[0], "use\0") == 0)
        return builtin_use(argc, arglist);
    if (strcmp(arglist[0], "cd\0") == 0) {
        mycd(argc, arglist); return 1;
    }
    if (strcmp(arglist[0], "cp\0") == 0) {
        struct stat statbuf; struct utimbuf timeby;
        if (Check(argc, arglist, statbuf)) return -1;
        Mycp(arglist[1], arglist[2]);
        stat(arglist[1], &statbuf);
        timeby.actime = statbuf.st_atime;
        timeby.modtime = statbuf.st_mtime;
        utime(arglist[2], &timeby);
        printf("Copy Finished!\n\n"); return 1;
    }
    if (strcmp(arglist[0], "ps\0") == 0)  { myps();                  return 1; }
    if (strcmp(arglist[0], "ls\0") == 0)  { ls(argc, arglist);      return 1; }
    if (strcmp(arglist[0], "time\0") == 0) { mytime(argc, arglist);    return 1; }
    if (strcmp(arglist[0], "tree\0") == 0) { tree(argc, arglist);    return 1; }
    if (strcmp(arglist[0], "rm\0") == 0)  { myrm(argc, arglist);      return 1; }
    if (strcmp(arglist[0], "mv\0") == 0)  { mv(argc, arglist);      return 1; }
    if (strcmp(arglist[0], "wc\0") == 0)  { wc(argc, arglist);     return 1; }

    if (strcmp(arglist[0], "history\0") == 0 || strcmp(arglist[0], "myhis\0") == 0) {
        printf("-------------------------------------\n");
        printf("**  Input History: **\n");
        for (int i = 0; i < cmd_cnt; i++) printf("%s", history[i]);
        printf("-------------------------------------\n");
        return 1;
    }
    return 0;
}

int callCommandWithRedi(int left, int right)
{
    int inNum = 0, outNum = 0;
    char *inFile = NULL, *outFile = NULL;
    int endIdx = right;

    for (int i = left; i < right; ++i) {
        if (strcmp(arglist[i], COMMAND_IN) == 0 && strcmp(arglist[i], COMMAND_IN2) != 0) {
            inNum++;
            if (i + 1 < right) inFile = arglist[i + 1];
            else return ERROR_MISS_PARAMETER;
            if (endIdx == right) endIdx = i;
        } else if (strcmp(arglist[i], COMMAND_OUT) == 0 && strcmp(arglist[i], COMMAND_OUT2) != 0) {
            outNum++;
            if (i + 1 < right) outFile = arglist[i + 1];
            else return ERROR_MISS_PARAMETER;
            if (endIdx == right) endIdx = i;
        }
    }

    if (inNum == 1) { FILE *fp = fopen(inFile, "r"); if (fp == NULL) return ERROR_FILE_NOT_EXIST; fclose(fp); }
    if (inNum > 1)  return ERROR_MANY_IN;
    if (outNum > 1) return ERROR_MANY_OUT;

    int result = RESULT_NORMAL;
    pid_t pid = fork();
    if (pid == -1) {
        result = ERROR_FORK;
    } else if (pid == 0) {
        if (inNum == 1)  freopen(inFile, "r", stdin);
        if (outNum == 1) freopen(outFile, "w", stdout);
        char *comm[MAXN];
        for (int i = left; i < endIdx; ++i) comm[i] = arglist[i];
        comm[endIdx] = NULL;
        execvp(comm[left], comm + left);
        exit(errno);
    } else {
        int status;
        waitpid(pid, &status, 0);
        int err = WEXITSTATUS(status);
        if (err) {
            printf("Command Error!\n");
            printf("You may need \e[31;1m'help'\e[0m\n\n");
        }
    }
    return result;
}

int callCommandWithPipe(int left, int right)
{
    if (left >= right) return RESULT_NORMAL;
    int pipeIdx = -1;
    for (int i = left; i < right; ++i) {
        if (strcmp(arglist[i], COMMAND_PIPE) == 0) { pipeIdx = i; break; }
    }
    if (pipeIdx == -1) return callCommandWithRedi(left, right);
    if (pipeIdx + 1 == right) return ERROR_PIPE_MISS_PARAMETER;

    int fds[2];
    if (pipe(fds) == -1) return ERROR_PIPE;
    int result = RESULT_NORMAL;
    pid_t pid = fork();

    if (pid == -1) {
        result = ERROR_FORK;
    } else if (pid == 0) {
        close(fds[0]);
        dup2(fds[1], STDOUT_FILENO);
        close(fds[1]);
        result = callCommandWithRedi(left, pipeIdx);
        exit(result);
    } else {
        int status;
        waitpid(pid, &status, 0);
        int exitCode = WEXITSTATUS(status);
        if (exitCode != RESULT_NORMAL) {
            char info[4096] = {0}, line[MAXN];
            close(fds[1]);
            dup2(fds[0], STDIN_FILENO);
            close(fds[0]);
            while (fgets(line, MAXN, stdin) != NULL) strcat(info, line);
            printf("%s", info);
            result = exitCode;
        } else if (pipeIdx + 1 < right) {
            close(fds[1]);
            dup2(fds[0], STDIN_FILENO);
            close(fds[0]);
            result = callCommandWithPipe(pipeIdx + 1, right);
        }
    }
    return result;
}

int callCommand(int commandNum)
{
    /* check alias */
    char *expanded = resolve_alias(arglist[0]);
    if (expanded) {
        char tmp[MAXN]; strcpy(tmp, expanded);
        /* simple single-word alias */
        arglist[0] = make(tmp);
    }

    pid_t pid = fork();
    if (pid == -1) return ERROR_FORK;
    if (pid == 0) {
        int inFds  = dup(STDIN_FILENO);
        int outFds = dup(STDOUT_FILENO);
        int result = callCommandWithPipe(0, commandNum);
        dup2(inFds,  STDIN_FILENO);
        dup2(outFds, STDOUT_FILENO);
        exit(result);
    } else {
        int status;
        waitpid(pid, &status, 0);
        return WEXITSTATUS(status);
    }
}

int main()
{
    char buf[MAXN];
    int result;
    cmd_cnt = 0;
    alias_cnt = 0;
    init_shell_registry();
    memset(history, 0x00, sizeof(history));
    memset(alias_table, 0x00, sizeof(alias_table));

    while (1) {
        Init();
        fflush(stdout);
        fgets(buf, BUFFSIZE, stdin);

        if (strcmp(buf, "\n") == 0) { printf("\n"); continue; }

        strcpy(history[cmd_cnt], buf);
        cmd_cnt++;
        if (cmd_cnt >= MAXN) {
            cmd_cnt = 0;
            memset(history, 0x00, sizeof(history));
            printf("--------------------------------------------\n");
            printf(" Warning: Lack of space! Reset Input History!\n");
            printf("--------------------------------------------\n");
        }

        memset(arglist, 0x00, sizeof(arglist));
        argc = mystrtok(buf, " \b\r\n\t");

        int inner_flag = inner(arglist);
        if (inner_flag) continue;

        result = callCommand(argc);
        switch (result) {
        case ERROR_FORK:          fprintf(stderr, "\e[31;1mError: Fork error.\n\e[0m");           exit(ERROR_FORK);
        case ERROR_COMMAND:       fprintf(stderr, "\e[31;1mError: Command not exist.\n\e[0m");     break;
        case ERROR_MANY_IN:       fprintf(stderr, "\e[31;1mError: Too many '<'.\n\e[0m");         break;
        case ERROR_MANY_OUT:      fprintf(stderr, "\e[31;1mError: Too many '>'.\n\e[0m");         break;
        case ERROR_FILE_NOT_EXIST: fprintf(stderr, "\e[31;1mError: Input file not exist.\n\e[0m"); break;
        case ERROR_MISS_PARAMETER: fprintf(stderr, "\e[31;1mError: Miss redirect file.\n\e[0m");  break;
        case ERROR_PIPE:          fprintf(stderr, "\e[31;1mError: Open pipe error.\n\e[0m");      break;
        case ERROR_PIPE_MISS_PARAMETER: fprintf(stderr, "\e[31;1mError: Miss pipe parameter.\n\e[0m"); break;
        }
        printf("\n");
    }
    return 0;
}
