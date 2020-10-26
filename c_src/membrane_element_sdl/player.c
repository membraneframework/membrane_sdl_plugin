#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <sys/mman.h>
#include <unistd.h>

#include "player.h"

UNIFEX_TERM create(UnifexEnv *env, int width, int height) {
  char error[2048] = {0};
  State *state = unifex_alloc_state(env);
  state->window = NULL;
  state->renderer = NULL;
  state->texture = NULL;
  state->sdl_initialized = 0;
  state->width = width;
  state->height = height;

  if (SDL_Init(SDL_INIT_VIDEO) < 0) {
    snprintf(error, 2048, "Error initializing SDL");
    goto exit_create;
  }

  state->sdl_initialized = 1;

  state->window = SDL_CreateWindow("Membrane", SDL_WINDOWPOS_UNDEFINED,
                                   SDL_WINDOWPOS_UNDEFINED, width, height,
                                   SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE);

  if (!state->window) {
    snprintf(error, 2048, "Error creating window: %s", SDL_GetError());
    goto exit_create;
  }

  state->renderer = SDL_CreateRenderer(state->window, -1, 0);
  if (!state->renderer) {
    snprintf(error, 2048, "Error creating renderer: %s", SDL_GetError());
    goto exit_create;
  }

  state->texture =
      SDL_CreateTexture(state->renderer, SDL_PIXELFORMAT_IYUV,
                        SDL_TEXTUREACCESS_STREAMING, width, height);
  if (!state->texture) {
    snprintf(error, 2048, "Error creating texture: %s", SDL_GetError());
    goto exit_create;
  }

  UNIFEX_TERM result = create_result_ok(env, state);
  unifex_release_state(env, state);
  return result;

exit_create:
  unifex_release_state(env, state);
  return unifex_raise(env, error);
}

UNIFEX_TERM display_frame(UnifexEnv *env, UnifexPayload *payload,
                          State *state) {

  SDL_UpdateTexture(state->texture, NULL, payload->data, state->width);
  SDL_RenderClear(state->renderer);
  SDL_RenderCopy(state->renderer, state->texture, NULL, NULL);
  SDL_RenderPresent(state->renderer);

  return display_frame_result_ok(env);
}

void handle_destroy_state(UnifexEnv *env, State *state) {
  UNIFEX_UNUSED(env);

  if (state->texture) {
    SDL_DestroyTexture(state->texture);
  }
  if (state->renderer) {
    SDL_DestroyRenderer(state->renderer);
  }
  if (state->window) {
    SDL_DestroyWindow(state->window);
  }
  if (state->sdl_initialized) {
    SDL_Quit();
  }
}

void event_loop() {
  SDL_Event event;
  SDL_PollEvent(&event);
}

int main_function(int argc, char **argv) {
  UnifexEnv env;
  if (unifex_cnode_init(argc, argv, &env)) {
    return 1;
  }

  while (!unifex_cnode_receive(&env)) {
    event_loop();
  }

  unifex_cnode_destroy(&env);
  return 0;
}