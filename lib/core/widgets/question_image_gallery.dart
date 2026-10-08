import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/image_utils.dart';

/// Anti-flicker, performant image gallery for live quiz questions.
/// Supports single image display and multi-image carousel.
/// Uses static memory caching and [gaplessPlayback] to eliminate screen blink
/// during 1-second timer rebuilds.
class QuestionImageGallery extends StatefulWidget {
  final List<String> imagesBase64;
  final double maxHeight;
  final bool enableFullscreen;

  const QuestionImageGallery({
    super.key,
    required this.imagesBase64,
    this.maxHeight = 180,
    this.enableFullscreen = true,
  });

  // In-memory cache to prevent re-decoding Base64 on every timer tick / setState
  static final Map<String, Uint8List> _bytesCache = {};

  static Uint8List? getCachedBytes(String base64) {
    if (_bytesCache.containsKey(base64)) {
      return _bytesCache[base64];
    }
    final bytes = ImageUtils.base64ToBytes(base64);
    if (bytes != null) {
      // Keep cache size bounded (max 50 images in memory)
      if (_bytesCache.length > 50) {
        _bytesCache.remove(_bytesCache.keys.first);
      }
      _bytesCache[base64] = bytes;
    }
    return bytes;
  }

  @override
  State<QuestionImageGallery> createState() => _QuestionImageGalleryState();
}

class _QuestionImageGalleryState extends State<QuestionImageGallery> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showFullscreen(BuildContext context, Uint8List bytes, int index) {
    if (!widget.enableFullscreen) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 3.5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
            if (widget.imagesBase64.length > 1)
              Positioned(
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Image ${index + 1} of ${widget.imagesBase64.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final validImages = widget.imagesBase64
        .where((b) => b.trim().isNotEmpty)
        .toList();

    if (validImages.isEmpty) {
      return const SizedBox.shrink();
    }

    // 1. Single Image View (Zero Flicker)
    if (validImages.length == 1) {
      final bytes = QuestionImageGallery.getCachedBytes(validImages.first);
      if (bytes == null) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 8),
        child: GestureDetector(
          onTap: () => _showFullscreen(context, bytes, 0),
          child: Container(
            constraints: BoxConstraints(maxHeight: widget.maxHeight),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.black.withValues(alpha: 0.04),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(
                bytes,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) => child,
              ),
            ),
          ),
        ),
      );
    }

    // 2. Multi-Image Carousel View
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: widget.maxHeight,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: validImages.length,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  itemBuilder: (context, index) {
                    final bytes = QuestionImageGallery.getCachedBytes(validImages[index]);
                    if (bytes == null) return const SizedBox.shrink();

                    return GestureDetector(
                      onTap: () => _showFullscreen(context, bytes, index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.black.withValues(alpha: 0.04),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.memory(
                            bytes,
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                            filterQuality: FilterQuality.medium,
                            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) => child,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Left chevron button
              if (_currentPage > 0)
                Positioned(
                  left: 6,
                  child: IconButton.filledTonal(
                    iconSize: 18,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),

              // Right chevron button
              if (_currentPage < validImages.length - 1)
                Positioned(
                  right: 6,
                  child: IconButton.filledTonal(
                    iconSize: 18,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),

              // Floating page badge
              Positioned(
                top: 8,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_currentPage + 1}/${validImages.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Indicator dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              validImages.length,
              (dotIndex) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentPage == dotIndex ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: _currentPage == dotIndex
                      ? AppColors.primary
                      : Colors.grey.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
