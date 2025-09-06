import 'package:flutter/material.dart';
import 'package:luna_iot/app/app_theme.dart';

class HomeFeatureSectionTitle extends StatelessWidget {
  const HomeFeatureSectionTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: 15, bottom: 10),
      child: Text(
        title,
        textAlign: TextAlign.left,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.titleColor,
        ),
      ),
    );
  }
}
