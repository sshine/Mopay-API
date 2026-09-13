# CI checks for the MobilePay reverse-engineering pipeline.
{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks.mobilepay-phase1 = pkgs.callPackage ./_mobilepay-phase1.nix { };
    };
}
