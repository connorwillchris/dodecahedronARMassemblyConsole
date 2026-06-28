#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <SDL2/SDL.h>

#include "aarch64/memory.h"
#include "aarch64/cpu.h"
#include "aarch64/dsi_display.h"

int main(int argc, char* argv[]) {
    DSIDisplay* display = display_create();
    if (!display) { fprintf(stderr, "Failed alloc display\n"); return 1; }
    if (!display_init(display)) { fprintf(stderr, "Failed init display\n"); display_destroy(display); return 1; }

    Memory* memory = memory_create(16 * 1024 * 1024);
    if (!memory) { fprintf(stderr, "Failed alloc memory\n"); display_shutdown(display); display_destroy(display); return 1; }

    uint64_t startPc = 0;
    size_t loadedSize = 0;
    const uint64_t kernelBase = 0x80000ULL;
    if (argc > 2 && strcmp(argv[1], "load") == 0) {
        loadedSize = memory_load_file(memory, kernelBase, argv[2]);
        if (loadedSize == 0) fprintf(stderr, "Failed to load %s\n", argv[2]);
        else { startPc = kernelBase; printf("Loaded %s (%zu bytes) at 0x%llx\n", argv[2], loadedSize, (unsigned long long)kernelBase); }
    }

    CpuState state;
    Cpu* cpu = cpu_create(&state, memory);
    cpu_reset(cpu, startPc);

    int running = 1;
    uint32_t frame = 0;
    while (running) {
        running = display_process_events(display);
        if (loadedSize > 0) display_draw_from_memory(display, memory_data(memory) + kernelBase, loadedSize);
        else display_draw_test_pattern(display, frame);
        display_present(display);

        cpu_step(cpu);
        frame++;
        SDL_Delay(16);
    }

    display_shutdown(display);
    display_destroy(display);
    memory_destroy(memory);
    free(cpu);
    return 0;
}
