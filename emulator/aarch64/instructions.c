#include "instructions.h"

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

static inline uint64_t sign_extend(uint64_t value, unsigned bits) {
    const uint64_t sign_bit = (uint64_t)1 << (bits - 1);
    const uint64_t mask = (~0ULL) << bits;
    if (value & sign_bit) {
        value |= mask;
    }
    return value;
}

static inline uint64_t reg_read_u64(const AArch64CpuState* state, unsigned reg, int is64) {
    if (reg == 31) {
        return state->sp;
    }
    if (!is64) {
        return state->regs[reg] & 0xFFFFFFFFu;
    }
    return state->regs[reg];
}

static inline void reg_write_u64(AArch64CpuState* state, unsigned reg, uint64_t value, int is64) {
    if (reg == 31) {
        state->sp = value;
        return;
    }
    if (!is64) {
        state->regs[reg] = value & 0xFFFFFFFFu;
    } else {
        state->regs[reg] = value;
    }
}

static inline void set_nz_flags(AArch64CpuState* state, uint64_t value) {
    state->nzcv = 0;
    if (value == 0) {
        state->nzcv |= 0x40000000u;
    } else if (value & (1ULL << 63)) {
        state->nzcv |= 0x80000000u;
    }
}

static inline bool branch_condition_satisfied(uint32_t instr, const AArch64CpuState* state) {
    uint32_t cond = instr & 0xF;
    switch (cond) {
        case 0x0: return (state->nzcv & 0x40000000u) != 0; /* EQ */
        case 0x1: return (state->nzcv & 0x40000000u) == 0; /* NE */
        case 0xA: return (state->nzcv & 0x80000000u) == 0; /* GE */
        case 0xB: return (state->nzcv & 0x80000000u) != 0; /* LT */
        case 0xC: return ((state->nzcv & 0x40000000u) == 0) && ((state->nzcv & 0x80000000u) == 0); /* GT */
        case 0xD: return ((state->nzcv & 0x40000000u) != 0) || ((state->nzcv & 0x80000000u) != 0); /* LE */
        default: return false;
    }
}

static inline void handle_load_store_pair(uint32_t instr, AArch64CpuState* state, uint64_t pc) {
    const uint32_t rt = instr & 0x1F;
    const uint32_t rn = (instr >> 5) & 0x1F;
    const uint32_t imm7 = (instr >> 15) & 0x7F;
    const uint64_t base = reg_read_u64(state, rn, 1);
    const uint64_t addr = base + (imm7 << 3);
    const bool is_store = (instr & 0xFFC00000u) == 0xA9000000u;
    const bool is_pair = (instr & 0xFFC00000u) == 0xA9000000u || (instr & 0xFFC00000u) == 0xA9800000u;
    (void)is_pair;
    if (is_store) {
        uint64_t value = reg_read_u64(state, rt, 1);
        uint64_t* mem = (uint64_t*)(uintptr_t)addr;
        *mem = value;
    } else {
        uint64_t* mem = (uint64_t*)(uintptr_t)addr;
        reg_write_u64(state, rt, *mem, 1);
    }
    state->pc = pc + 4;
}

static inline uint64_t decode_adr_offset(uint32_t instr, uint64_t pc, int is_adrp) {
    const uint32_t immhi = (instr >> 5) & 0x7FFFFu;
    const uint32_t immlo = (instr >> 30) & 0x3u;
    const uint64_t imm = ((uint64_t)immhi << 2) | immlo;
    const int64_t offset = sign_extend(imm, 21);
    if (is_adrp) {
        return (pc & ~0xFFFULL) + ((uint64_t)offset << 12);
    }
    return pc + (uint64_t)offset;
}

void aarch64_execute_instruction(uint32_t instr, AArch64CpuState* state) {
    const uint64_t pc = state->pc;

    if ((instr & 0x9F000000u) == 0x10000000u) {
        const uint32_t rd = instr & 0x1F;
        reg_write_u64(state, rd, decode_adr_offset(instr, pc, 0), 1);
        state->pc = pc + 4;
        return;
    }

    if ((instr & 0x9F000000u) == 0x90000000u) {
        const uint32_t rd = instr & 0x1F;
        reg_write_u64(state, rd, decode_adr_offset(instr, pc, 1), 1);
        state->pc = pc + 4;
        return;
    }

    if ((instr & 0xFFC00000u) == 0x52800000u) {
        const uint32_t rd = instr & 0x1F;
        const uint32_t imm16 = (instr >> 5) & 0xFFFFu;
        const uint32_t hw = (instr >> 21) & 0x3u;
        reg_write_u64(state, rd, ((uint64_t)imm16) << (hw * 16), 1);
        state->pc = pc + 4;
        return;
    }

    if ((instr & 0xFFC00000u) == 0x52800000u) {
        const uint32_t rd = instr & 0x1F;
        const uint32_t imm16 = (instr >> 5) & 0xFFFFu;
        const uint32_t hw = (instr >> 21) & 0x3u;
        reg_write_u64(state, rd, ((uint64_t)imm16) << (hw * 16), 1);
        state->pc = pc + 4;
        return;
    }

    if ((instr & 0x7F800000u) == 0x72800000u) {
        const uint32_t rd = instr & 0x1F;
        const uint32_t imm16 = (instr >> 5) & 0xFFFFu;
        const uint32_t hw = (instr >> 21) & 0x3u;
        const uint64_t mask = 0xFFFFULL << (hw * 16);
        const uint64_t value = reg_read_u64(state, rd, 1);
        reg_write_u64(state, rd, (value & ~mask) | (((uint64_t)imm16) << (hw * 16)), 1);
        state->pc = pc + 4;
        return;
    }

    if ((instr & 0xFFC00000u) == 0x12000000u) {
        const uint32_t rd = instr & 0x1F;
        const uint32_t rn = (instr >> 5) & 0x1F;
        const uint32_t imm12 = (instr >> 10) & 0xFFFu;
        const uint64_t value = reg_read_u64(state, rn, 1) & imm12;
        reg_write_u64(state, rd, value, 1);
        state->pc = pc + 4;
        return;
    }

    if ((instr & 0xFFC00000u) == 0x32000000u) {
        const uint32_t rd = instr & 0x1F;
        const uint32_t rn = (instr >> 5) & 0x1F;
        const uint32_t imm12 = (instr >> 10) & 0xFFFu;
        const uint64_t value = reg_read_u64(state, rn, 1) | imm12;
        reg_write_u64(state, rd, value, 1);
        state->pc = pc + 4;
        return;
    }

    if ((instr & 0xFFC00000u) == 0x52000000u) {
        const uint32_t rd = instr & 0x1F;
        const uint32_t rn = (instr >> 5) & 0x1F;
        const uint32_t imm12 = (instr >> 10) & 0xFFFu;
        const uint64_t value = reg_read_u64(state, rn, 1) ^ imm12;
        reg_write_u64(state, rd, value, 1);
        state->pc = pc + 4;
        return;
    }

    if ((instr & 0xFFC00000u) == 0xAA000000u) {
        const uint32_t rd = instr & 0x1F;
        const uint32_t rn = (instr >> 5) & 0x1F;
        const uint32_t rm = (instr >> 16) & 0x1F;
        const uint64_t value = reg_read_u64(state, rn, 1) | reg_read_u64(state, rm, 1);
        reg_write_u64(state, rd, value, 1);
        state->pc = pc + 4;
        return;
    }

    if ((instr & 0xFFC00000u) == 0x11000000u || (instr & 0xFFC00000u) == 0x91000000u) {
        const uint32_t rd = instr & 0x1F;
        const uint32_t rn = (instr >> 5) & 0x1F;
        const uint32_t imm12 = (instr >> 10) & 0xFFFu;
        const uint32_t shift = (instr >> 22) & 0x3u;
        const uint64_t value = reg_read_u64(state, rn, 1);
        const uint64_t imm = (uint64_t)imm12 << (shift * 12);
        reg_write_u64(state, rd, value + imm, 1);
        state->pc = pc + 4;
        return;
    }

    if ((instr & 0xFFC00000u) == 0xD1000000u || (instr & 0xFFC00000u) == 0xCB000000u) {
        const uint32_t rd = instr & 0x1F;
        const uint32_t rn = (instr >> 5) & 0x1F;
        const uint32_t imm12 = (instr >> 10) & 0xFFFu;
        const uint32_t shift = (instr >> 22) & 0x3u;
        const uint64_t value = reg_read_u64(state, rn, 1);
        const uint64_t imm = (uint64_t)imm12 << (shift * 12);
        const uint64_t result = value - imm;
        reg_write_u64(state, rd, result, 1);
        set_nz_flags(state, result);
        state->pc = pc + 4;
        return;
    }

    if ((instr & 0xFFC00000u) == 0xF1000000u) {
        const uint32_t rd = instr & 0x1F;
        const uint32_t rn = (instr >> 5) & 0x1F;
        const uint32_t imm12 = (instr >> 10) & 0xFFFu;
        const uint32_t shift = (instr >> 22) & 0x3u;
        const uint64_t lhs = reg_read_u64(state, rn, 1);
        const uint64_t imm = (uint64_t)imm12 << (shift * 12);
        const uint64_t result = lhs - imm;
        reg_write_u64(state, rd, result, 1);
        set_nz_flags(state, result);
        state->pc = pc + 4;
        return;
    }

    if ((instr & 0x7F000000u) == 0x35000000u || (instr & 0x7F000000u) == 0x37000000u) {
        const uint32_t rt = instr & 0x1F;
        const uint32_t imm19 = (instr >> 5) & 0x7FFFFu;
        int64_t offset = (int64_t)imm19 << 2;
        if (offset & (1LL << 20)) {
            offset |= ~((1LL << 21) - 1);
        }
        const uint64_t value = reg_read_u64(state, rt, 1);
        const bool take = ((instr & 0x7F000000u) == 0x35000000u) ? (value == 0) : (value != 0);
        state->pc = take ? (uint64_t)((int64_t)pc + offset) : pc + 4;
        return;
    }

    if ((instr & 0xFF000010u) == 0x54000000u) {
        const uint32_t imm19 = (instr >> 5) & 0x7FFFFu;
        int64_t offset = (int64_t)imm19 << 2;
        if (offset & (1LL << 20)) {
            offset |= ~((1LL << 21) - 1);
        }
        if (branch_condition_satisfied(instr, state)) {
            state->pc = (uint64_t)((int64_t)pc + offset);
        } else {
            state->pc = pc + 4;
        }
        return;
    }

    if ((instr & 0x7F000000u) == 0x14000000u) {
        const uint32_t imm26 = instr & 0x03FFFFFFu;
        int64_t offset = (int64_t)imm26 << 2;
        if (offset & (1LL << 27)) {
            offset |= ~((1LL << 28) - 1);
        }
        state->pc = (uint64_t)((int64_t)pc + offset);
        return;
    }

    if ((instr & 0xFC000000u) == 0x94000000u) {
        const uint32_t imm26 = instr & 0x03FFFFFFu;
        int64_t offset = (int64_t)imm26 << 2;
        if (offset & (1LL << 27)) {
            offset |= ~((1LL << 28) - 1);
        }
        reg_write_u64(state, 30, pc + 4, 1);
        state->pc = (uint64_t)((int64_t)pc + offset);
        return;
    }

    if ((instr & 0xFFFFFFF0u) == 0xD65F03C0u) {
        state->pc = reg_read_u64(state, 30, 1);
        return;
    }

    if ((instr & 0xFFF8FFC0u) == 0xD5300000u) {
        const uint32_t rd = (instr >> 10) & 0x1F;
        reg_write_u64(state, rd, 0, 1);
        state->pc = pc + 4;
        return;
    }

    if ((instr & 0xFFF8FFC0u) == 0xD5000000u) {
        state->pc = pc + 4;
        return;
    }

    if (instr == 0xD503201Fu || instr == 0xD503203Fu || instr == 0xD503205Fu ||
        instr == 0xD503207Fu || instr == 0xD50330BFu || instr == 0xD5033F9Fu ||
        instr == 0xD5033FDFu) {
        state->pc = pc + 4;
        return;
    }

    if ((instr & 0xFFC00000u) == 0xD1000000u || (instr & 0xFFC00000u) == 0xF1000000u) {
        const uint32_t rd = instr & 0x1F;
        const uint32_t rn = (instr >> 5) & 0x1F;
        const uint32_t imm12 = (instr >> 10) & 0xFFFu;
        const uint32_t shift = (instr >> 22) & 0x3u;
        const uint64_t lhs = reg_read_u64(state, rn, 1);
        const uint64_t imm = (uint64_t)imm12 << (shift * 12);
        const uint64_t result = lhs - imm;
        reg_write_u64(state, rd, result, 1);
        set_nz_flags(state, result);
        state->pc = pc + 4;
        return;
    }

    if ((instr & 0xFFE00000u) == 0x6B000000u) {
        const uint32_t rn = (instr >> 5) & 0x1F;
        const uint32_t rm = (instr >> 16) & 0x1F;
        const uint64_t lhs = reg_read_u64(state, rn, 1);
        const uint64_t rhs = reg_read_u64(state, rm, 1);
        set_nz_flags(state, lhs - rhs);
        state->pc = pc + 4;
        return;
    }

    if ((instr & 0xFFC00000u) == 0x9B000000u) {
        const uint32_t rd = instr & 0x1F;
        const uint32_t rn = (instr >> 5) & 0x1F;
        const uint32_t rm = (instr >> 16) & 0x1F;
        const uint64_t value = reg_read_u64(state, rn, 1) * reg_read_u64(state, rm, 1);
        reg_write_u64(state, rd, value, 1);
        state->pc = pc + 4;
        return;
    }

    if ((instr & 0xFFC00000u) == 0x72000000u) {
        const uint32_t rn = (instr >> 5) & 0x1F;
        const uint32_t imm12 = (instr >> 10) & 0xFFFu;
        set_nz_flags(state, reg_read_u64(state, rn, 1) & imm12);
        state->pc = pc + 4;
        return;
    }

    if ((instr & 0xFFC00000u) == 0x1AC00000u) {
        const uint32_t rd = instr & 0x1F;
        const uint32_t rn = (instr >> 5) & 0x1F;
        const uint32_t lsb = (instr >> 10) & 0x3F;
        const uint32_t width = (instr >> 16) & 0x3F;
        uint64_t value = reg_read_u64(state, rn, 1);
        value = (value >> lsb) & ((1ULL << width) - 1);
        reg_write_u64(state, rd, value, 1);
        state->pc = pc + 4;
        return;
    }

    if ((instr & 0xFFC00000u) == 0x39400000u || (instr & 0xFFC00000u) == 0x39000000u) {
        const uint32_t rt = instr & 0x1F;
        const uint32_t rn = (instr >> 5) & 0x1F;
        const uint32_t imm12 = (instr >> 10) & 0xFFFu;
        const uint64_t base = reg_read_u64(state, rn, 1);
        const uint64_t addr = base + imm12;
        const int store = (instr & 0xFFC00000u) == 0x39000000u;
        uint8_t* mem = (uint8_t*)(uintptr_t)addr;
        if (store) {
            *mem = (uint8_t)reg_read_u64(state, rt, 0);
        } else {
            reg_write_u64(state, rt, *mem, 0);
        }
        state->pc = pc + 4;
        return;
    }

    if ((instr & 0xFFC00000u) == 0xB9400000u || (instr & 0xFFC00000u) == 0xF9400000u ||
        (instr & 0xFFC00000u) == 0xB9000000u || (instr & 0xFFC00000u) == 0xF9000000u) {
        const uint32_t rt = instr & 0x1F;
        const uint32_t rn = (instr >> 5) & 0x1F;
        const uint32_t imm12 = (instr >> 10) & 0xFFFu;
        const uint64_t base = reg_read_u64(state, rn, 1);
        const uint64_t addr = base + imm12;
        const int store = (instr & 0xFFC00000u) == 0xB9000000u || (instr & 0xFFC00000u) == 0xF9000000u;
        const int word = (instr & 0xFFC00000u) == 0xB9000000u || (instr & 0xFFC00000u) == 0xB9400000u;
        if (store) {
            const uint64_t value = reg_read_u64(state, rt, 1);
            if (word) {
                uint32_t* mem = (uint32_t*)(uintptr_t)addr;
                *mem = (uint32_t)value;
            } else {
                uint64_t* mem = (uint64_t*)(uintptr_t)addr;
                *mem = value;
            }
        } else {
            if (word) {
                uint32_t* mem = (uint32_t*)(uintptr_t)addr;
                reg_write_u64(state, rt, *mem, 0);
            } else {
                uint64_t* mem = (uint64_t*)(uintptr_t)addr;
                reg_write_u64(state, rt, *mem, 1);
            }
        }
        state->pc = pc + 4;
        return;
    }

    if ((instr & 0xFFC00000u) == 0xA9000000u || (instr & 0xFFC00000u) == 0xA9800000u) {
        handle_load_store_pair(instr, state, pc);
        return;
    }

    if ((instr & 0xFFC00000u) == 0xF8400000u || (instr & 0xFFC00000u) == 0xF8200000u ||
        (instr & 0xFFC00000u) == 0xB8600000u || (instr & 0xFFC00000u) == 0xB8200000u) {
        const uint32_t rt = instr & 0x1F;
        const uint32_t rn = (instr >> 5) & 0x1F;
        const uint32_t rm = (instr >> 16) & 0x1F;
        const uint64_t base = reg_read_u64(state, rn, 1);
        const uint64_t index = reg_read_u64(state, rm, 1);
        const uint64_t addr = base + (index << 2);
        const int store = (instr & 0xFFC00000u) == 0xB8200000u || (instr & 0xFFC00000u) == 0xF8200000u;
        const int word = (instr & 0xFFC00000u) == 0xB8600000u || (instr & 0xFFC00000u) == 0xB8200000u;
        if (store) {
            const uint64_t value = reg_read_u64(state, rt, 1);
            if (word) {
                uint32_t* mem = (uint32_t*)(uintptr_t)addr;
                *mem = (uint32_t)value;
            } else {
                uint64_t* mem = (uint64_t*)(uintptr_t)addr;
                *mem = value;
            }
        } else {
            if (word) {
                uint32_t* mem = (uint32_t*)(uintptr_t)addr;
                reg_write_u64(state, rt, *mem, 0);
            } else {
                uint64_t* mem = (uint64_t*)(uintptr_t)addr;
                reg_write_u64(state, rt, *mem, 1);
            }
        }
        state->pc = pc + 4;
        return;
    }

    if ((instr & 0xFFF80000u) == 0xD503201F) {
        state->pc = pc + 4;
        return;
    }

    if ((instr & 0xFFF80000u) == 0xD5033000u) {
        state->pc = pc + 4;
        return;
    }

    if ((instr & 0xFFF80000u) == 0xD503301F) {
        state->pc = pc + 4;
        return;
    }

    if ((instr & 0xFFF80000u) == 0xD50330BFu) {
        state->pc = pc + 4;
        return;
    }

    if ((instr & 0xFFE0FFFFu) == 0xD503201Fu) {
        state->pc = pc + 4;
        return;
    }

    if ((instr & 0xFFE0FFFFu) == 0xD5033000u) {
        state->pc = pc + 4;
        return;
    }

    if (((instr & 0xFFC00000u) == 0xA9000000u) || ((instr & 0xFFC00000u) == 0xA8000000u)) {
        state->pc = pc + 4;
        return;
    }

    fprintf(stderr, "Unsupported AArch64 instruction 0x%08x at PC 0x%016llx\n",
            instr, (unsigned long long)pc);

    state->pc = pc + 4;
}

void aarch64_set_register(AArch64CpuState* state, unsigned reg, uint64_t value) {
    reg_write_u64(state, reg, value, 1);
}

uint64_t aarch64_get_register(const AArch64CpuState* state, unsigned reg) {
    return reg_read_u64(state, reg, 1);
}
