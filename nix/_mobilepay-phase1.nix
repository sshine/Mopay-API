# Phase-1 reverse-engineering derivation for the vendored MobilePay APK.
#
# Realises the APK into the Nix store, runs a narrow set of static recon
# commands, and writes a short report. No full decompile yet.
#
# Prefixed with underscore: this is a bare Nix expression, not a flake-parts
# module, so import-tree must not pick it up.
{
  lib,
  stdenv,
  fetchurl,
  file,
  gnugrep,
  gawk,
  coreutils,
  mobilepay ? null,
}: let
  src = if mobilepay != null then mobilepay else fetchurl {
    name = "mobilepay-10.35.37-arm64.apk";
    url = "https://www.apkmirror.com/apk/vipps-as/mobilepay/mobilepay-10-35-37-release/mobilepay-10-35-37-2-android-apk-download/download/?key=b6466057a1afc1f97e4738f776049cce6af534df";
    hash = "sha256-ZW1eXXHAN10FcG9PZgksRFmzHEpQ25sml1yHO1f+9rA=";
  };
in
stdenv.mkDerivation {
  name = "mobilepay-phase1-recon";
  src = src;
  nativeBuildInputs = [ file gnugrep gawk coreutils ];
  buildPhase = ''
    set -euo pipefail
    mkdir -p $out
    {
      echo "# MobilePay phase-1 recon"
      echo ""
      echo "## File"
      file $src
      echo ""
      echo "## Size"
      du -h $src
      echo ""
      echo "## Zip listing (top)"
      unzip -l $src | head -n 40
      echo ""
      echo "## Strings (urls / api / token)"
      strings $src | grep -Eio 'https?://[^[:space:]]+' | sort -u | head -n 50
      echo ""
      echo "## .so files"
      unzip -l $src | grep -E '\.so$' || true
    } > $out/phase1_recon.md
  '';
  installPhase = ''
    mkdir -p $out
    cp phase1_recon.md $out/
  '';
}
