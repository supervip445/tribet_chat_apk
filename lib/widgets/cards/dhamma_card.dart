import 'package:dhamma_apk/models/dhamma.dart';
import 'package:dhamma_apk/util/date_format_util.dart';
import 'package:flutter/material.dart';

class DhammaCard extends StatelessWidget {
  final Dhamma dhamma;

  const DhammaCard({super.key, required this.dhamma});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pushNamed(context, "/dhamma-detail", arguments: dhamma.id);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // image section
            _buildImageSection(),

            // content section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // title
                  Text(
                    dhamma.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF424242),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // speaker and date row
                  Row(
                    children: [
                      Flexible(child: _buildSpeaker()),
                      const SizedBox(width: 24),
                      _buildDate(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // image and fallback
  Widget _buildImageSection() {
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: dhamma.image != null && dhamma.image!.isNotEmpty
          ? Image.network(
              dhamma.image!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _loadingPlaceholder();
              },
              errorBuilder: (context, error, stackTrace) {
                return _fallbackImage();
              },
            )
          : _fallbackImage(),
    );
  }

  Widget _loadingPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFB300)),
        ),
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFE0B2), Color(0xFFFFCC80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.volume_up, size: 36, color: Color(0xFFEF6C00)),
            SizedBox(height: 4),
            Text(
              "Dhamma Talk",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFEF6C00),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // speaker
  Widget _buildSpeaker() {
    return Row(
      children: [
        Icon(Icons.person, size: 18, color: Colors.orange[800]),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            dhamma.speaker,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange[900],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // date
  Widget _buildDate() {
    return Row(
      children: [
        Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          DateFormatUtil.formatDate(dhamma.date),
          style: TextStyle(fontSize: 11, color: Colors.grey[700]),
        ),
      ],
    );
  }
}
