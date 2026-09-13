{ ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    rec {
      checks.mopay-api = packages.default;

      packages.default = pkgs.callPackage ./_package.nix { };

      apps.default = {
        type = "app";
        program = lib.getExe packages.default;
      };
    };
}
