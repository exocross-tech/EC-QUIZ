import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/file_saver.dart';

class QrCodeDialog extends StatelessWidget {
  final String joinCode;
  final String quizTitle;
  final String? pin;

  const QrCodeDialog({
    super.key,
    required this.joinCode,
    required this.quizTitle,
    this.pin,
  });

  static Future<void> show({
    required BuildContext context,
    required String joinCode,
    required String quizTitle,
    String? pin,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => QrCodeDialog(
        joinCode: joinCode,
        quizTitle: quizTitle,
        pin: pin,
      ),
    );
  }

  String _buildQrData() {
    try {
      final base = Uri.base;
      // If deployed on public web domain (not localhost), use current browser origin
      if (base.scheme == 'http' || base.scheme == 'https') {
        if (base.host != 'localhost' && base.host != '127.0.0.1') {
          return '${base.origin}/#/contests/join?code=$joinCode';
        }
      }
    } catch (_) {}

    // When running locally on PC or on native APK, use public Firebase hosting URL so mobile phones can join!
    if (AppConstants.webHostingUrl.isNotEmpty) {
      return '${AppConstants.webHostingUrl}/#/contests/join?code=$joinCode';
    }

    return joinCode;
  }

  Future<void> _downloadQrCode(BuildContext context, String qrData) async {
    try {
      final painter = QrPainter(
        data: qrData,
        version: QrVersions.auto,
        gapless: true,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: AppColors.primary,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black87,
        ),
      );
      final picData = await painter.toImageData(600, format: ui.ImageByteFormat.png);
      if (picData != null) {
        final bytes = picData.buffer.asUint8List();
        FileSaver.saveFile(bytes, 'contest_qr_$joinCode.png');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('QR Code saved as contest_qr_$joinCode.png!'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save QR code: $e'),
            backgroundColor: AppColors.gameRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPin = pin != null && pin!.isNotEmpty;
    final qrData = _buildQrData();
    final isUrl = qrData.startsWith('http://') || qrData.startsWith('https://');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    quizTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Scan hint
            Text(
              isUrl ? 'Scan with phone camera to join' : 'Scan to join contest',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            // QR Code Container with small download icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.primary,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black87,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Tooltip(
                      message: 'Download QR Code image',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _downloadQrCode(context, qrData),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.download_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Large Join Code
            Text(
              'OR ENTER CODE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              joinCode,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: AppColors.primary,
              ),
            ),

            if (hasPin) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'PIN: $pin',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Copy Action Buttons
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: joinCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Code $joinCode copied to clipboard!'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy Code'),
                ),
                if (isUrl)
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: qrData));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Join link copied to clipboard!'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.link, size: 18),
                    label: const Text('Copy Link'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
