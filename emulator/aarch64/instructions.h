#pragma once

#include <stdint.h>

/* Minimal AArch64 CPU state and instruction interface used by the emulator. */
typedef struct AArch64CpuState {
    uint64_t regs[31];
    uint64_t sp;
    uint64_t pc;
    uint32_t nzcv;
} AArch64CpuState;

void aarch64_execute_instruction(uint32_t instr, AArch64CpuState* state);

void aarch64_set_register(AArch64CpuState* state, unsigned reg, uint64_t value);

uint64_t aarch64_get_register(const AArch64CpuState* state, unsigned reg);
