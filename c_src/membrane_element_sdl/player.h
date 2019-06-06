#pragma once

#include <SDL.h>
#include <shmex/lib_cnode.h>

typedef struct State {
  SDL_Window *window;
  SDL_Renderer *renderer;
  SDL_Texture *texture;
  int width;
  int height;
} State;

int create(int width, int height, State *state);
int display_frame(Shmex *payload, State *state);
int destroy(State *state);
void event_loop();
