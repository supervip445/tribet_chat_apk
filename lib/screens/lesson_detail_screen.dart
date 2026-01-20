import 'package:dhamma_apk/util/date_format_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/lesson.dart';
import '../services/public_service.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/like_dislike.dart';
import '../widgets/comment_section.dart';
import '../widgets/sidebar.dart';

class LessonDetailScreen extends StatefulWidget {
  final int lessonId;

  const LessonDetailScreen({super.key, required this.lessonId});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  final PublicService _publicService = PublicService();
  Lesson? _lesson;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchLesson();
  }

  Future<void> _fetchLesson() async {
    try {
      final response = await _publicService.getLesson(widget.lessonId);
      debugPrint('Lesson API response: $response');
      debugPrint('Lesson data: ${response['data']}');

      final lessonData = response['data'];
      debugPrint('Lesson content value: ${lessonData['content']}');
      debugPrint('Lesson content type: ${lessonData['content'].runtimeType}');
      debugPrint('Lesson content is null: ${lessonData['content'] == null}');
      debugPrint(
        'Lesson content is empty: ${lessonData['content']?.toString().isEmpty ?? true}',
      );

      setState(() {
        _lesson = Lesson.fromJson(lessonData);
        debugPrint('Parsed lesson content: ${_lesson!.content}');
        debugPrint(
          'Parsed lesson content is null: ${_lesson!.content == null}',
        );
        debugPrint(
          'Parsed lesson content is empty: ${_lesson!.content?.isEmpty ?? true}',
        );
        _loading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Error fetching lesson: $e');
      debugPrint('Stack trace: $stackTrace');
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
                : _lesson == null
                ? const Center(child: Text('Lesson not found'))
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      if (_lesson!.class_ != null)
                                        Chip(
                                          label: Text(_lesson!.class_!.name),
                                          backgroundColor: Colors.blue[100],
                                        ),
                                      if (_lesson!.subject != null)
                                        Chip(
                                          label: Text(_lesson!.subject!.name),
                                          backgroundColor: Colors.green[100],
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  if (_lesson!.viewsCount != null) ...[
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.visibility,
                                          size: 18,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_lesson!.viewsCount}',
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
                                  if (_lesson!.lessonDate != null)
                                    Text(
                                      DateFormatUtil.formatDate(
                                        _lesson!.lessonDate!,
                                      ),
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _lesson!.title,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_lesson!.description != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _lesson!.description!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              GridView.count(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 3, // adjust for chip height
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  if (_lesson!.teacher != null)
                                    _buildInfoChip(
                                      'Teacher',
                                      _lesson!.teacher!.name,
                                      Icons.person,
                                    ),
                                  if (_lesson!.durationMinutes != null)
                                    _buildInfoChip(
                                      'Duration',
                                      '${_lesson!.durationMinutes} minutes',
                                      Icons.access_time,
                                    ),
                                  if (_lesson!.class_ != null)
                                    _buildInfoChip(
                                      'Class',
                                      _lesson!.class_!.name,
                                      Icons.school,
                                    ),
                                  if (_lesson!.subject != null)
                                    _buildInfoChip(
                                      'Subject',
                                      _lesson!.subject!.name,
                                      Icons.book,
                                    ),
                                ],
                              ),

                              const SizedBox(height: 16),
                              LikeDislike(
                                likeableType: 'App\\Models\\Lesson',
                                likeableId: _lesson!.id,
                              ),
                              // Always show content section, even if empty
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Icon(
                                    Icons.article,
                                    color: Colors.amber[800],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Lesson Content',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child:
                                    _lesson!.content != null &&
                                        _lesson!.content!.isNotEmpty
                                    ? Html(
                                        data: _lesson!.content!,
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
                                              MediaQuery.of(
                                                    context,
                                                  ).size.width -
                                                  96,
                                            ),
                                          ),
                                          "th": Style(
                                            backgroundColor:
                                                Colors.grey.shade200,
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
                                              MediaQuery.of(
                                                    context,
                                                  ).size.width -
                                                  96,
                                            ),
                                            margin: Margins.symmetric(
                                              vertical: 8,
                                            ),
                                            display: Display.block,
                                          ),
                                          "iframe": Style(
                                            width: Width(
                                              MediaQuery.of(
                                                    context,
                                                  ).size.width -
                                                  96,
                                            ),
                                            height: Height(300),
                                            margin: Margins.symmetric(
                                              vertical: 8,
                                            ),
                                            display: Display.block,
                                          ),
                                          "p": Style(
                                            margin: Margins.only(bottom: 8),
                                            lineHeight: LineHeight(1.6),
                                          ),
                                          "ul": Style(
                                            margin: Margins.only(
                                              left: 16,
                                              bottom: 8,
                                            ),
                                          ),
                                          "ol": Style(
                                            margin: Margins.only(
                                              left: 16,
                                              bottom: 8,
                                            ),
                                          ),
                                          "li": Style(
                                            margin: Margins.only(bottom: 4),
                                          ),
                                          "h1": Style(
                                            fontSize: FontSize(28),
                                            fontWeight: FontWeight.bold,
                                            margin: Margins.only(
                                              bottom: 12,
                                              top: 16,
                                            ),
                                          ),
                                          "h2": Style(
                                            fontSize: FontSize(24),
                                            fontWeight: FontWeight.bold,
                                            margin: Margins.only(
                                              bottom: 10,
                                              top: 14,
                                            ),
                                          ),
                                          "h3": Style(
                                            fontSize: FontSize(20),
                                            fontWeight: FontWeight.bold,
                                            margin: Margins.only(
                                              bottom: 8,
                                              top: 12,
                                            ),
                                          ),
                                          "h4": Style(
                                            fontSize: FontSize(18),
                                            fontWeight: FontWeight.bold,
                                            margin: Margins.only(
                                              bottom: 6,
                                              top: 10,
                                            ),
                                          ),
                                          "h5": Style(
                                            fontSize: FontSize(16),
                                            fontWeight: FontWeight.bold,
                                            margin: Margins.only(
                                              bottom: 4,
                                              top: 8,
                                            ),
                                          ),
                                          "h6": Style(
                                            fontSize: FontSize(14),
                                            fontWeight: FontWeight.bold,
                                            margin: Margins.only(
                                              bottom: 4,
                                              top: 8,
                                            ),
                                          ),
                                        },
                                      )
                                    : Container(
                                        padding: const EdgeInsets.all(24),
                                        child: Center(
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.description_outlined,
                                                size: 48,
                                                color: Colors.grey[400],
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'No content available for this lesson',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                              ),
                              if (_lesson!.attachments != null &&
                                  _lesson!.attachments!.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                const Text(
                                  'Attachments',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ..._lesson!.attachments!.asMap().entries.map((
                                  entry,
                                ) {
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.attach_file,
                                        color: Colors.blue,
                                      ),
                                      title: Text(
                                        'Attachment ${entry.key + 1}',
                                      ),
                                      trailing: const Icon(Icons.download),
                                      onTap: () {
                                        // Handle download
                                      },
                                    ),
                                  );
                                }),
                              ],
                              const SizedBox(height: 24),
                              CommentSection(
                                commentableType: 'App\\Models\\Lesson',
                                commentableId: _lesson!.id,
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

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.amber[800]),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.amber[900],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

List<Lesson> dummyLessons = [
  Lesson(
    id: 1,
    title: 'Introduction to Buddhism',
    description:
        'Learn the fundamentals of Buddhism, its history, and principles.',
    content: 'Full content here...',
    classId: 1,
    subjectId: 1,
    teacherId: 1,
    lessonDate: '2025-12-26',
    durationMinutes: 45,
    status: 'published',
    attachments: ['https://example.com/file1.pdf'],
    class_: SchoolClass(id: 1, name: 'Class 1', code: 'C1'),
    subject: Subject(id: 1, name: 'Buddhism', code: 'BD101'),
    teacher: Teacher(
      id: 1,
      name: 'Venerable Thura',
      email: 'thura@example.com',
    ),
    viewsCount: 120,
    createdAt: '2025-12-20T10:00:00Z',
    updatedAt: '2025-12-22T12:00:00Z',
  ),
  Lesson(
    id: 2,
    title: 'Mindfulness Meditation',
    description: 'A practical guide to mindfulness meditation techniques.',
    content: 'Full content here...',
    classId: 2,
    subjectId: 2,
    teacherId: 2,
    lessonDate: '2025-12-27',
    durationMinutes: 30,
    status: 'published',
    attachments: ['https://example.com/file2.pdf'],
    class_: SchoolClass(id: 2, name: 'Class 2', code: 'C2'),
    subject: Subject(id: 2, name: 'Meditation', code: 'MD201'),
    teacher: Teacher(id: 2, name: 'Sayadaw U Nyan', email: 'nyan@example.com'),
    viewsCount: 85,
    createdAt: '2025-12-21T09:00:00Z',
    updatedAt: '2025-12-23T11:00:00Z',
  ),
  Lesson(
    id: 3,
    title: 'The Four Noble Truths',
    description: 'Understanding the core teachings of the Buddha.',
    content: 'Full content here...',
    classId: 1,
    subjectId: 1,
    teacherId: 3,
    lessonDate: '2025-12-28',
    durationMinutes: 50,
    status: 'published',
    attachments: [],
    class_: SchoolClass(id: 1, name: 'Class 1', code: 'C1'),
    subject: Subject(id: 1, name: 'Buddhism', code: 'BD101'),
    teacher: Teacher(id: 3, name: 'Ven. Aung', email: 'aung@example.com'),
    viewsCount: 100,
    createdAt: '2025-12-22T08:30:00Z',
    updatedAt: '2025-12-24T10:30:00Z',
  ),
  Lesson(
    id: 4,
    title: 'Compassion in Daily Life',
    description: 'Practical tips to apply compassion in everyday interactions.',
    content: 'Full content here...',
    classId: 3,
    subjectId: 3,
    teacherId: 4,
    lessonDate: '2025-12-29',
    durationMinutes: 40,
    status: 'published',
    attachments: null,
    class_: SchoolClass(id: 3, name: 'Class 3', code: 'C3'),
    subject: Subject(id: 3, name: 'Ethics', code: 'ET301'),
    teacher: Teacher(id: 4, name: 'U Thant', email: 'thant@example.com'),
    viewsCount: 70,
    createdAt: '2025-12-23T07:45:00Z',
    updatedAt: '2025-12-25T09:15:00Z',
  ),
];
