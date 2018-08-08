with import <nixpkgs> {};

stdenv.mkDerivation {
  name = "fsentry";
  buildInputs = [ elixir ];
}
