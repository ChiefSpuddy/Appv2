import 'package:flutter/material.dart';

extension ScaffoldExtensions on ScaffoldState {
  T? findBottomChild<T>() {
    final ScaffoldFeatureController? controller = 
        widget.bottomNavigationBar as ScaffoldFeatureController?;
    return controller?.widget as T?;
  }
}
