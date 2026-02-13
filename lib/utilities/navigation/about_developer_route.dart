import 'package:flutter/material.dart';
import 'package:infinitynotes/views/about/about_developer_view.dart';

void openAboutDeveloper(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const AboutDeveloperView(),
    ),
  );
}
