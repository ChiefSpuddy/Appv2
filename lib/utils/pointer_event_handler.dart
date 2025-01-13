import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SafePointerEventHandler {
  static bool _initialized = false;

  static void initializePointerEventHandling() {
    // Only run on web platform
    if (!kIsWeb) return;

    if (!_initialized) {
      // Ensure initialization happens only once
      _initialized = true;

      // Only handle text field related pointer binding errors
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exception.toString().contains('targetElement == domElement')) {
          // Ignore this specific error for text fields
          return;
        }
        // Forward other errors to Flutter's error handler
        FlutterError.presentError(details);
      };

      // Add platform-specific channel
      const channel = MethodChannel('pointer_handler');
      channel.setMethodCallHandler((call) async {
        if (call.method == 'handlePointerEvent') {
          // Handle any platform-specific pointer events
          return null;
        }
        return null;
      });
    }
  }

  static bool _isPointerError(dynamic exception) {
    final errorString = exception.toString().toLowerCase();
    return errorString.contains('targetelement == domelement') ||
           errorString.contains('the targeted input element') ||
           errorString.contains('pointer_binding');
  }
}
