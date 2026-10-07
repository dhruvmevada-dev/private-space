import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Four animated PIN boxes backed by a hidden numeric TextField.
class PinField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool autofocus;
  final bool hasError;
  final FocusNode? focusNode;
  final ValueChanged<String>? onCompleted;

  const PinField({
    super.key,
    required this.controller,
    required this.label,
    this.autofocus = false,
    this.hasError = false,
    this.focusNode,
    this.onCompleted,
  });

  @override
  State<PinField> createState() => _PinFieldState();
}

class _PinFieldState extends State<PinField> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
    _focus.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    _focus.removeListener(_refresh);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _onChange() {
    if (!mounted) return;
    setState(() {});
    if (widget.controller.text.length == 4) widget.onCompleted?.call(widget.controller.text);
  }

  void _focusAndShowKeyboard() {
    _focus.requestFocus();
    SystemChannels.textInput.invokeMethod('TextInput.show');
  }

  @override
  Widget build(BuildContext context) {
    final len = widget.controller.text.length;
    return Column(
      children: [
        Text(widget.label, style: const TextStyle(color: AppColors.muted, fontSize: 13.5)),
        const SizedBox(height: 12),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _focusAndShowKeyboard,
          child: Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < len;
                  final active = _focus.hasFocus && i == (len > 3 ? 3 : len);
                  final borderColor = widget.hasError
                      ? AppColors.error
                      : active
                          ? AppColors.primary
                          : filled
                              ? AppColors.primary.withOpacity(0.5)
                              : AppColors.outline;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 58,
                    height: 64,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: active ? 2 : 1.2),
                      boxShadow: active
                          ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 14)]
                          : const [],
                    ),
                    child: AnimatedScale(
                      scale: filled ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutBack,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.gradient,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      autofocus: widget.autofocus,
                      obscureText: true,
                      showCursor: false,
                      enableInteractiveSelection: false,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration.collapsed(hintText: ''),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
