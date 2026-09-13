# Phase-1 reverse-engineering derivation for the vendored MobilePay APK.
#
# Realises the APK (or XAPK) into the Nix store, runs a narrow set of static
# recon commands, and writes a short report. No full decompile yet.
{
  lib,
  stdenv,
  fetchurl,
  unzip,
  file,
  gnugrep,
  gawk,
  coreutils,
  mobilepay ? null,
}: let
  src = if mobilepay != null then mobilepay else fetchurl {
    name = "mobilepay-10.35.37.xapk";
    url = "https://mobilepay.en.uptodown.com/android/download";
    hash = "sha256-ZW1eXXHAN10FcG9PZgksRFmzHEpQ25sml1yHO1f+9rA=";
  };

  # The Uptodown artefact is an XAPK (zip). Extract the base APK for recon.
  baseApk = stdenv.mkDerivation {
    name = "mobilepay-10.35.37-base.apk";
    src = src;
    nativeBuildInputs = [ unzip ];
    unpackPhase = ''
      unzip -o $src -d $out
    '';
    installPhase = ''
      # Prefer the base APK; fall back to the first .apk found.
      apk=$(find $out -name 'base.apk' -o -name '*.apk' | head -n1)
      cp "$apk" $out/base.apk
    '';
  };
in
stdenv.mkDerivation {
  name = "mobilepay-phase1-recon";
  src = baseApk;
  nativeBuildInputs = [ unzip file gnugrep gawk coreutils ];
  buildPhase = ''
    set -euo pipefail
    mkdir -p $out
    {
      echo "# MobilePay phase-1 recon"
      echo ""
      echo "## File"
      file base.apk
      echo ""
      echo "## Size"
      du -h base.apk
      echo ""
      echo "## Zip listing (top)"
      unzip -l base.apk | head -n 40
      echo ""
      echo "## Strings (urls / api / token)"
      strings base.apk | grep -Eio 'https?://[^[:space:]]+' | sort -u | head -n 50
      echo ""
      echo "## .so files"
      unzip -l base.apk | grep -E '\.so$' || true
    } > $out/phase1_recon.md
  '';
  installPhase = ''
    mkdir -p $out
    cp phase1_recon.md $out/
  '';
}
