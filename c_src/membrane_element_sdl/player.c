#include <bunch/bunch.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <sys/mman.h>
#include <unistd.h>

#include "player.h"

int create(int width, int height, State *state) {
  SDL_Window *window = NULL;
  SDL_Renderer *renderer = NULL;
  SDL_Texture *texture = NULL;

  if (SDL_Init(SDL_INIT_VIDEO) < 0) {
    fprintf(stderr, "Error initializing SDL\r\n");
    goto exit_create;
  }

  window = SDL_CreateWindow("Membrane", SDL_WINDOWPOS_UNDEFINED,
                            SDL_WINDOWPOS_UNDEFINED, width, height,
                            SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE);

  if (!window) {
    fprintf(stderr, "Error creating window: %s\r\n", SDL_GetError());
    goto exit_create;
  }

  renderer = SDL_CreateRenderer(window, -1, 0);
  if (!renderer) {
    fprintf(stderr, "Error creating renderer: %s\r\n", SDL_GetError());
    goto exit_create;
  }

  texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_IYUV,
                              SDL_TEXTUREACCESS_STREAMING, width, height);
  if (!texture) {
    fprintf(stderr, "Error creating texture: %s\r\n", SDL_GetError());
    goto exit_create;
  }

  state->window = window;
  state->renderer = renderer;
  state->texture = texture;
  state->width = width;
  state->height = height;

  return 0;

exit_create:
  if (renderer) {
    SDL_DestroyRenderer(renderer);
  }
  if (window) {
    SDL_Quit();
  }
  return 1;
}

int display_frame(Shmex *payload, State *state) {
  int res = 0;
  ShmexLibResult shmex_res = SHMEX_RES_OK;
  shmex_res = shmex_open_and_mmap(payload);
  if (SHMEX_RES_OK != shmex_res) {
    fprintf(stderr, "shmex_open_and_mmap error: %s, errno: %s\r\n",
            shmex_lib_result_to_string(shmex_res), bunch_errno_string());
    res = 1;
    goto display_frame_exit;
  }

  SDL_UpdateTexture(state->texture, NULL, payload->mapped_memory, state->width);
  SDL_RenderClear(state->renderer);
  SDL_RenderCopy(state->renderer, state->texture, NULL, NULL);
  SDL_RenderPresent(state->renderer);

  shmex_res = shmex_unlink(payload);
  if (SHMEX_RES_OK != shmex_res) {
    fprintf(stderr, "shmex_unlink error: %s, errno: %s\r\n",
            shmex_lib_result_to_string(shmex_res), bunch_errno_string());
    res = 1;
    goto display_frame_exit;
  }

display_frame_exit:
  shmex_release(payload);
  return res;
}

int destroy(State *state) {
  SDL_DestroyRenderer(state->renderer);
  SDL_Quit();
  return 0;
}

void event_loop() {
  SDL_Event event;
  SDL_PollEvent(&event);
}
