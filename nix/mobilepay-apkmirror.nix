# Alternative vendor source: APKMirror arm64-v8a APK (base + 3 splits, 42.55 MB).
# Version 10.35.37, uploaded 2026-09-08. Direct download key expires; re-scrape
# the page if it 404s. No SHA256 published by APKMirror for this variant.
{
  fetchurl,
}:
fetchurl {
  name = "mobilepay-10.35.37-arm64.apk";
  url = "https://www.apkmirror.com/apk/vipps-as/mobilepay/mobilepay-10-35-37-release/mobilepay-10-35-37-2-android-apk-download/download/?key=b6466057a1afc1f97e4738f776049cce6af534df";
  # hash omitted on purpose — run `nix-prefetch-url <url>` and paste the result.
  hash = lib.fakeSha256; # placeholder; replace after first fetch
}
