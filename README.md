# FSentry

FSentry is an Elixir module for spawning FS sentries. It is implemented as a
[port driver][] that streams FS event messages to a designated PID.

[port driver]: http://erlang.org/doc/tutorial/c_portdriver.html

Currently, only Inotify backend is implemented, although Kqueue and Win32
implementations are planned.

Unlike [synrc/fs](https://github.com/synrc/fs), FSentry doesn't spawn external
processes and doesn't have any runtime dependencies. It also can listen on
individual files rather than just folders.
