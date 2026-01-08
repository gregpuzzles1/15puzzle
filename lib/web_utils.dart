// Web-specific utilities for removing loading spinner
// This file is imported conditionally only on web platform
// ignore_for_file: avoid_web_libraries_in_flutter

// Web-specific utilities for removing loading spinner
// This file is imported conditionally only on web platform
import 'dart:html' as html;

void removeLoadingSpinner() {
  html.document.querySelector('#loading')?.remove();
}
