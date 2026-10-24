import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'core.dart';

// =============================================================================
// Logos
// =============================================================================

/// CurVitae logo, cropped to the mark + wordmark (the artwork has wide margins).
class CurVitaeLogo extends StatelessWidget {
  const CurVitaeLogo({super.key, this.height = 90, this.radius = 18});

  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    const aspect = 1408 / 768;
    const heightFactor = 0.62;
    const widthFactor = 0.5;
    final imgH = height / heightFactor;
    final imgW = imgH * aspect;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        color: AppConfig.logoPaper,
        width: imgW * widthFactor,
        height: height,
        child: OverflowBox(
          alignment: Alignment.center,
          minWidth: imgW,
          maxWidth: imgW,
          minHeight: imgH,
          maxHeight: imgH,
          child: Image.asset(
            AppConfig.curvitaeLogo,
            width: imgW,
            height: imgH,
            fit: BoxFit.fill,
            errorBuilder: (_, _, _) => const Center(
              child: Icon(Icons.all_inclusive_rounded, size: 48),
            ),
          ),
        ),
      ),
    );
  }
}

/// Nyxara logo on its native dark tile.
class NyxaraLogo extends StatelessWidget {
  const NyxaraLogo({super.key, this.size = 72, this.glow = false});

  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: const Color(0xFF7C4DFF).withValues(alpha: 0.45),
                  blurRadius: 36,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.26),
        child: Image.asset(
          AppConfig.nyxaraLogo,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              const Icon(Icons.auto_awesome_rounded, color: Colors.white),
        ),
      ),
    );
  }
}

// =============================================================================
// Nyxara loading overlay (shown while the CV is being made)
// =============================================================================

class NyxaraLoadingOverlay extends StatefulWidget {
  const NyxaraLoadingOverlay({super.key, required this.status});

  final String status;

  @override
  State<NyxaraLoadingOverlay> createState() => _NyxaraLoadingOverlayState();
}

class _NyxaraLoadingOverlayState extends State<NyxaraLoadingOverlay>
    with SingleTickerProviderStateMixin {
  static const _tips = [
    'Tip: numbers make achievements memorable.',
    'Tip: keep your CV to one or two pages.',
    'Tip: mirror keywords from the job description.',
    'Tip: lead with your strongest, most recent work.',
  ];

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  Timer? _tipTimer;
  int _tip = 0;

  @override
  void initState() {
    super.initState();
    _tipTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() => _tip = (_tip + 1) % _tips.length);
    });
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      child: Material(
        color: cs.surface.withValues(alpha: 0.97),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.92, end: 1.06).animate(
                      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                    ),
                    child: const NyxaraLogo(size: 148, glow: true),
                  ),
                  const SizedBox(height: 32),
                  Text('Nyxara AI',
                      style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: Text(
                      widget.status,
                      key: ValueKey(widget.status),
                      textAlign: TextAlign.center,
                      style: tt.bodyLarge?.copyWith(color: cs.primary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 220,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: const LinearProgressIndicator(minHeight: 6),
                    ),
                  ),
                  const SizedBox(height: 28),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      _tips[_tip],
                      key: ValueKey(_tip),
                      textAlign: TextAlign.center,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Layout helpers
// =============================================================================

/// Centered, width-limited scrolling body used by every tab.
class TabBody extends StatelessWidget {
  const TabBody({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: children,
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: cs.primary),
            const SizedBox(width: 8),
          ],
          Text(text,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// =============================================================================
// Selectors
// =============================================================================

class StyleSelector extends StatelessWidget {
  const StyleSelector({super.key, required this.value, required this.onChanged});

  final CvStyle value;
  final ValueChanged<CvStyle> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CvStyle.values
          .map((s) => ChoiceChip(
                avatar: CircleAvatar(radius: 8, backgroundColor: s.color),
                label: Text(s.label),
                selected: s == value,
                onSelected: (_) => onChanged(s),
              ))
          .toList(),
    );
  }
}

class ToneSelector extends StatelessWidget {
  const ToneSelector({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      showSelectedIcon: false,
      segments: kTones
          .map((t) => ButtonSegment<String>(value: t, label: Text(t)))
          .toList(),
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

// =============================================================================
// File picker tiles
// =============================================================================

class FilePickTile extends StatelessWidget {
  const FilePickTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.file,
    required this.onTap,
    this.onClear,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final PlatformFile? file;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final picked = file != null;

    return Card.outlined(
      color: picked ? cs.primaryContainer.withValues(alpha: 0.45) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: picked ? cs.primary : cs.outlineVariant, width: picked ? 1.5 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: picked ? cs.primary : cs.secondaryContainer,
                child: Icon(picked ? Icons.check_rounded : icon,
                    color: picked ? cs.onPrimary : cs.onSecondaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(picked ? file!.name : title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      picked ? '${(file!.size / 1024).toStringAsFixed(0)} KB, tap to replace' : subtitle,
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (picked && onClear != null)
                IconButton(onPressed: onClear, icon: const Icon(Icons.close_rounded)),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Dynamic entry lists (experience / education / projects)
// =============================================================================

class EntryListController extends ChangeNotifier {
  EntryListController(this.fieldCount, {int initialRows = 0}) {
    for (var i = 0; i < initialRows; i++) {
      rows.add(_newRow());
    }
  }

  final int fieldCount;
  final List<List<TextEditingController>> rows = [];

  List<TextEditingController> _newRow() =>
      List.generate(fieldCount, (_) => TextEditingController());

  void add() {
    rows.add(_newRow());
    notifyListeners();
  }

  void removeAt(int index) {
    final removed = rows.removeAt(index);
    notifyListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final c in removed) {
        c.dispose();
      }
    });
  }

  /// Non-empty rows as trimmed strings.
  List<List<String>> values() => rows
      .map((r) => r.map((c) => c.text.trim()).toList())
      .where((r) => r.any((v) => v.isNotEmpty))
      .toList();

  @override
  void dispose() {
    for (final r in rows) {
      for (final c in r) {
        c.dispose();
      }
    }
    super.dispose();
  }
}

class EntryListSection extends StatelessWidget {
  const EntryListSection({
    super.key,
    required this.title,
    required this.icon,
    required this.addLabel,
    required this.emptyHint,
    required this.controller,
    required this.labels,
    this.multilineIndex,
  });

  final String title;
  final IconData icon;
  final String addLabel;
  final String emptyHint;
  final EntryListController controller;
  final List<String> labels;
  final int? multilineIndex;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionTitle(title, icon: icon),
            if (controller.rows.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(emptyHint,
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
              ),
            for (var i = 0; i < controller.rows.length; i++)
              Card.outlined(
                key: ObjectKey(controller.rows[i]),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: cs.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('${i + 1}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, color: cs.primary)),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Remove',
                            onPressed: () => controller.removeAt(i),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ),
                      for (var j = 0; j < labels.length; j++) ...[
                        TextField(
                          controller: controller.rows[i][j],
                          minLines: j == multilineIndex ? 3 : 1,
                          maxLines: j == multilineIndex ? 5 : 1,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(labelText: labels[j]),
                        ),
                        if (j != labels.length - 1) const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: controller.add,
                icon: const Icon(Icons.add_rounded),
                label: Text(addLabel),
              ),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// Nyxara AI info card (Home tab + bottom sheet)
// =============================================================================

class NyxaraCard extends StatelessWidget {
  const NyxaraCard({super.key});

  @override
  Widget build(BuildContext context) {
    const features = <(IconData, String)>[
      (Icons.verified_rounded, 'ATS-friendly CVs'),
      (Icons.track_changes_rounded, 'Tailored to your target role'),
      (Icons.edit_note_rounded, 'Sharp, recruiter-ready bullets'),
      (Icons.shield_rounded, 'Never invents facts'),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF0B0F2B), Color(0xFF1B1464), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const NyxaraLogo(size: 64, glow: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nyxara AI',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w800)),
                    const Text('The intelligence behind CurVitae',
                        style: TextStyle(color: Color(0xFFB3C5FF), fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Nyxara AI reads between the lines of your experience, turns rough notes into powerful achievements and shapes everything for the role you want, without inventing a single fact.',
            style: TextStyle(color: Colors.white, height: 1.45, fontSize: 13.5),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: features
                .map((f) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(f.$1, size: 15, color: const Color(0xFF9FB8FF)),
                          const SizedBox(width: 6),
                          Text(f.$2,
                              style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
