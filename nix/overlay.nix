{ ... }:
{
  flake.overlays.default = final: _prev: {
    mopay-api = final.callPackage ./_package.nix { };
  };
}
