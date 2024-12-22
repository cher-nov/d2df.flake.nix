{
  doom2df-base = import ./doom2df;
  editor = import ./editor;
  wadcvt = import ./utils/wadcvt.nix;
  dfwad = import ./utils/dfwad.nix;
  doom2df-bundle = import ./bundle;
  buildWad = (import ./buildWad).buildWad;
  buildWadScript = (import ./buildWad).buildWadScript;
}
