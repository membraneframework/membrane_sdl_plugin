#pragma once

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wall"
#pragma GCC diagnostic ignored "-Wextra" 
#include <SDL2/SDL.h>
#pragma GCC diagnostic pop

typedef struct State {
  SDL_Window *window;
  SDL_Renderer *renderer;
  SDL_Texture *texture;
  int sdl_initialized;
  int width;
  int height;
} State;

#include "_generated/player.h"
