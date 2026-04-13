import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kAdminPrimary = Color(0xFF00A8FF);

TextStyle get kAdminHeaderTitleStyle => GoogleFonts.leagueSpartan(
  fontSize: 26,
  fontWeight: FontWeight.bold,
  color: Colors.white,
  height: 1.08,
);

TextStyle get kAdminHeaderSubtitleStyle => const TextStyle(
  fontSize: 14,
  color: Colors.white60,
  fontWeight: FontWeight.w500,
  height: 1.25,
);

EdgeInsets adminHeaderPadding(BuildContext context, {double bottom = 12}) {
  final topPadding = MediaQuery.of(context).padding.top;
  return EdgeInsets.fromLTRB(16, topPadding + 14, 16, bottom);
}

ButtonStyle adminOutlineButtonStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: Colors.white,
    side: const BorderSide(color: Colors.white24),
    minimumSize: const Size(0, 42),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  );
}

ButtonStyle adminPrimaryButtonStyle({
  Color backgroundColor = kAdminPrimary,
  Color foregroundColor = Colors.white,
}) {
  return ElevatedButton.styleFrom(
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    minimumSize: const Size(0, 42),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  );
}

Widget adminFilterChip({
  required String label,
  required bool selected,
  required VoidCallback onTap,
  Color selectedColor = kAdminPrimary,
  Color unselectedColor = const Color(0xFF121A2B),
  Color selectedTextColor = Colors.white,
  Color unselectedTextColor = Colors.white70,
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  ),
  double radius = 20,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(radius),
    child: Container(
      padding: padding,
      decoration: BoxDecoration(
        color: selected ? selectedColor : unselectedColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: selected ? selectedColor : Colors.white12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? selectedTextColor : unselectedTextColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class AdminPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  const AdminPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final hasActions = actions.isNotEmpty;
    final hasMultipleActions = actions.length > 1;

    return Padding(
      padding: adminHeaderPadding(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: kAdminHeaderTitleStyle),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(subtitle!, style: kAdminHeaderSubtitleStyle),
                ],
              ],
            ),
          ),
          if (hasActions) ...[
            const SizedBox(width: 10),
            if (hasMultipleActions)
              IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...actions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final action = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == actions.length - 1 ? 0 : 8,
                        ),
                        child: action,
                      );
                    }),
                  ],
                ),
              )
            else
              actions.first,
          ],
        ],
      ),
    );
  }
}
