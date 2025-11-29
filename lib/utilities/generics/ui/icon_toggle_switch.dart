import 'package:flutter/material.dart';

class IconToggleSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final Color activeColor;
  final Color inactiveColor;
  final double width;
  final double height;
  final double toggleSize;

  const IconToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.activeIcon,
    required this.inactiveIcon,
    this.activeColor = Colors.blue,
    this.inactiveColor = Colors.grey,
    this.width = 70,
    this.height = 40,
    this.toggleSize = 33,
  });

  @override
  State<IconToggleSwitch> createState() => _IconToggleSwitchState();
}

class _IconToggleSwitchState extends State<IconToggleSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      value: widget.value ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant IconToggleSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    widget.onChanged(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final double toggleSize = widget.toggleSize;
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final color = Color.lerp(
              widget.inactiveColor,
              widget.activeColor,
              _animationController.value);
          final alignment = Alignment.lerp(
              const Alignment(-0.85, 0),
              const Alignment(0.85, 0),
              _animationController.value)!;
          final icon = _animationController.value > 0.5
              ? widget.activeIcon
              : widget.inactiveIcon;

          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.height / 2),
              color: color,
            ),
            child: Stack(
              children: [
                Align(
                  alignment: alignment,
                  child: Container(
                    width: toggleSize,
                    height: toggleSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(66),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Icon(
                      icon,
                      size: toggleSize * 0.6,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
