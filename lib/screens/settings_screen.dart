import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/food_repository.dart';
import '../l10n/strings.dart';
import '../models/app_enums.dart';
import '../models/notification_prefs.dart';
import '../theme/app_backdrop.dart';
import '../widgets/source_badge.dart';
import '../widgets/help_button.dart';
import '../providers/settings_controller.dart';
import '../widgets/pill_nav_bar.dart';
import 'detail_sections_screen.dart';
import 'sustainable_diet_screen.dart';
import '../theme/icon_service.dart';
import '../widgets/detail_parts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_info.dart';

/// TAB 3 — Impostazioni.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final st = context.watch<SettingsController>();
    final db = context.read<FoodDatabase>();
    final theme = Theme.of(context);

    Widget header(String text, {String? sub, Widget? help}) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: text),
                  if (help != null) WidgetSpan(alignment: PlaceholderAlignment.middle, child: help),
                ]),
                style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
              ),
              if (sub != null) ...[
                const SizedBox(height: 2),
                Text(sub, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(s.tabSettings)),
      body: ListView(
        padding: EdgeInsets.only(bottom: PillNavBar.overlap(context)),
        children: [
          header(s.language),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SegmentedButton<AppLanguage>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: AppLanguage.it, label: Text('Italiano')),
                ButtonSegment(value: AppLanguage.en, label: Text('English')),
              ],
              selected: {st.language},
              onSelectionChanged: (v) => st.setLanguage(v.first),
            ),
          ),
          header(s.theme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: const SlotIcon('settings.theme.light'),
                  label: Text(s.themeLight),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const SlotIcon('settings.theme.dark'),
                  label: Text(s.themeDark),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: const SlotIcon('settings.theme.system'),
                  label: Text(s.themeSystem),
                ),
              ],
              selected: {st.themeMode},
              onSelectionChanged: (v) => st.setThemeMode(v.first),
            ),
          ),
          header(s.frostTitle, sub: s.frostSub),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(s.frostNone, style: theme.textTheme.labelMedium),
                Expanded(
                  child: Slider(
                    value: st.frost,
                    divisions: 10,
                    label: '${(st.frost * 100).round()}%',
                    onChanged: st.setFrost,
                  ),
                ),
                Text(s.frostStrong, style: theme.textTheme.labelMedium),
              ],
            ),
          ),
          header(s.paletteTitle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final p in BackdropPalette.values)
                  ChoiceChip(
                    selected: st.palette == p,
                    onSelected: (_) => st.setPalette(p),
                    avatar: _PaletteSwatch(palette: p, top: st.customTop, bottom: st.customBottom),
                    label: Text(s.paletteName(p)),
                  ),
              ],
            ),
          ),
          // Custom palette: base colour (top) and secondary colour (bottom)
          if (st.palette == BackdropPalette.custom) ...[
            _ColorRow(
              label: s.paletteTopColor,
              value: st.customTop,
              onChanged: (c) => st.setCustomColors(top: c),
            ),
            _ColorRow(
              label: s.paletteBottomColor,
              value: st.customBottom,
              onChanged: (c) => st.setCustomColors(bottom: c),
            ),
          ],
          header(s.climateZone, sub: s.climateZoneSub, help: const HelpButton(field: 'seasonality.eufic_climatic_zones')),
          RadioGroup<ClimaticZone>(
            groupValue: st.zone,
            onChanged: (z) => st.setZone(z!),
            child: Column(
              children: [
                for (final z in ClimaticZone.values)
                  RadioListTile<ClimaticZone>(
                    value: z,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    title: Text(s.zone(z)),
                    subtitle: Text(
                      (db.zoneCountries[z] ?? const []).map(s.country).join(', '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: st.zone != ClimaticZone.mediterranean
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      header(s.macroArea, sub: s.macroAreaSub, help: const HelpButton(ids: ['italy_macro_areas'])),
                      RadioGroup<ItalyMacroArea>(
                        groupValue: st.area,
                        onChanged: (a) => st.setArea(a!),
                        child: Column(
                          children: [
                            for (final a in ItalyMacroArea.values)
                              RadioListTile<ItalyMacroArea>(
                                value: a,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                title: Text(s.area(a)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            title: TextWithHelp(s.approxSetting, helpIds: const ['seasonality_estimate'], helpSize: 18),
            subtitle: Text(s.approxSettingSub),
            value: st.allowApproximate,
            onChanged: st.setAllowApproximate,
          ),
          header(s.notifications),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: const SlotIcon('settings.notifications'),
            title: Text(s.peakNotif),
            subtitle: Text(s.peakNotifSub),
          ),
          RadioGroup<PeakNotifMode>(
            groupValue: st.peakNotifMode,
            onChanged: (v) => st.setPeakNotifMode(v!),
            child: Column(
              children: [
                for (final m in PeakNotifMode.values)
                  RadioListTile<PeakNotifMode>(
                    value: m,
                    dense: true,
                    contentPadding: const EdgeInsets.only(left: 52, right: 12),
                    title: Text(s.peakNotifMode(m)),
                  ),
              ],
            ),
          ),
          const Divider(indent: 20, endIndent: 20, height: 24),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: const SlotIcon('settings.shopping_mode'),
            title: Text(s.shoppingModeTitle),
            subtitle: Text(s.shoppingModeSub),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(72, 4, 20, 0),
            child: Text(s.shoppingModeListOption, style: theme.textTheme.labelLarge),
          ),
          RadioGroup<ShoppingNotifListMode>(
            groupValue: st.shoppingListMode,
            onChanged: (v) => st.setShoppingListMode(v!),
            child: Column(
              children: [
                for (final m in ShoppingNotifListMode.values)
                  RadioListTile<ShoppingNotifListMode>(
                    value: m,
                    dense: true,
                    contentPadding: const EdgeInsets.only(left: 52, right: 12),
                    title: Text(s.shoppingModeListMode(m)),
                  ),
              ],
            ),
          ),
          SwitchListTile(
            contentPadding: const EdgeInsets.only(left: 72, right: 20),
            title: Text(s.storageAfterShopping),
            subtitle: Text(s.storageAfterShoppingSub),
            value: st.storageTipsAfterShopping,
            onChanged: st.setStorageTipsAfterShopping,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: !st.storageTipsAfterShopping
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(72, 0, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.storageTipsWhen, style: theme.textTheme.labelLarge),
                        const SizedBox(height: 6),
                        SegmentedButton<bool>(
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(value: false, label: Text(s.storageTipsNow)),
                            ButtonSegment(value: true, label: Text(s.storageTipsLater)),
                          ],
                          selected: {st.storageTipsDelay > 0},
                          onSelectionChanged: (v) => st.setStorageTipsDelay(v.first ? 15 : 0),
                        ),
                        if (st.storageTipsDelay > 0) ...[
                          const SizedBox(height: 8),
                          _DelayPicker(minutes: st.storageTipsDelay, onChanged: st.setStorageTipsDelay),
                          Text(
                            s.storageTipsDelayNote,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
          header(s.secFoodPage),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: const SlotIcon('settings.detail_sections'),
            title: Text(s.detailSections),
            subtitle: Text(s.detailSectionsSub),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              AppPageRoute(builder: (_) => const DetailSectionsScreen()),
            ),
          ),
          header(s.about),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: const SlotIcon('settings.sustainable_diet'),
            title: Text(s.sustainableDiet),
            subtitle: Text(s.sustainableDietSub),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              AppPageRoute(builder: (_) => const SustainableDietScreen()),
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: const SlotIcon('settings.app_version'),
            title: Text(s.appVersionLabel(appVersion)),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: const SlotIcon('settings.database'),
            title: Text(s.databaseVersion(db.version, db.items.length)),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: const SourceBadge(sourceKey: 'github', size: 26),
            title: Text(s.githubApp),
            subtitle: Text(s.githubAppSub),
            trailing: const Icon(Icons.open_in_new_rounded, size: 20),
            onTap: () => launchUrl(Uri.parse(appRepoUrl), mode: LaunchMode.externalApplication),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: const SourceBadge(sourceKey: 'github', size: 26),
            title: Text(s.githubDatabase),
            subtitle: Text(s.githubDatabaseSub),
            trailing: const Icon(Icons.open_in_new_rounded, size: 20),
            onTap: () => launchUrl(Uri.parse(databaseRepoUrl), mode: LaunchMode.externalApplication),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: const SlotIcon('settings.license'),
            title: Text(s.licenseTitle),
            subtitle: Text(s.licenseSub),
          ),
        ],
      ),
    );
  }
}

/// Free delay of the storage notification: − / + and slider (1-120 min).
class _DelayPicker extends StatelessWidget {
  const _DelayPicker({required this.minutes, required this.onChanged});
  final int minutes;
  final ValueChanged<int> onChanged;

  static const _max = 120;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Row(
      children: [
        IconButton.filledTonal(
          visualDensity: VisualDensity.compact,
          onPressed: minutes > 1 ? () => onChanged(minutes - 1) : null,
          icon: const Icon(Icons.remove_rounded, size: 18),
        ),
        SizedBox(
          width: 76,
          child: Text(s.minutesShort(minutes), textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
        ),
        IconButton.filledTonal(
          visualDensity: VisualDensity.compact,
          onPressed: minutes < _max ? () => onChanged(minutes + 1) : null,
          icon: const Icon(Icons.add_rounded, size: 18),
        ),
        Expanded(
          child: Slider(
            value: minutes.toDouble(),
            min: 1,
            max: _max.toDouble(),
            divisions: _max - 1,
            label: s.minutesShort(minutes),
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}

/// Two-colour dot showing the tints of a palette.
class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({required this.palette, required this.top, required this.bottom});
  final BackdropPalette palette;
  final int top;
  final int bottom;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = BackdropColors.of(palette, false, customTop: top, customBottom: bottom);
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        gradient: c == null
            ? null
            : LinearGradient(colors: [c.first, c.second], stops: const [0.5, 0.5]),
        color: c == null ? (dark ? Colors.black : const Color(0xFFF3F5EE)) : null,
      ),
    );
  }
}

/// Row of colour dots to pick one colour of the custom palette.
class _ColorRow extends StatelessWidget {
  const _ColorRow({required this.label, required this.value, required this.onChanged});
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  /// Choices: one colour per hue, the app softens them for the background.
  static const colors = <int>[
    0xFF66BB6A, 0xFF9CCC65, 0xFF4DB6AC, 0xFF4DD0E1, 0xFF64B5F6, 0xFF7986CB,
    0xFF9575CD, 0xFFF06292, 0xFFE57373, 0xFFFFB74D, 0xFFFFD54F, 0xFFA1887F, 0xFF90A4AE,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in colors)
                Semantics(
                  button: true,
                  selected: c == value,
                  child: GestureDetector(
                    onTap: () => onChanged(c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(color: c == value ? cs.onSurface : Colors.transparent, width: 2.5),
                      ),
                      child: c == value ? const Icon(Icons.check_rounded, size: 18, color: Colors.white) : null,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
