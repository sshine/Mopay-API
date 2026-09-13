# Vendored MobilePay APK (Danish, package dk.danskebank.mobilepay).
#
# Downloaded at evaluation time by Nix; never committed to the repo.
# Source: Uptodown (XAPK, arm64). Version 10.35.37, 2026-09-09.
# SHA256 (hex) from Uptodown's listing: 656d5e5d71c0375d05706f4f66092c4459b31c4a50db9b26975c873b57fef6b0
# Converted to SRI base64 for fetchurl.
{
  fetchurl,
}:
fetchurl {
  name = "mobilepay-10.35.37.xapk";
  url = "https://mobilepay.en.uptodown.com/android/download";
  hash = "sha256-ZW1eXXHAN10FcG9PZgksRFmzHEpQ25sml1yHO1f+9rA=";
  # Note: Uptodown's download page is a redirector; the actual bytes are
  # served from their CDN. If fetchurl fails on the redirect, pin a direct
  # CDN URL instead (see comments in the commit history).
}
