import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpBoxes extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onChanged;
  final List<String>? initialValue;

  const OtpBoxes({this.length = 4, this.onChanged, this.initialValue, super.key});

  @override
  State<OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<OtpBoxes> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (i) {
      final c = TextEditingController();
      if (widget.initialValue != null && i < widget.initialValue!.length) {
        c.text = widget.initialValue![i];
      }
      return c;
    });
    _nodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _notify() {
    widget.onChanged?.call(_controllers.map((c) => c.text).join());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: List.generate(widget.length, (i) {
        return Expanded(
          child: Container(
            height: 64,
            margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow ?? colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: TextField(
              controller: _controllers[i],
              focusNode: _nodes[i],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(1)],
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (v) {
                if (v.isNotEmpty && i < widget.length - 1) {
                  _nodes[i + 1].requestFocus();
                } else if (v.isEmpty && i > 0) {
                  _nodes[i - 1].requestFocus();
                }
                _notify();
              },
            ),
          ),
        );
      }),
    );
  }
}
