/// Web-specific utilities for removing loading spinner
/// This file is imported conditionally only on web platform
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js' as js;

void removeLoadingSpinner() {
  html.document.querySelector('#loading')?.remove();
}

/// Initialize audio context for iOS/Safari compatibility
/// Safari requires user interaction before playing audio
void initAudioContext() {
  try {
    // Resume AudioContext for Safari
    js.context.callMethod('eval', [
      '''
      (function() {
        if (typeof AudioContext !== 'undefined') {
          var ctx = new (window.AudioContext || window.webkitAudioContext)();
          if (ctx.state === 'suspended') {
            ctx.resume();
          }
        }
      })();
      '''
    ]);
  } catch (e) {
    // Ignore errors - not all platforms need this
  }
}
