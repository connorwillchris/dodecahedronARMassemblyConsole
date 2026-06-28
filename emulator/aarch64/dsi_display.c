#include <SDL2/SDL.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "dsi_display.h"

DSIDisplay* display_create(void) {
    DSIDisplay* d = (DSIDisplay*)malloc(sizeof(DSIDisplay));
    if (!d) return NULL;
    d->window = NULL; d->renderer = NULL; d->texture = NULL;
    d->width = 800; d->height = 480;
    d->pixels = (uint32_t*)malloc(d->width * d->height * sizeof(uint32_t));
    return d;
}

int display_init(DSIDisplay* d) {
    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        fprintf(stderr, "SDL_Init error: %s\n", SDL_GetError());
        return 0;
    }
    SDL_Window* w = SDL_CreateWindow("AArch64 DSI Emulator",
                                     SDL_WINDOWPOS_CENTERED,
                                     SDL_WINDOWPOS_CENTERED,
                                     d->width, d->height, 0);
    if (!w) { fprintf(stderr, "SDL_CreateWindow error: %s\n", SDL_GetError()); return 0; }
    SDL_Renderer* r = SDL_CreateRenderer(w, -1, SDL_RENDERER_ACCELERATED);
    if (!r) { SDL_DestroyWindow(w); fprintf(stderr, "SDL_CreateRenderer error: %s\n", SDL_GetError()); return 0; }
    SDL_Texture* t = SDL_CreateTexture(r, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, d->width, d->height);
    if (!t) { SDL_DestroyRenderer(r); SDL_DestroyWindow(w); fprintf(stderr, "SDL_CreateTexture error: %s\n", SDL_GetError()); return 0; }
    d->window = w; d->renderer = r; d->texture = t;
    return 1;
}

int display_process_events(DSIDisplay* d) {
    SDL_Event ev;
    while (SDL_PollEvent(&ev)) {
        if (ev.type == SDL_QUIT) return 0;
    }
    return 1;
}

void display_draw_test_pattern(DSIDisplay* d, uint32_t frame) {
    for (uint32_t y = 0; y < d->height; ++y) {
        for (uint32_t x = 0; x < d->width; ++x) {
            uint8_t r = (x + frame) & 0xFF;
            uint8_t g = (y + frame) & 0xFF;
            uint8_t b = (x + y + frame) & 0xFF;
            d->pixels[y * d->width + x] = (0xFFu << 24) | (r << 16) | (g << 8) | b;
        }
    }
}

void display_draw_from_memory(DSIDisplay* d, const uint8_t* src, size_t srcSize) {
    size_t pixelCount = (size_t)d->width * d->height;
    size_t argbSize = pixelCount * 4;
    size_t rgbSize = pixelCount * 3;
    size_t graySize = pixelCount;
    if (srcSize >= argbSize) {
        memcpy(d->pixels, src, argbSize);
        return;
    }
    if (srcSize >= rgbSize) {
        for (size_t i = 0; i < pixelCount; ++i) {
            size_t idx = i * 3;
            uint8_t r = src[idx]; uint8_t g = src[idx+1]; uint8_t b = src[idx+2];
            d->pixels[i] = (0xFFu << 24) | (r << 16) | (g << 8) | b;
        }
        return;
    }
    if (srcSize >= graySize) {
        for (size_t i = 0; i < pixelCount; ++i) {
            uint8_t g = src[i];
            d->pixels[i] = (0xFFu << 24) | (g << 16) | (g << 8) | g;
        }
        return;
    }
    display_draw_test_pattern(d, 0);
}

void display_present(DSIDisplay* d) {
    SDL_UpdateTexture((SDL_Texture*)d->texture, NULL, d->pixels, d->width * sizeof(uint32_t));
    SDL_RenderClear((SDL_Renderer*)d->renderer);
    SDL_RenderCopy((SDL_Renderer*)d->renderer, (SDL_Texture*)d->texture, NULL, NULL);
    SDL_RenderPresent((SDL_Renderer*)d->renderer);
}

void display_shutdown(DSIDisplay* d) {
    if (d->texture) { SDL_DestroyTexture((SDL_Texture*)d->texture); d->texture = NULL; }
    if (d->renderer) { SDL_DestroyRenderer((SDL_Renderer*)d->renderer); d->renderer = NULL; }
    if (d->window) { SDL_DestroyWindow((SDL_Window*)d->window); d->window = NULL; }
    SDL_Quit();
}

void display_destroy(DSIDisplay* d) {
    if (!d) return;
    if (d->pixels) free(d->pixels);
    free(d);
}
