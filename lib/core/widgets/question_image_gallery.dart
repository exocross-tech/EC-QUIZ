import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/image_utils.dart';

/// Anti-flicker, performant multi-image mosaic grid for live quiz questions.
/// Displays:
/// - 1 image: 1 full-width container
/// - 2 images: 1 row with 2 side-by-side images
/// - 3 images: Row 1 has 2 images side-by-side, Row 2 has the 3rd image centered
/// - 4 images: 2x2 grid (2 in row 1, 2 in row 2)
/// Uses static memory caching and [gaplessPlayback] to eliminate screen blink
/// during 1-second countdown rebuilds.
class QuestionImageGallery extends StatelessWidget {
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
      if (_bytesCache.length > 50) {
        _bytesCache.remove(_bytesCache.keys.first);
      }
      _bytesCache[base64] = bytes;
    }
    return bytes;
  }

  void _showFullscreen(BuildContext context, List<String> validImages, int initialIndex) {
    if (!enableFullscreen) return;

    showDialog(
      context: context,
      builder: (ctx) => _FullscreenGalleryDialog(
        imagesBase64: validImages,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final validImages = imagesBase64
        .where((b) => b.trim().isNotEmpty)
        .toList();

    if (validImages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: _buildGridContent(context, validImages),
    );
  }

  Widget _buildGridContent(BuildContext context, List<String> validImages) {
    final count = validImages.length;

    // Case 1: Single image
    if (count == 1) {
      final bytes = getCachedBytes(validImages.first);
      if (bytes == null) return const SizedBox.shrink();

      return Center(
        child: GestureDetector(
          onTap: () => _showFullscreen(context, validImages, 0),
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            width: double.infinity,
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

    // Case 2: 2 images in a single row
    if (count == 2) {
      return Row(
        children: [
          _buildTile(context, validImages, 0, height: 125),
          const SizedBox(width: 8),
          _buildTile(context, validImages, 1, height: 125),
        ],
      );
    }

    // Case 3: 3 images (Row 1 has 2 images, Row 2 has 3rd centered)
    if (count == 3) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildTile(context, validImages, 0, height: 105),
              const SizedBox(width: 8),
              _buildTile(context, validImages, 1, height: 105),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Spacer(flex: 1),
              _buildTile(context, validImages, 2, height: 105, flex: 2),
              const Spacer(flex: 1),
            ],
          ),
        ],
      );
    }

    // Case 4: 4 images (2x2 grid)
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _buildTile(context, validImages, 0, height: 95),
            const SizedBox(width: 8),
            _buildTile(context, validImages, 1, height: 95),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildTile(context, validImages, 2, height: 95),
            const SizedBox(width: 8),
            _buildTile(context, validImages, 3, height: 95),
          ],
        ),
      ],
    );
  }

  Widget _buildTile(
    BuildContext context,
    List<String> validImages,
    int index, {
    required double height,
    int flex = 1,
  }) {
    final bytes = getCachedBytes(validImages[index]);
    if (bytes == null) {
      return Expanded(flex: flex, child: const SizedBox.shrink());
    }

    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () => _showFullscreen(context, validImages, index),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.black.withValues(alpha: 0.04),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) => child,
                ),
              ),
              Positioned(
                bottom: 4,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullscreenGalleryDialog extends StatefulWidget {
  final List<String> imagesBase64;
  final int initialIndex;

  const _FullscreenGalleryDialog({
    required this.imagesBase64,
    required this.initialIndex,
  });

  @override
  State<_FullscreenGalleryDialog> createState() => _FullscreenGalleryDialogState();
}

class _FullscreenGalleryDialogState extends State<_FullscreenGalleryDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black87,
      insetPadding: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imagesBase64.length,
            onPageChanged: (page) => setState(() => _currentIndex = page),
            itemBuilder: (context, index) {
              final bytes = QuestionImageGallery.getCachedBytes(widget.imagesBase64[index]);
              if (bytes == null) return const SizedBox.shrink();

              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 3.5,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      bytes,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          if (widget.imagesBase64.length > 1) ...[
            if (_currentIndex > 0)
              Positioned(
                left: 8,
                child: IconButton.filledTonal(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            if (_currentIndex < widget.imagesBase64.length - 1)
              Positioned(
                right: 8,
                child: IconButton.filledTonal(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            Positioned(
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1} of ${widget.imagesBase64.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
