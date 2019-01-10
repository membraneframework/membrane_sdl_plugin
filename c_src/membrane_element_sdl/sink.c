#include <stdio.h>
#include <membrane/log.h>
#include "sink.h"

UNIFEX_TERM create(UnifexEnv* env, int width, int height) {
  char* err_reason = NULL;
  SDL_Window* window = NULL;
  SDL_Renderer* renderer = NULL;
  SDL_Texture* texture = NULL;

  if (SDL_Init(SDL_INIT_VIDEO) < 0) {
      MEMBRANE_WARN(env, "Error initializing SDL: %s", SDL_GetError());
      err_reason = "init_sdl";
      goto exit_create;
  }

  window = SDL_CreateWindow("Membrane",
                            SDL_WINDOWPOS_UNDEFINED,
                            SDL_WINDOWPOS_UNDEFINED,
                            width, height,
                            SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE);

  if (!window) {
    MEMBRANE_WARN(env, "Error creating window: %s", SDL_GetError());
    err_reason = "create_window";
    goto exit_create;
  }

  renderer = SDL_CreateRenderer(window, -1, 0);
  if (!renderer) {
    MEMBRANE_WARN(env, "Error creating renderer: %s", SDL_GetError());
    err_reason = "create_renderer";
    goto exit_create;
  }

  texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_YV12, SDL_TEXTUREACCESS_STREAMING, width, height);
  if (!texture) {
    MEMBRANE_WARN(env, "Error creating texture: %s", SDL_GetError());
    err_reason = "create_texture";
    goto exit_create;
  }

  State* state = unifex_alloc_state(env);
  state->window = window;
  state->renderer = renderer;
  state->texture = texture;
  state->width = width;
  state->height = height;

  UNIFEX_TERM res = create_result_ok(env, state);
  unifex_release_state(env, state);
  return res;

exit_create:
  if(renderer) {
    SDL_DestroyRenderer(renderer);
  }
  if(window) {
    SDL_Quit();
  }
  return create_result_error(env, err_reason);
}

UNIFEX_TERM display_frame(UnifexEnv* env, UnifexPayload* payload, State* state) {
  SDL_UpdateTexture(state->texture, NULL, payload->data, state->width);
  SDL_RenderClear(state->renderer);
  SDL_RenderCopy(state->renderer, state->texture, NULL, NULL);
  SDL_RenderPresent(state->renderer);

  return display_frame_result_ok(env);
}

UNIFEX_TERM destroy(UnifexEnv* env, State* state) {
  handle_destroy_state(env, state);
  return destroy_result_ok(env);
}

void handle_destroy_state(UnifexEnv* env, State* state) {
  UNIFEX_UNUSED(env);

  SDL_DestroyRenderer(state->renderer);
  SDL_Quit();
}
