import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RenderImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final double? rounded;
  final bool isCircle;
  final double? aspectRatio;

  const RenderImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.rounded,
    this.isCircle = false,
    this.aspectRatio,
  });

  bool get _isNetworkImage =>
      imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

  bool get _isAssetImage => imageUrl.startsWith('assets/');

  bool get _isEmpty => imageUrl.trim().isEmpty;

  Widget _wrapWithAspectRatio(Widget child) {
    if (height != null || aspectRatio == null) return child;
    return AspectRatio(
      aspectRatio: aspectRatio!,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = isCircle
        ? BorderRadius.circular((width ?? height ?? 0) / 2)
        : BorderRadius.circular(rounded ?? 8);

    Widget imageWidget;

    if (_isEmpty) {
      imageWidget = const ImageErrorWidget(
        message: 'No image available',
      );
    } else if (_isNetworkImage) {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => const ImageLoadingWidget(),
        errorWidget: (_, __, ___) => const ImageErrorWidget(
          message: 'Failed to load image',
        ),
      );
    } else if (_isAssetImage) {
      imageWidget = Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const ImageErrorWidget(
          message: 'Image not found',
        ),
      );
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => const ImageLoadingWidget(),
        errorWidget: (_, __, ___) => const ImageErrorWidget(
          message: 'Failed to load image',
        ),
      );
    }

    return _wrapWithAspectRatio(
      ClipRRect(
        borderRadius: borderRadius,
        child: SizedBox(
          width: width ?? double.infinity,
          height: height,
          child: imageWidget,
        ),
      ),
    );
  }
}

class ImageLoadingWidget extends StatelessWidget {
  const ImageLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 32,
        color: Colors.grey,
      ),
    );
  }
}

class ImageErrorWidget extends StatelessWidget {
  final String message;

  const ImageErrorWidget({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(12),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.broken_image_outlined,
            size: 36,
            color: Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
