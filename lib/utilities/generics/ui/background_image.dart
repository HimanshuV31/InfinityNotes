import 'package:flutter/material.dart';

class BackgroundImage extends StatelessWidget {
  const BackgroundImage({super.key});

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
        'assets/images/background.png',
        fit: BoxFit.cover);
    return SizedBox.expand(
      child: image,
    );
  }
}