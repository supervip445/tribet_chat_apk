import 'package:dhamma_apk/models/post.dart';
import 'package:dhamma_apk/util/date_format_util.dart';
import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final contentPreview = _stripHtmlTags(post.content);
    final previewText = contentPreview.length > 150
        ? '${contentPreview.substring(0, 150)}...'
        : contentPreview;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () =>
                Navigator.pushNamed(context, '/post-detail', arguments: post.id),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageSection(constraints.maxWidth),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle(),
                      const SizedBox(height: 8),
                      _buildPreviewText(previewText),
                      const SizedBox(height: 12),
                      _buildCategoryDateRow(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageSection(double width) {
    final imageHeight = width * 0.5; // maintain 2:1 ratio

    if (post.image != null && post.image!.isNotEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: SizedBox(
          height: imageHeight,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                post.image!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _imagePlaceholder(imageHeight);
                },
                errorBuilder: (context, error, stackTrace) {
                  return _imageError(imageHeight);
                },
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return _imagePlaceholder(imageHeight, fallbackIcon: Icons.article);
    }
  }

  Widget _imagePlaceholder(double height, {IconData fallbackIcon = Icons.article}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        gradient: LinearGradient(
          colors: [Colors.orange.shade100, Colors.orange.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(fallbackIcon, size: 48, color: Colors.orange.shade700),
      ),
    );
  }

  Widget _imageError(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        color: Colors.grey.shade300,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.broken_image, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Image not available', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      post.title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF424242),
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildPreviewText(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildCategoryDateRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            post.category?.name ?? 'Uncategorized',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          DateFormatUtil.formatDate(post.createdAt),
          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
        ),
      ],
    );
  }
}

String _stripHtmlTags(String html) {
  return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
}
