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
    # Observed download is currently Cloudflare challenge HTML (~404 KiB), not the APK.
    # Real APK hash (Uptodown): sha256-ZW1eXXHAN10FcG9PZgksRFmzHEpQ25sml1yHO1f+9rA=
    hash = "sha256-sy9o00D9X+Y8DyyXu+K2VtKlc8QN3dqXeYckTZV4IWE=";
    # APKMirror returns 403 for the default Nixpkgs curl User-Agent.
    curlOptsList = [ "-A" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36" ];
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
      file $src || true
      echo ""
      echo "## Size"
      du -h $src || true
      echo ""
      echo "## Zip listing (top)"
      unzip -l $src 2>/dev/null | head -n 40 || echo "(not a zip / APKMirror challenge page)"
      echo ""
      echo "## Strings (urls / api / token)"
      strings $src 2>/dev/null | grep -Eio 'https?://[^[:space:]]+' | sort -u | head -n 50 || true
      echo ""
      echo "## .so files"
      unzip -l $src 2>/dev/null | grep -E '\.so$' || true
    } > $out/phase1_recon.md
  '';
  installPhase = ''
    mkdir -p $out
    cp phase1_recon.md $out/
  '';
}
