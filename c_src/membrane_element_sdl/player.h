#pragma once

#include <SDL.h>

typedef struct State {
  SDL_Window *window;
  SDL_Renderer *renderer;
  SDL_Texture *texture;
  int sdl_initialized;
  int width;
  int height;
} State;

#include "_generated/player.h"