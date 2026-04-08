import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'app_logo.dart';

class StartupSplashScreen extends StatefulWidget {
  const StartupSplashScreen({
    super.key,
    this.rotationDuration = const Duration(seconds: 5),
  });

  final Duration rotationDuration;

  @override
  State<StartupSplashScreen> createState() => _StartupSplashScreenState();
}

class _StartupSplashScreenState extends State<StartupSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: widget.rotationDuration,
    )..repeat();

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.96, end: 1.03).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.03, end: 0.96).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 50,
      ),
    ]).animate(_rotationController);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: RotationTransition(
                turns: _rotationController,
                child: const AppLogo(size: 90),
              ),
            ),
            const SizedBox(height: 18),
            Text('Ceylon Market', style: AppTextStyles.heading1),
          ],
        ),
      ),
    );
  }
}