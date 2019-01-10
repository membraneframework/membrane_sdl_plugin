#pragma once

#include "SDL.h"

typedef struct State {
  SDL_Window* window;
  SDL_Renderer* renderer;
  SDL_Texture* texture;
  int width;
  int height;
} State;

typedef State UnifexNifState;

#include "_generated/sink.h"
