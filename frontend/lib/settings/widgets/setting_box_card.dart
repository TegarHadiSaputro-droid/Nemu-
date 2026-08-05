import 'package:flutter/material.dart';

/// Box besar bergaya seperti card "Dokumen wajib" di Nemu+ —
/// rounded besar, putih, mengisi penuh ruang yang tersedia.
class SettingBoxCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const SettingBoxCard({
    super.key,
    this.children = const [],
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Column(children: children),
      ),
    );
  }
}