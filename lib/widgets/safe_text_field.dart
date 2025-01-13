import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class SafeTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool autofocus;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;

  const SafeTextField({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onTap,
    this.autofocus = false,
    this.decoration,
    this.keyboardType,
    this.focusNode,
  });

  @override
  State<SafeTextField> createState() => _SafeTextFieldState();
}

class _SafeTextFieldState extends State<SafeTextField> {
  late FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus != _hasFocus) {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      decoration: widget.decoration ?? InputDecoration(
        hintText: widget.hintText,
        // Add padding to prevent text from being too close to the edges
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        // Use outlined border for better visibility
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onChanged: widget.onChanged,
      onTap: () {
        if (kIsWeb) {
          // Add a slight delay for web platforms
          Future.delayed(const Duration(milliseconds: 50), () {
            if (widget.onTap != null) {
              widget.onTap!();
            }
          });
        } else {
          if (widget.onTap != null) {
            widget.onTap!();
          }
        }
      },
      autofocus: widget.autofocus,
      keyboardType: widget.keyboardType,
    );
  }
}
