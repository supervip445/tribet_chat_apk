import 'package:dhamma_apk/util/date_format_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/dhamma.dart';
import '../services/public_service.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/like_dislike.dart';
import '../widgets/comment_section.dart';
import '../widgets/sidebar.dart';

class DhammaDetailScreen extends StatefulWidget {
  final int dhammaId;

  const DhammaDetailScreen({super.key, required this.dhammaId});

  @override
  State<DhammaDetailScreen> createState() => _DhammaDetailScreenState();
}

class _DhammaDetailScreenState extends State<DhammaDetailScreen> {
  final PublicService _publicService = PublicService();
  Dhamma? _dhamma;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchDhamma();
  }

  Future<void> _fetchDhamma() async {
    try {
      final response = await _publicService.getDhamma(widget.dhammaId);
      setState(() {
        _dhamma = Dhamma.fromJson(response['data']);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching dhamma: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      drawer: Builder(
        builder: (context) {
          return const Sidebar();
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _dhamma == null
                ? const Center(child: Text('Dhamma Talk not found'))
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        if (_dhamma!.image != null)
                          Image.network(
                            _dhamma!.image!,
                            width: double.infinity,
                            height: 300,
                            fit: BoxFit.cover,
                          ),
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Chip(
                                    label: Text('Dhamma Talk'),
                                    backgroundColor: Colors.amber,
                                  ),
                                  Row(
                                    children: [
                                      if (_dhamma!.viewsCount != null) ...[
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.visibility,
                                              size: 18,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${_dhamma!.viewsCount}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'views',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 16),
                                      ],
                                      Text(
                                        DateFormatUtil.formatDate(_dhamma!.date),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Speaker: ${_dhamma!.speaker}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _dhamma!.title,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              LikeDislike(
                                likeableType: 'App\\Models\\Dhamma',
                                likeableId: _dhamma!.id,
                              ),
                              const SizedBox(height: 24),
                              Html(
                                data: _dhamma!.content,
                                style: {
                                  "table": Style(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                    backgroundColor: Colors.white,
                                    margin: Margins.all(8),
                                    display: Display.block,
                                    width: Width(
                                      MediaQuery.of(context).size.width - 96,
                                    ),
                                  ),
                                  "th": Style(
                                    backgroundColor: Colors.grey.shade200,
                                    padding: HtmlPaddings.all(12),
                                    fontWeight: FontWeight.bold,
                                    textAlign: TextAlign.center,
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                      width: 1,
                                    ),
                                    whiteSpace: WhiteSpace.normal,
                                  ),
                                  "td": Style(
                                    padding: HtmlPaddings.all(12),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                    textAlign: TextAlign.left,
                                    whiteSpace: WhiteSpace.normal,
                                  ),
                                  "tr": Style(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  "img": Style(
                                    width: Width(
                                      MediaQuery.of(context).size.width - 96,
                                    ),
                                    margin: Margins.symmetric(vertical: 8),
                                    display: Display.block,
                                  ),
                                  "p": Style(
                                    margin: Margins.only(bottom: 8),
                                    lineHeight: LineHeight(1.6),
                                  ),
                                  "ul": Style(
                                    margin: Margins.only(left: 16, bottom: 8),
                                  ),
                                  "ol": Style(
                                    margin: Margins.only(left: 16, bottom: 8),
                                  ),
                                  "li": Style(margin: Margins.only(bottom: 4)),
                                  "h1": Style(
                                    fontSize: FontSize(28),
                                    fontWeight: FontWeight.bold,
                                    margin: Margins.only(bottom: 12, top: 16),
                                  ),
                                  "h2": Style(
                                    fontSize: FontSize(24),
                                    fontWeight: FontWeight.bold,
                                    margin: Margins.only(bottom: 10, top: 14),
                                  ),
                                  "h3": Style(
                                    fontSize: FontSize(20),
                                    fontWeight: FontWeight.bold,
                                    margin: Margins.only(bottom: 8, top: 12),
                                  ),
                                  "h4": Style(
                                    fontSize: FontSize(18),
                                    fontWeight: FontWeight.bold,
                                    margin: Margins.only(bottom: 6, top: 10),
                                  ),
                                  "h5": Style(
                                    fontSize: FontSize(16),
                                    fontWeight: FontWeight.bold,
                                    margin: Margins.only(bottom: 4, top: 8),
                                  ),
                                  "h6": Style(
                                    fontSize: FontSize(14),
                                    fontWeight: FontWeight.bold,
                                    margin: Margins.only(bottom: 4, top: 8),
                                  ),
                                },
                              ),
                              const SizedBox(height: 24),
                              CommentSection(
                                commentableType: 'App\\Models\\Dhamma',
                                commentableId: _dhamma!.id,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
