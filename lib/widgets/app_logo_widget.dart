import 'package:flutter/material.dart';
import '../theme/meow_theme.dart';

class AppLogoWidget extends StatelessWidget {
  final double size;
  final double borderRadius;
  final bool withBorder;
  final bool withShadow;

  const AppLogoWidget({
    super.key,
    this.size = 40,
    this.borderRadius = 10,
    this.withBorder = true,
    this.withShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: withBorder ? Border.all(color: MeowTheme.mustardYellow.withOpacity(0.4), width: 1.5) : null,
        boxShadow: withShadow ? [
          BoxShadow(
            color: MeowTheme.mustardYellow.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          'assets/icons/app_logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: MeowTheme.mustardYellow,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Icon(Icons.account_balance_wallet_rounded, color: MeowTheme.textDarkPrimary, size: size * 0.6),
          ),
        ),
      ),
    );
  }
}
