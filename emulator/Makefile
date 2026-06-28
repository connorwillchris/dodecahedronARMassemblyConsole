CC = gcc
CFLAGS = -std=c11 -O2 -Wall -I.
LDFLAGS = -lSDL2

P = aarch64

SRCS = main.c $P/cpu.c $P/memory.c $P/dsi_display.c $P/instructions.c $P/cpu.c
OBJS = $(SRCS:.c=.o)

all: aarch64emu

aarch64emu: $(OBJS)
	$(CC) -o $@ $^ $(LDFLAGS)

clean:
	rm -f $(OBJS) aarch64emu
