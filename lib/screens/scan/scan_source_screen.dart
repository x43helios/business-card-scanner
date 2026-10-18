import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/crash_log.dart';
import '../../services/scan_permissions.dart';
import 'preparing_screen.dart';

class ScanSourceScreen extends StatefulWidget {
  const ScanSourceScreen({super.key});

  @override
  State<ScanSourceScreen> createState() => _ScanSourceScreenState();
}

class _ScanSourceScreenState extends State<ScanSourceScreen> {
  final _picker = ImagePicker();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Android may kill MainActivity while the camera/gallery intent runs.
    WidgetsBinding.instance.addPostFrameCallback((_) => _recoverLostPick());
  }

  Future<void> _recoverLostPick() async {
    if (_busy) return;
    try {
      final response = await _picker.retrieveLostData();
      if (response.isEmpty) return;
      final file = response.file;
      if (file != null) {
        await CrashLog.log('retrieveLostData recovered: ${file.path}');
        _schedulePreparing(file.path);
        return;
      }
      if (response.exception != null && mounted) {
        _showError('${response.exception}');
      }
    } catch (e, st) {
      await CrashLog.log('retrieveLostData failed', e, st);
    }
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final denied = await ScanPermissions.ensureFor(source);
      if (denied != null) {
        if (!mounted) return;
        _showError(denied);
        setState(() => _busy = false);
        return;
      }

      await CrashLog.log('pickImage start source=$source');
      final x = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2000,
        maxHeight: 2000,
        requestFullMetadata: false,
      );
      if (x == null) {
        await CrashLog.log('pickImage cancelled');
        if (mounted) setState(() => _busy = false);
        return;
      }

      await CrashLog.log('pickImage returned path=${x.path}');
      // CRITICAL: leave the image_picker completion stack before any
      // navigation, file copy, or ML Kit. Activity resume is still settling.
      if (!mounted) return;
      setState(() => _busy = false);
      _schedulePreparing(x.path);
    } catch (e, st) {
      await CrashLog.log('pickImage failed', e, st);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      _showError('${l10n.errorGeneric}: $e');
      setState(() => _busy = false);
    }
  }

  /// Defer navigation to the next frame + microtask so we never open
  /// Preparing/OCR in the same call stack as the image_picker result.
  void _schedulePreparing(String rawPath) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() async {
        if (!mounted) return;
        try {
          await CrashLog.log('navigating to PreparingScreen');
          if (!mounted) return;
          await Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => PreparingScreen(rawImagePath: rawPath),
            ),
          );
        } catch (e, st) {
          await CrashLog.log('Preparing navigation failed', e, st);
          if (!mounted) return;
          final l10n = AppLocalizations.of(context);
          _showError('${l10n.errorGeneric}: $e');
        }
      });
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Creates a tiny placeholder JPEG named demo so stub OCR can run without
  /// Vision / ML Kit (Linux CI, emulators without models, etc.).
  Future<void> _runDemo() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, 'demo_business_card.jpg'));
      await file.writeAsBytes(const [
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
        0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
        0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
        0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
        0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
        0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
        0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
        0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
        0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x1F, 0x00, 0x00,
        0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
        0x09, 0x0A, 0x0B, 0xFF, 0xC4, 0x00, 0xB5, 0x10, 0x00, 0x02, 0x01, 0x03,
        0x03, 0x02, 0x04, 0x03, 0x05, 0x05, 0x04, 0x04, 0x00, 0x00, 0x01, 0x7D,
        0x01, 0x02, 0x03, 0x00, 0x04, 0x11, 0x05, 0x12, 0x21, 0x31, 0x41, 0x06,
        0x13, 0x51, 0x61, 0x07, 0x22, 0x71, 0x14, 0x32, 0x81, 0x91, 0xA1, 0x08,
        0x23, 0x42, 0xB1, 0xC1, 0x15, 0x52, 0xD1, 0xF0, 0x24, 0x33, 0x62, 0x72,
        0x82, 0x09, 0x0A, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x25, 0x26, 0x27, 0x28,
        0x29, 0x2A, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x43, 0x44, 0x45,
        0x46, 0x47, 0x48, 0x49, 0x4A, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59,
        0x5A, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6A, 0x73, 0x74, 0x75,
        0x76, 0x77, 0x78, 0x79, 0x7A, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89,
        0x8A, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9A, 0xA2, 0xA3,
        0xA4, 0xA5, 0xA6, 0xA7, 0xA8, 0xA9, 0xAA, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6,
        0xB7, 0xB8, 0xB9, 0xBA, 0xC2, 0xC3, 0xC4, 0xC5, 0xC6, 0xC7, 0xC8, 0xC9,
        0xCA, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD7, 0xD8, 0xD9, 0xDA, 0xE1, 0xE2,
        0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xE8, 0xE9, 0xEA, 0xF1, 0xF2, 0xF3, 0xF4,
        0xF5, 0xF6, 0xF7, 0xF8, 0xF9, 0xFA, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01,
        0x00, 0x00, 0x3F, 0x00, 0x7B, 0xDF, 0xFF, 0xD9,
      ]);
      if (!mounted) return;
      setState(() => _busy = false);
      _schedulePreparing(file.path);
    } catch (e, st) {
      await CrashLog.log('demo OCR failed', e, st);
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scan)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            elevation: 0,
            color: scheme.primaryContainer.withValues(alpha: 0.45),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: scheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.demoHint,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SourceTile(
            icon: Icons.photo_camera_outlined,
            title: l10n.takePhoto,
            subtitle: l10n.isZh ? '使用相機拍攝名片' : 'Capture with the camera',
            filled: true,
            onPressed: _busy ? null : () => _pick(ImageSource.camera),
          ),
          const SizedBox(height: 12),
          _SourceTile(
            icon: Icons.photo_library_outlined,
            title: l10n.pickGallery,
            subtitle: l10n.isZh ? '從相簿選取既有照片' : 'Pick an existing photo',
            filled: false,
            onPressed: _busy ? null : () => _pick(ImageSource.gallery),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: _busy ? null : _runDemo,
            icon: const Icon(Icons.play_circle_outline),
            label: Text(l10n.isZh ? '執行示範 OCR' : 'Run demo OCR'),
          ),
          if (_busy) ...[
            const SizedBox(height: 28),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.filled,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool filled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
    if (filled) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          alignment: Alignment.centerLeft,
        ),
        child: child,
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        alignment: Alignment.centerLeft,
      ),
      child: child,
    );
  }
}
