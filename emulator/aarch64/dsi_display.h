#pragma once

#include <stdint.h>
#include <stddef.h>

typedef struct DSIDisplay {
    void* window;
    void* renderer;
    void* texture;
    uint32_t width;
    uint32_t height;
    uint32_t* pixels;
} DSIDisplay;

DSIDisplay* display_create(void);
int display_init(DSIDisplay* d);
int display_process_events(DSIDisplay* d);
void display_draw_test_pattern(DSIDisplay* d, uint32_t frame);
void display_draw_from_memory(DSIDisplay* d, const uint8_t* src, size_t srcSize);
void display_present(DSIDisplay* d);
void display_shutdown(DSIDisplay* d);
void display_destroy(DSIDisplay* d);
