import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

class AppBarTabBar {
  static PreferredSizeWidget buildAppBar({
    required BuildContext context,
    String title = '',
    Widget? titleWidget,
    VoidCallback? onBackPressed,
    bool showBackButton = true,
    IconData? backIcon,
    List<Widget>? actions,
    PreferredSizeWidget? bottom,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final effectiveBackgroundColor =
        backgroundColor ?? theme.colorScheme.primary;
    final effectiveForegroundColor =
        foregroundColor ?? theme.colorScheme.onPrimary;
    final effectiveTitle = title.isEmpty ? l10n.appTitle : title;

    return AppBar(
      backgroundColor: effectiveBackgroundColor,
      foregroundColor: effectiveForegroundColor,
      elevation: elevation ?? 1.0,
      scrolledUnderElevation: 1.0,
      leading:
          showBackButton
              ? IconButton(
                icon: Icon(backIcon ?? Icons.arrow_back),
                tooltip: l10n.backTooltip,
                onPressed: onBackPressed ?? () => Navigator.maybePop(context),
              )
              : null,
      title:
          titleWidget ??
          Text(
            effectiveTitle,
            style: GoogleFonts.notoSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
      centerTitle: true,
      actions: actions,
      bottom: bottom,
    );
  }

  static PreferredSizeWidget buildTabBar({
    required BuildContext context,
    required List<String> tabTitles,
    required Function(int) onTabChanged,
    TabController? controller,
    TextStyle? labelStyle,
    TextStyle? unselectedLabelStyle,
    Color? labelColor,
    Color? unselectedLabelColor,
    Color? indicatorColor,
    Color? backgroundColor,
  }) {
    final theme = Theme.of(context);
    return PreferredSize(
      preferredSize: const Size.fromHeight(kTextTabBarHeight),
      child: Material(
        color: backgroundColor ?? theme.colorScheme.surface,
        child: TabBar(
          controller: controller,
          labelStyle:
              labelStyle ??
              GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              unselectedLabelStyle ??
              GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w500),
          labelColor: labelColor ?? theme.colorScheme.primary,
          unselectedLabelColor:
              unselectedLabelColor ??
              theme.colorScheme.onSurface.withValues(alpha: 0.7),
          indicatorColor: indicatorColor ?? theme.colorScheme.primary,
          indicatorWeight: 2.5,
          onTap: onTabChanged,
          tabs: tabTitles.map((title) => Tab(text: title)).toList(),
          tabAlignment: TabAlignment.fill,
          dividerColor: theme.dividerColor.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
