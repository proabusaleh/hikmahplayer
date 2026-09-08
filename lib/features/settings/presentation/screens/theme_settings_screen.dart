import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/theme/app_colors.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = AppScope.of(context).theme;
    return Scaffold(
      appBar: AppBar(title: const Text('Theme')),
      body: ListView(
        children: [
          const _SectionLabel('Mode'),
          RadioGroup<ThemeMode>(
            groupValue: controller.themeMode,
            onChanged: (v) => controller.setThemeMode(v!),
            child: const Column(
              children: [
                RadioListTile<ThemeMode>(title: Text('Light'), value: ThemeMode.light),
                RadioListTile<ThemeMode>(title: Text('Dark'), value: ThemeMode.dark),
                RadioListTile<ThemeMode>(subtitle: Text('Follows device setting'), title: Text('System'), value: ThemeMode.system),
              ],
            ),
          ),
          SwitchListTile(
            title: const Text('Use system accent colors'),
            subtitle: Text(controller.dynamicSeed != null ? 'Follows your OS accent color' : 'Not available on this device'),
            value: controller.dynamicSeed != null && controller.useDynamicColor,
            onChanged: controller.dynamicSeed != null ? (v) => controller.setUseDynamicColor(v) : null,
          ),
          SwitchListTile(
            title: const Text('Pure black dark mode'),
            subtitle: const Text('AMOLED friendly surfaces'),
            value: controller.usePureBlack,
            onChanged: (v) => controller.setUsePureBlack(v),
          ),
          const _SectionLabel('Accent color'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < AppColors.seedChoices.length; i++)
                  _SeedSwatch(
                    choice: AppColors.seedChoices[i],
                    selected: !controller.useDynamicColor && controller.seedChoice.id == AppColors.seedChoices[i].id,
                    onTap: () => controller.setSeedColorIndex(i),
                  ),
              ],
            ),
          ),
          SizedBox(height: theme.visualDensity.baseSizeAdjustment.dx),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
}

class _SeedSwatch extends StatelessWidget {
  const _SeedSwatch({required this.choice, required this.selected, required this.onTap});

  final SeedChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: choice.color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
            width: 3,
          ),
        ),
        child: selected ? const Icon(Icons.check, color: Colors.white) : null,
      ),
    );
  }
}
