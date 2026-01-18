// Stub implementation for non-web platforms
void removeLoadingSpinner() {
  // No-op on non-web platforms
}

bool openExternalUrl(String url) {
  // No-op on non-web platforms (we'll fall back to clipboard copy).
  return false;
}

bool isSafariBrowser() {
  return false;
}
