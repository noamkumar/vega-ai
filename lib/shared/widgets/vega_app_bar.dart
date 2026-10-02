import 'package:flutter/material.dart';
import 'package:vega_ai/core/constants/app_colors.dart';

/// Standard branded AppBar for VEGA AI secondary screens.
class VegaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  const VegaAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      leading: leading,
      title: ShaderMask(
        shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
      ),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
          height: 1.0,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1.0);
}
