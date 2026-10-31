import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/theme/appearance_settings.dart';
import 'package:hiddify/features/common/general_pref_tiles.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Appearance settings: theme mode, main colour, connection button colours, corner radius, font size.
/// Every change is applied to the whole app straight away.
class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final text = t.pages.settings.appearance;
    final appearance = ref.watch(appearanceProvider);
    final notifier = ref.read(appearanceProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(text.title),
        actions: [
          IconButton(
            tooltip: text.reset,
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: appearance.isDefault ? null : notifier.resetAll,
          ),
        ],
      ),
      body: ListView(
        children: [
          const ThemeModePrefTile(),
          _ColorTile(
            icon: Icons.palette_rounded,
            title: text.seedColor,
            color: appearance.seedColor,
            shownWhenDefault: scheme.primary,
            defaultLabel: text.seedColorAuto,
            hexLabel: text.hexLabel,
            invalidLabel: text.invalidHex,
            applyLabel: text.apply,
            onChanged: notifier.setSeedColor,
          ),
          _ColorTile(
            icon: Icons.power_settings_new_rounded,
            title: text.idleButtonColor,
            color: appearance.idleButtonColor,
            shownWhenDefault: AppearanceSettings.defaultIdle,
            defaultLabel: text.defaultColor,
            hexLabel: text.hexLabel,
            invalidLabel: text.invalidHex,
            applyLabel: text.apply,
            onChanged: notifier.setIdleButtonColor,
          ),
          _ColorTile(
            icon: Icons.power_settings_new_rounded,
            title: text.connectedButtonColor,
            color: appearance.connectedButtonColor,
            shownWhenDefault: AppearanceSettings.defaultConnected,
            defaultLabel: text.defaultColor,
            hexLabel: text.hexLabel,
            invalidLabel: text.invalidHex,
            applyLabel: text.apply,
            onChanged: notifier.setConnectedButtonColor,
          ),
          _SliderTile(
            icon: Icons.rounded_corner_rounded,
            title: text.cornerRadius,
            value: appearance.cornerRadius ?? 12,
            min: AppearanceSettings.minRadius,
            max: AppearanceSettings.maxRadius,
            divisions: 32,
            valueLabel: appearance.cornerRadius == null ? text.defaultColor : appearance.cornerRadius!.round().toString(),
            onCommit: notifier.setCornerRadius,
            onReset: appearance.cornerRadius == null ? null : () => notifier.setCornerRadius(null),
          ),
          _SliderTile(
            icon: Icons.format_size_rounded,
            title: text.fontSize,
            value: appearance.fontScale,
            min: AppearanceSettings.minFontScale,
            max: AppearanceSettings.maxFontScale,
            divisions: 12,
            valueLabel: '${(appearance.fontScale * 100).round()}%',
            onCommit: notifier.setFontScale,
            onReset: appearance.fontScale == 1.0 ? null : () => notifier.setFontScale(1.0),
          ),
        ],
      ),
    );
  }
}

/// What the colour dialog hands back: a colour, or `null` for "back to default".
class _ColorChoice {
  const _ColorChoice(this.color);
  final Color? color;
}

class _ColorTile extends StatelessWidget {
  const _ColorTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.shownWhenDefault,
    required this.defaultLabel,
    required this.hexLabel,
    required this.invalidLabel,
    required this.applyLabel,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final Color? color;
  final Color shownWhenDefault;
  final String defaultLabel;
  final String hexLabel;
  final String invalidLabel;
  final String applyLabel;
  final Future<void> Function(Color? color) onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(color == null ? defaultLabel : colorToHex(color!)),
      trailing: CircleAvatar(
        radius: 14,
        backgroundColor: color ?? shownWhenDefault,
      ),
      onTap: () async {
        final result = await showDialog<_ColorChoice>(
          context: context,
          builder: (_) => _ColorDialog(
            title: title,
            initial: color,
            defaultLabel: defaultLabel,
            hexLabel: hexLabel,
            invalidLabel: invalidLabel,
            applyLabel: applyLabel,
          ),
        );
        if (result != null) await onChanged(result.color);
      },
    );
  }
}

class _ColorDialog extends StatefulWidget {
  const _ColorDialog({
    required this.title,
    required this.initial,
    required this.defaultLabel,
    required this.hexLabel,
    required this.invalidLabel,
    required this.applyLabel,
  });

  final String title;
  final Color? initial;
  final String defaultLabel;
  final String hexLabel;
  final String invalidLabel;
  final String applyLabel;

  @override
  State<_ColorDialog> createState() => _ColorDialogState();
}

class _ColorDialogState extends State<_ColorDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial == null ? '' : colorToHex(widget.initial!),
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    final parsed = parseHexColor(_controller.text);
    if (parsed == null) {
      setState(() => _error = widget.invalidLabel);
      return;
    }
    Navigator.of(context).pop(_ColorChoice(parsed));
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.initial?.toARGB32();
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final preset in appearancePresetColors)
                  _Swatch(
                    color: preset,
                    selected: preset.toARGB32() == selected,
                    onTap: () => Navigator.of(context).pop(_ColorChoice(preset)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[#0-9a-fA-F]')),
                LengthLimitingTextInputFormatter(7),
              ],
              decoration: InputDecoration(labelText: widget.hexLabel, errorText: _error),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _apply(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(const _ColorChoice(null)),
          child: Text(widget.defaultLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(onPressed: _apply, child: Text(widget.applyLabel)),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.selected, required this.onTap});

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 26,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
            width: 3,
          ),
        ),
        child: selected
            ? Icon(Icons.check_rounded, size: 20, color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white)
            : null,
      ),
    );
  }
}

/// A slider that follows the finger locally and saves (and so re-themes the app) only on release,
/// so dragging stays smooth.
class _SliderTile extends StatefulWidget {
  const _SliderTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueLabel,
    required this.onCommit,
    required this.onReset,
  });

  final IconData icon;
  final String title;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String valueLabel;
  final Future<void> Function(double value) onCommit;
  final VoidCallback? onReset;

  @override
  State<_SliderTile> createState() => _SliderTileState();
}

class _SliderTileState extends State<_SliderTile> {
  late double _value = widget.value;

  @override
  void didUpdateWidget(covariant _SliderTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(widget.icon),
      title: Text(widget.title),
      subtitle: Slider(
        value: _value.clamp(widget.min, widget.max).toDouble(),
        min: widget.min,
        max: widget.max,
        divisions: widget.divisions,
        onChanged: (value) => setState(() => _value = value),
        onChangeEnd: (value) => widget.onCommit(value),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.valueLabel),
          if (widget.onReset != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: widget.onReset,
            ),
        ],
      ),
    );
  }
}
