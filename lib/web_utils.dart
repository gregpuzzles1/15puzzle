/// Web-specific utilities for removing loading spinner
/// This file is imported conditionally only on web platform
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void removeLoadingSpinner() {
  html.document.querySelector('#loading')?.remove();
}
