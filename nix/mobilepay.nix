# Vendored MobilePay APK (Danish, package dk.danskebank.mobilepay).
#
# Downloaded at evaluation time by Nix; never committed to the repo.
# Source: Uptodown (XAPK, arm64). Version 10.35.37, 2026-09-09.
# SHA256 from Uptodown's listing.
{
  fetchurl,
}:
fetchurl {
  name = "mobilepay-10.35.37.xapk";
  url = "https://mobilepay.en.uptodown.com/android/download";
  hash = "sha256-ZW1eX1cAN10FcHZg9mC0ZJBbMcSlDbkyaXlcgztX/vaw=";
  # Note: Uptodown's download page is a redirector; the actual bytes are
  # served from their CDN. If fetchurl fails on the redirect, pin a direct
  # CDN URL instead (see comments in the commit history).
}
