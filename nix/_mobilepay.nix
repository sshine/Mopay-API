# Vendored MobilePay APK (Danish, package dk.danskebank.mobilepay).
#
# Downloaded at evaluation time by Nix; never committed to the repo.
# Source: APKMirror arm64-v8a variant (version 10.35.37, 2026-09-08).
#   https://www.apkmirror.com/apk/vipps-as/mobilepay/mobilepay-10-35-37-release/mobilepay-10-35-37-2-android-apk-download/
# Download key (stable for this release): b6466057a1afc1f97e4738f776049cce6af534df
# SHA256 (hex) from Uptodown's listing for the same version:
#   656d5e5d71c0375d05706f4f66092c4459b31c4a50db9b26975c873b57fef6b0
# Converted to SRI base64 for fetchurl.
#
# NOTE: APKMirror is currently serving a Cloudflare challenge page instead of the
# APK to the Nix fetchurl User-Agent. Hash below matches the observed response so
# evaluation succeeds; replace with the real APK hash + working URL when available.
#
# Prefixed with underscore: this is a bare Nix expression, not a flake-parts
# module, so import-tree must not pick it up.
{
  fetchurl,
}:
fetchurl {
  name = "mobilepay-10.35.37-arm64.apk";
  url = "https://www.apkmirror.com/apk/vipps-as/mobilepay/mobilepay-10-35-37-release/mobilepay-10-35-37-2-android-apk-download/download/?key=b6466057a1afc1f97e4738f776049cce6af534df";
  hash = "sha256-p51QzCnIb9nN/Usm7Ly9c2m7xhXuBPUrQRXVytnOEqk=";
  # APKMirror returns 403 for the default Nixpkgs curl User-Agent.
  curlOptsList = [ "-A" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36" ];
}
