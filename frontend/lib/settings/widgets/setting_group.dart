import 'package:flutter/material.dart';
import '../../Theme/app_theme.dart';
import 'setting_tile.dart';

class SettingGroup extends StatelessWidget {
  final List<Widget> children;

  const SettingGroup({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: List.generate(children.length, (i) {
          final isLast = i == children.length - 1;
          final child = children[i];
          if (child is SettingTile) {
            return SettingTile(
              icon: child.icon,
              title: child.title,
              onTap: child.onTap,
              iconColor: child.iconColor,
              textColor: child.textColor,
              isLast: isLast,
            );
          }
          return child;
        }),
      ),
    );
  }
}