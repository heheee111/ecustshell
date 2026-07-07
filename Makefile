# ecustshell Makefile
# OS Course Design — Shell Project
#
# Current approach: shell.c includes all sub-module .c files
# (textual inclusion — simple but not idiomatic C)
#
# Future improvement: compile each .c to .o, then link
# Listed below as "proper" target for reference.

CC      = gcc
CFLAGS  = -Wall -Wextra -O2
TARGET  = ecustshell

# --- Simple build (current architecture) ---
# Since shell.h #includes all .c files, only shell.c needs compiling.
$(TARGET): shell.c shell.h cd.c cp.c ls.c mv.c ps.c rm.c time_cmd.c tree.c wc.c
	$(CC) $(CFLAGS) -o $(TARGET) shell.c

# --- Proper multi-file build (future) ---
# To use this: first remove the #include "*.c" lines from shell.h,
# then add function declarations to shell.h for each module.
OBJS = shell.o cd.o cp.o ls.o mv.o ps.o rm.o time_cmd.o tree.o wc.o

proper: $(OBJS)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJS)

%.o: %.c shell.h
	$(CC) $(CFLAGS) -c $< -o $@

# --- Utilities ---
.PHONY: clean run help

clean:
	rm -f $(TARGET) *.o

run: $(TARGET)
	./$(TARGET)

help:
	@echo "make          - build ecustshell (simple, include-based)"
	@echo "make proper   - build with separate compilation (needs header refactor)"
	@echo "make run      - build and run"
	@echo "make clean    - remove binary and object files"
