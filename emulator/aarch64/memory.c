#include "memory.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

Memory* memory_create(size_t size) {
    Memory* m = (Memory*)malloc(sizeof(Memory));
    if (!m) return NULL;
    m->data = (uint8_t*)calloc(1, size);
    if (!m->data) { free(m); return NULL; }
    m->size = size;
    return m;
}

void memory_destroy(Memory* m) {
    if (!m) return;
    free(m->data);
    free(m);
}

uint8_t memory_load8(const Memory* m, uint64_t addr) {
    return m->data[addr];
}

uint16_t memory_load16(const Memory* m, uint64_t addr) {
    uint16_t v;
    memcpy(&v, &m->data[addr], sizeof(v));
    return v;
}

uint32_t memory_load32(const Memory* m, uint64_t addr) {
    uint32_t v;
    memcpy(&v, &m->data[addr], sizeof(v));
    return v;
}

void memory_store8(Memory* m, uint64_t addr, uint8_t v) {
    m->data[addr] = v;
}

void memory_store16(Memory* m, uint64_t addr, uint16_t v) {
    memcpy(&m->data[addr], &v, sizeof(v));
}

void memory_store32(Memory* m, uint64_t addr, uint32_t v) {
    memcpy(&m->data[addr], &v, sizeof(v));
}

size_t memory_load_file(Memory* m, uint64_t addr, const char* path) {
    FILE* f = fopen(path, "rb");
    if (!f) return 0;
    fseek(f, 0, SEEK_END);
    long sz = ftell(f);
    if (sz < 0) { fclose(f); return 0; }
    if ((uint64_t)sz + addr > m->size) { fclose(f); return 0; }
    fseek(f, 0, SEEK_SET);
    size_t read = fread(&m->data[addr], 1, (size_t)sz, f);
    fclose(f);
    return read;
}

const uint8_t* memory_data(const Memory* m) { return m->data; }
