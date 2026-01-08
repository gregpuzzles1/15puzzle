// Web-specific utilities for removing loading spinner
// This file is imported conditionally only on web platform
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void removeLoadingSpinner() {
  html.document.querySelector('#loading')?.remove();
}

bool isSafariBrowser() {
  final ua = html.window.navigator.userAgent;

  final isAppleWebKit = ua.contains('AppleWebKit');
  final isSafari = ua.contains('Safari');
  final isChrome = ua.contains('Chrome') || ua.contains('CriOS');
  final isFirefox = ua.contains('Firefox') || ua.contains('FxiOS');
  final isEdge = ua.contains('Edg') || ua.contains('EdgiOS');

  return isAppleWebKit && isSafari && !(isChrome || isFirefox || isEdge);
}
