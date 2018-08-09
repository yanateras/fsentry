with import <nixpkgs> {};

stdenv.mkDerivation {
  name = "fsentry";

  buildInputs = [
    elixir
  ] ++ lib.optionals (stdenv.isDarwin) [
    libinotify-kqueue
    pkgconfig  
  ];
}
