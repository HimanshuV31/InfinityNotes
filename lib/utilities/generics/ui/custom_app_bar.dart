import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? themeColor;
  final IconButton? leading;

  const CustomAppBar({
    super.key,
    required this.title,
    this.themeColor,
    this.titleWidget,
    required this.foregroundColor,
    required this.backgroundColor,
    this.actions,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    const double fontSize = 23;
    const double strokeWidth = 2;
    const double letterSpacing = 1.5;

    return AppBar(
      title: titleWidget ??
          (title != null
              ? Stack(
            children: [
              Text(
                title!,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: letterSpacing,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = strokeWidth
                    ..color = backgroundColor,
                ),
              ),
              Text(
                title!,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: foregroundColor,
                  letterSpacing: letterSpacing,
                ),
              ),
            ],
          )
              : null),
      backgroundColor: themeColor ?? backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 0,
      leading: leading,
      actions: actions,
      flexibleSpace: themeColor != null
          ? null
          : LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 600;
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  isDesktop
                      ? "assets/images/Web_AppBar_Background.png"
                      : "assets/images/Phone_AppBar_Background.png",
                ),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
