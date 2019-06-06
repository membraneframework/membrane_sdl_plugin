#include <arpa/inet.h>
#include <netinet/in.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>
#ifndef _REENTRANT
#define _REENTRANT // For some reason __erl_errno is undefined unless _REENTRANT
                   // is defined
#endif
#include "player.h"
#include <ei.h>
#include <ei_connect.h>
#include <erl_interface.h>

#ifdef CNODE_DEBUG
#define DEBUG(X, ...) fprintf(stderr, X "\r\n", ##__VA_ARGS__)
#else
#define DEBUG(...)
#endif

int listen_sock(int *listen_fd, int *port) {
  int fd = socket(AF_INET, SOCK_STREAM, 0);
  if (fd < 0) {
    return 1;
  }

  int opt_on = 1;
  if (setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &opt_on, sizeof(opt_on))) {
    return 1;
  }

  struct sockaddr_in addr;
  unsigned int addr_size = sizeof(addr);
  addr.sin_family = AF_INET;
  addr.sin_port = htons(0);
  addr.sin_addr.s_addr = htonl(INADDR_ANY);

  if (bind(fd, (struct sockaddr *)&addr, addr_size) < 0) {
    return 1;
  }

  if (getsockname(fd, (struct sockaddr *)&addr, &addr_size)) {
    return 1;
  }
  *port = (int)ntohs(addr.sin_port);

  const int queue_size = 5;
  if (listen(fd, queue_size)) {
    return 1;
  }

  *listen_fd = fd;
  return 0;
}

int handle_message(int ei_fd, char *node_name, erlang_msg emsg,
                   ei_x_buff *in_buf, State *state) {
  ei_x_buff out_buf;
  ei_x_new_with_version(&out_buf);
  int decode_idx = 0;
  int version;
  char fun[255];
  int arity;

  if (ei_decode_version(in_buf->buff, &decode_idx, &version)) {
    goto handle_message_error;
  }
  ei_decode_tuple_header(in_buf->buff, &decode_idx, &arity);
  if (ei_decode_atom(in_buf->buff, &decode_idx, fun)) {
    goto handle_message_error;
  }

  int res = 1;
  if (!strcmp(fun, "create")) {
    long width, height;
    if (ei_decode_long(in_buf->buff, &decode_idx, &width) ||
        ei_decode_long(in_buf->buff, &decode_idx, &height)) {
      goto handle_message_error;
    }
    res = create((int)width, (int)height, state);
  }

  if (!strcmp(fun, "display_frame")) {
    Shmex payload;
    if (shmex_deserialize(in_buf->buff, &decode_idx, &payload)) {
      goto handle_message_error;
    }
    res = display_frame(&payload, state);
  }

  if (!strcmp(fun, "destroy")) {
    res = destroy(state);
  }

  if (ei_x_encode_tuple_header(&out_buf, 2) ||
      ei_x_encode_atom(&out_buf, node_name) ||
      ei_x_encode_atom(&out_buf, res ? "error" : "ok")) {
    goto handle_message_error;
  }

  ei_send(ei_fd, &emsg.from, out_buf.buff, out_buf.index);

  ei_x_free(&out_buf);
  return 0;

handle_message_error:
  ei_x_free(&out_buf);
  DEBUG("Message handling error");
  return 1;
}

int receive(int ei_fd, char *node_name, State *state) {
  ei_x_buff in_buf;
  ei_x_new(&in_buf);
  erlang_msg emsg;
  int res = 0;
  event_loop();
  switch (ei_xreceive_msg_tmo(ei_fd, &emsg, &in_buf, 100)) {
  case ERL_TICK:
    break;
  case ERL_ERROR:
    res = erl_errno != ETIMEDOUT;
    break;
  default:
    if (emsg.msgtype == ERL_REG_SEND &&
        handle_message(ei_fd, node_name, emsg, &in_buf, state)) {
      res = -1;
    }
    break;
  }

  ei_x_free(&in_buf);
  return res;
}

int validate_args(int argc, char **argv) {
  if (argc != 6) {
    return 1;
  }
  for (int i = 1; i < argc; i++) {
    if (strlen(argv[i]) > 255) {
      return 1;
    }
  }
  return 0;
}

int main(int argc, char **argv) {
  if (validate_args(argc, argv)) {
    fprintf(stderr,
            "%s <host_name> <alive_name> <node_name> <cookie> <creation>\r\n",
            argv[0]);
    return 1;
  }
  char host_name[256];
  strcpy(host_name, argv[1]);
  char alive_name[256];
  strcpy(alive_name, argv[2]);
  char node_name[256];
  strcpy(node_name, argv[3]);
  char cookie[256];
  strcpy(cookie, argv[4]);
  short creation = (short)atoi(argv[5]);

  int listen_fd;
  int port;
  if (listen_sock(&listen_fd, &port)) {
    DEBUG("listen error");
    return 1;
  }
  DEBUG("listening at %d", port);

  ei_cnode ec;
  struct in_addr addr;
  addr.s_addr = inet_addr("127.0.0.1");
  if (ei_connect_xinit(&ec, host_name, alive_name, node_name, &addr, cookie,
                       creation) < 0) {
    DEBUG("init error: %d", erl_errno);
    return 1;
  }
  DEBUG("initialized %s (%s)", ei_thisnodename(&ec), inet_ntoa(addr));

  if (ei_publish(&ec, port) == -1) {
    DEBUG("publish error: %d", erl_errno);
    return 1;
  }
  DEBUG("published");
  printf("ready\r\n");
  fflush(stdout);

  ErlConnect conn;
  int ei_fd = ei_accept_tmo(&ec, listen_fd, &conn, 5000);
  if (ei_fd == ERL_ERROR) {
    DEBUG("accept error: %d", erl_errno);
    return 1;
  }
  DEBUG("accepted %s", conn.nodename);

  State state;

  int res = 0;
  int cont = 1;
  while (cont) {
    switch (receive(ei_fd, node_name, &state)) {
    case 0:
      break;
    case 1:
      DEBUG("disconnected");
      cont = 0;
      break;
    default:
      DEBUG("error handling message, disconnecting");
      cont = 0;
      res = 1;
      break;
    }
  }
  close(listen_fd);
  close(ei_fd);
  return res;
}
