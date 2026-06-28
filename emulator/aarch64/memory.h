#pragma once
#include <stdint.h>
#include <stddef.h>

typedef struct Memory {
    uint8_t* data;
    size_t size;
} Memory;

Memory* memory_create(size_t size);
void memory_destroy(Memory* m);
uint8_t memory_load8(const Memory* m, uint64_t addr);
uint16_t memory_load16(const Memory* m, uint64_t addr);
uint32_t memory_load32(const Memory* m, uint64_t addr);
void memory_store8(Memory* m, uint64_t addr, uint8_t v);
void memory_store16(Memory* m, uint64_t addr, uint16_t v);
void memory_store32(Memory* m, uint64_t addr, uint32_t v);
size_t memory_load_file(Memory* m, uint64_t addr, const char* path);
const uint8_t* memory_data(const Memory* m);
