# `packages.default` stays the library: it is what this repository publishes, and what
# `checks.mopay` names. The server is reached by name, which is also what an MCP client
# configuration would spell out.
{ ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    rec {
      checks.mopay = packages.default;
      checks.mopay-mcp = packages.mopay-mcp;

      packages.default = pkgs.callPackage ./_package.nix { };
      packages.mopay-mcp = pkgs.callPackage ./_package.nix { crate = "mopay-mcp"; };

      # The only runnable thing here, so it is the default app even though it is not the
      # default package. `nix run github:sshine/Mopay-API` starts the MCP server on stdio.
      apps.mopay-mcp = {
        type = "app";
        program = lib.getExe packages.mopay-mcp;
      };
      apps.default = apps.mopay-mcp;
    };
}
