{ ... }:
{
  flake.overlays.default = final: _prev: {
    mopay = final.callPackage ./_package.nix { };
    mopay-mcp = final.callPackage ./_package.nix { crate = "mopay-mcp"; };
  };
}
