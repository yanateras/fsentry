#include <limits.h>
#include <string.h>
#include <unistd.h>

#include <sys/inotify.h>

// http://erlang.org/doc/man/erl_driver.html
#include "erl_driver.h"

#define BUFLEN (NAME_MAX + 1 + sizeof(struct inotify_event)) * 16
#define LENGTH(x) sizeof(x) / sizeof(*x)

struct state {
  ErlDrvPort port;
  int fd;
  int wd;
};

static ErlDrvData start(ErlDrvPort port, char *command) {
  command += LENGTH("fsentry");

  struct state *state = driver_alloc(sizeof(*state));

  if (!state)
    return ERL_DRV_ERROR_GENERAL;

  state->port = port;
  state->fd = inotify_init1(IN_NONBLOCK | IN_CLOEXEC);

  if (state->fd == -1) {
    driver_free(state);
    return ERL_DRV_ERROR_ERRNO;
  }

  state->wd = inotify_add_watch(state->fd, command, IN_ALL_EVENTS);

  if (state->wd == -1) {
    close(state->fd);
    driver_free(state);
    return ERL_DRV_ERROR_ERRNO;
  }

  driver_select(state->port, (ErlDrvEvent)(intptr_t)state->fd,
                ERL_DRV_READ | ERL_DRV_USE, 1);

  return (ErlDrvData)state;
}

static void stop(ErlDrvData data) {
  struct state *state = (struct state *)data;
  driver_select(state->port, (ErlDrvEvent)(intptr_t)state->fd, ERL_DRV_USE, 0);
  close(state->fd);
  driver_free(state);
}

char *inotify_event_to_string(struct inotify_event *i) {
  if (i->mask & IN_ACCESS)
    return "access";
  if (i->mask & IN_ATTRIB)
    return "attrib";
  if (i->mask & IN_CLOSE_WRITE)
    return "close_write";
  if (i->mask & IN_CLOSE_NOWRITE)
    return "close_nowrite";
  if (i->mask & IN_CREATE)
    return "create";
  if (i->mask & IN_DELETE)
    return "delete";
  if (i->mask & IN_DELETE_SELF)
    return "delete_self";
  if (i->mask & IN_MODIFY)
    return "modify";
  if (i->mask & IN_MOVE_SELF)
    return "move_self";
  if (i->mask & IN_MOVED_FROM)
    return "moved_from";
  if (i->mask & IN_MOVED_TO)
    return "moved_to";
  if (i->mask & IN_OPEN)
    return "open";
}

void ready_input(ErlDrvData data, ErlDrvEvent event) {
  struct state *state = (struct state *)data;
  int fd = (intptr_t)event;

  for (;;) {
    char buf[BUFLEN];
    char *ptr = buf;

    int n = read(fd, buf, BUFLEN);

    if (n <= 0)
      break;

    while (ptr < buf + n) {
      struct inotify_event *if_event = (struct inotify_event *)ptr;

      ErlDrvBinary *name = driver_alloc_binary(strlen(if_event->name));
      memcpy(name->orig_bytes, &if_event->name, name->orig_size);

      ErlDrvTermData term[] = {
          ERL_DRV_PORT,   driver_mk_port(state->port),
          ERL_DRV_BINARY, (ErlDrvTermData)name, (ErlDrvTermData)name->orig_size, 0,
          ERL_DRV_ATOM,   driver_mk_atom(inotify_event_to_string(if_event)),
          ERL_DRV_TUPLE,  3};

      erl_drv_output_term(driver_mk_port(state->port), term, LENGTH(term));
      driver_free_binary(name);

      ptr += sizeof(struct inotify_event) + if_event->len;
    }
  }
}

static void stop_select(ErlDrvEvent event, void *reserved) {
  close((intptr_t)event);
}

static ErlDrvEntry driver_entry = {
    .init = NULL,
    .start = start,
    .stop = stop,
    .ready_input = ready_input,
    .stop_select = stop_select,
    .driver_name = "fsentry",
    .extended_marker = ERL_DRV_EXTENDED_MARKER,
    .major_version = ERL_DRV_EXTENDED_MAJOR_VERSION,
    .minor_version = ERL_DRV_EXTENDED_MINOR_VERSION};

DRIVER_INIT(fsentry) { return &driver_entry; }
