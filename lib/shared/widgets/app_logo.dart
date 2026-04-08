import 'package:flutter/material.dart';
import '../../core/constants/app_text_styles.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 26});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icon.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

class AppLogoTitle extends StatelessWidget {
  final String? title;
  final TextStyle? textStyle;
  final double logoSize;

  const AppLogoTitle({
    super.key,
    this.title,
    this.textStyle,
    this.logoSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(size: logoSize),
        if (title != null && title!.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(title!, style: textStyle ?? AppTextStyles.heading2),
        ],
      ],
    );
  }
}
