#pragma once
#include <stdint.h>
#include "memory.h"
#include "instructions.h"

typedef AArch64CpuState CpuState;

typedef struct Cpu {
    CpuState* state;
    Memory* memory;
} Cpu;

Cpu* cpu_create(CpuState* state, Memory* memory);
void cpu_reset(Cpu* cpu, uint64_t startPc);
void cpu_step(Cpu* cpu);
