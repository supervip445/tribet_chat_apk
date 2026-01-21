import 'package:dhamma_apk/util/date_format_util.dart';
import 'package:dhamma_apk/widgets/render_video.dart';
import 'package:dhamma_apk/widgets/render_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/post.dart';
import '../services/public_service.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/like_dislike.dart';
import '../widgets/comment_section.dart';
import '../widgets/sidebar.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final PublicService _publicService = PublicService();
  Post? _post;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPost();
  }

  Future<void> _fetchPost() async {
    try {
      final response = await _publicService.getPost(widget.postId);
      setState(() {
        _post = Post.fromJson(response['data']);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching post: $e');
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
      drawer: const Sidebar(),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _post == null
                    ? const Center(child: Text('Post not found'))
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            // Render image if exists
                            if (_post!.image != null)
                              RenderImage(
                                imageUrl: _post!.image!,
                                aspectRatio: 3 / 2,
                                rounded: 0,
                              ),
                            // Render video if exists
                            if (_post!.video != null)
                              RenderVideo(
                                videoUrl: _post!.video!,
                                aspectRatio: 16 / 9,
                              ),
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Category, Views, Date
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Chip(
                                        label: Text(
                                          _post!.category?.name ??
                                              'Uncategorized',
                                        ),
                                        backgroundColor: Colors.amber[100],
                                      ),
                                      Row(
                                        children: [
                                          if (_post!.viewsCount != null) ...[
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.visibility,
                                                  size: 18,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${_post!.viewsCount}',
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
                                            DateFormatUtil.formatDate(
                                              _post!.createdAt,
                                            ),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Title
                                  Text(
                                    _post!.title,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Like/Dislike
                                  LikeDislike(
                                    likeableType: 'App\\Models\\Post',
                                    likeableId: _post!.id,
                                  ),
                                  const SizedBox(height: 24),
                                  // HTML Content
                                  Html(
                                    data: _post!.content,
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
                                  // Comments
                                  CommentSection(
                                    commentableType: 'App\\Models\\Post',
                                    commentableId: _post!.id,
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
