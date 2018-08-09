# FSentry

FSentry is an Elixir module for spawning FS sentries. It is implemented as a
[port driver][] that streams FS event messages to a designated PID.

[port driver]: http://erlang.org/doc/tutorial/c_portdriver.html

Based on Inotify. macOS and BSD users should install [libinotify-kqueue][],
Windows users are currently out of luck (although it would be nice to have a
Win32 Inotify implementation).

[libinotify-kqueue]: https://github.com/libinotify-kqueue/libinotify-kqueue

Unlike [synrc/fs](https://github.com/synrc/fs), FSentry doesn't spawn external
processes and doesn't have any runtime dependencies. It also can listen on
individual files rather than just folders.
