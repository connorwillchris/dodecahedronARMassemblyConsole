#include "cpu.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

Cpu* cpu_create(CpuState* state, Memory* memory) {
    Cpu* c = (Cpu*)malloc(sizeof(Cpu));
    if (!c) return NULL;
    c->state = state;
    c->memory = memory;

    return c;
}

void cpu_reset(Cpu* cpu, uint64_t startPc) {
    memset(cpu->state, 0, sizeof(CpuState));
    cpu->state->pc = startPc;
}

static uint32_t fetch32(Cpu* cpu) {
    return memory_load32(cpu->memory, cpu->state->pc);
}

void cpu_step(Cpu* cpu) {
    uint32_t instr = fetch32(cpu);
    if (instr == 0) return;

    aarch64_execute_instruction(instr, cpu->state);
}
