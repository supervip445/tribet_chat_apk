import 'package:dhamma_apk/widgets/admin/admin_pagination.dart';
import 'package:flutter/material.dart';
import '../../widgets/admin/admin_layout.dart';
import '../../widgets/admin/simple_rich_text_editor.dart';
import '../../widgets/admin/views_modal.dart';
import '../../services/admin/lesson_service.dart';
import '../../services/admin/class_service.dart';
import '../../services/admin/subject_service.dart';
import '../../services/admin/user_service.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class LessonsAdminScreen extends StatefulWidget {
  const LessonsAdminScreen({super.key});

  @override
  State<LessonsAdminScreen> createState() => _LessonsAdminScreenState();
}

class _LessonsAdminScreenState extends State<LessonsAdminScreen> {
  final AdminLessonService _lessonService = AdminLessonService();
  final AdminClassService _classService = AdminClassService();
  final AdminSubjectService _subjectService = AdminSubjectService();
  final AdminUserService _userService = AdminUserService();
  final _formKey = GlobalKey<FormState>();
  int _currentPage = 1;
  bool _hasMorePages = true;
  bool _isLoadingMore = false;
  List<dynamic> _lessons = [];
  List<dynamic> _classes = [];
  List<dynamic> _subjects = [];
  List<dynamic> _teachers = [];
  bool _loading = true;
  bool _showModal = false;
  bool _showDetailModal = false;
  bool _showViewsModal = false;
  Map<String, dynamic>? _viewingLesson;
  Map<String, dynamic>? _editingLesson;
  Map<String, dynamic>? _selectedLessonForViews;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedClassId = '';
  String _selectedSubjectId = '';
  String _selectedTeacherId = '';
  DateTime? _lessonDate;
  int _durationMinutes = 60;
  String _status = 'draft';
  List<File> _attachments = [];

  @override
  void initState() {
    super.initState();
    _fetchLessons();
    _fetchData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _fetchLessons({bool loadMore = false}) async {
    if (loadMore && !_hasMorePages) return;

    setState(() {
      loadMore ? _isLoadingMore = true : _loading = true;
    });

    try {
      final response = await _lessonService.getAll(_currentPage);
      final pagination = response['pagination'];

      final List<dynamic> fetchedLessons = response['data'] ?? [];

      setState(() {
        if (loadMore) {
          _lessons.addAll(fetchedLessons);
        } else {
          _lessons = fetchedLessons;
        }

        _hasMorePages = pagination['has_more_pages'] ?? false;
        _loading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _isLoadingMore = false;
      });
      _showError('Failed to load lessons');
    }
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final [classesRes, subjectsRes, teachersRes] = await Future.wait([
        _classService.getAll(),
        _subjectService.getAll(),
        _userService.getAll(),
      ]);
      setState(() {
        _classes = classesRes['data'] ?? [];
        _subjects = subjectsRes['data'] ?? [];
        _teachers = teachersRes['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showError('Error fetching data: $e');
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final formData = FormData();
      formData.append('title', _titleController.text.trim());

      // Handle nullable string fields - send null if empty
      final description = _descriptionController.text.trim();
      if (description.isNotEmpty) {
        formData.append('description', description);
      } else {
        formData.append('description', '');
      }

      final content = _contentController.text.trim();
      if (content.isNotEmpty) {
        formData.append('content', content);
      } else {
        formData.append('content', '');
      }

      // Ensure integer fields are sent as integers (validation ensures they're not empty)
      if (_selectedClassId.isNotEmpty) {
        formData.append('class_id', int.parse(_selectedClassId).toString());
      }
      if (_selectedSubjectId.isNotEmpty) {
        formData.append('subject_id', int.parse(_selectedSubjectId).toString());
      }
      if (_selectedTeacherId.isNotEmpty) {
        formData.append('teacher_id', int.parse(_selectedTeacherId).toString());
      }

      // Handle nullable date field
      if (_lessonDate != null) {
        formData.append(
          'lesson_date',
          _lessonDate!.toIso8601String().split('T')[0],
        );
      } else {
        formData.append('lesson_date', '');
      }

      // Handle nullable integer field - send only if > 0
      if (_durationMinutes > 0) {
        formData.append('duration_minutes', _durationMinutes.toString());
      } else {
        formData.append('duration_minutes', '');
      }

      formData.append('status', _status);

      // Append attachments
      for (int i = 0; i < _attachments.length; i++) {
        formData.append('attachments[$i]', _attachments[i]);
      }

      if (_editingLesson != null) {
        await _lessonService.update(_editingLesson!['id'], formData);
        _showSuccess('Lesson updated successfully');
      } else {
        await _lessonService.create(formData);
        _showSuccess('Lesson created successfully');
      }

      setState(() {
        _showModal = false;
      });
      _resetForm();
      _fetchData();
      _fetchLessons();
    } catch (e) {
      _showError('Error saving lesson: $e');
    }
  }

  void _handleView(Map<String, dynamic> lesson) {
    setState(() {
      _viewingLesson = lesson;
      _showDetailModal = true;
    });
  }

  void _handleEdit(Map<String, dynamic> lesson) {
    setState(() {
      _editingLesson = lesson;
      _titleController.text = lesson['title'] ?? '';
      _descriptionController.text = lesson['description'] ?? '';
      _contentController.text = lesson['content'] ?? '';
      _selectedClassId = lesson['class_id']?.toString() ?? '';
      _selectedSubjectId = lesson['subject_id']?.toString() ?? '';
      _selectedTeacherId = lesson['teacher_id']?.toString() ?? '';
      _lessonDate = lesson['lesson_date'] != null
          ? DateTime.parse(lesson['lesson_date'])
          : null;
      _durationMinutes = lesson['duration_minutes'] ?? 60;
      _status = lesson['status'] ?? 'draft';
      _attachments = [];
      _showModal = true;
    });
  }

  Future<void> _handleDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this lesson?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _lessonService.delete(id);
        _showSuccess('Lesson deleted successfully');
        _fetchData();
        _fetchLessons();
      } catch (e) {
        _showError('Error deleting lesson: $e');
      }
    }
  }

  Future<void> _pickAttachments() async {
    // For now, we'll use a simple file picker approach
    // In a real app, you'd use file_picker package
    // This is a placeholder - you'll need to implement file picking
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _contentController.clear();
    _selectedClassId = '';
    _selectedSubjectId = '';
    _selectedTeacherId = '';
    _lessonDate = null;
    _durationMinutes = 60;
    _status = 'draft';
    _attachments = [];
    _editingLesson = null;
    _showModal = false;
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _handleViewCountClick(Map<String, dynamic> lesson) {
    setState(() {
      _selectedLessonForViews = lesson;
      _showViewsModal = true;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lessonDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _lessonDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Lessons',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              _resetForm();
                              setState(() => _showModal = true);
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add New Lesson'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber[600],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withAlpha(25),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Title')),
                                  DataColumn(label: Text('Class')),
                                  DataColumn(label: Text('Subject')),
                                  DataColumn(label: Text('Teacher')),
                                  DataColumn(label: Text('Date')),
                                  DataColumn(label: Text('Status')),
                                  DataColumn(label: Text('Views')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: _lessons.map((lesson) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(lesson['title'] ?? '')),
                                      DataCell(
                                        Text(lesson['class']?['name'] ?? 'N/A'),
                                      ),
                                      DataCell(
                                        Text(
                                          lesson['subject']?['name'] ?? 'N/A',
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          lesson['teacher']?['name'] ?? 'N/A',
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          lesson['lesson_date'] != null
                                              ? DateFormat('yyyy-MM-dd').format(
                                                  DateTime.parse(
                                                    lesson['lesson_date'],
                                                  ),
                                                )
                                              : 'N/A',
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                lesson['status'] == 'published'
                                                ? Colors.green[100]
                                                : Colors.grey[200],
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            lesson['status'] ?? 'draft',
                                            style: TextStyle(
                                              color:
                                                  lesson['status'] ==
                                                      'published'
                                                  ? Colors.green[800]
                                                  : Colors.grey[800],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        InkWell(
                                          onTap: () =>
                                              _handleViewCountClick(lesson),
                                          child: Text(
                                            '${lesson['views_count'] ?? 0}',
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          children: [
                                            TextButton(
                                              onPressed: () =>
                                                  _handleView(lesson),
                                              child: const Text('View'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  _handleEdit(lesson),
                                              child: const Text('Edit'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  _handleDelete(lesson['id']),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.red,
                                              ),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Pagination outside scroll
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AdminPagination(
                            currentPage: _currentPage,
                            hasMorePages: _hasMorePages,
                            isLoading: _isLoadingMore,
                            onPrevious: () {
                              setState(() => _currentPage--);
                              _fetchLessons();
                            },
                            onNext: () {
                              setState(() => _currentPage++);
                              _fetchLessons();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
            // Modal
            if (_showModal) _buildModal(context),
            if (_showDetailModal && _viewingLesson != null)
              _buildDetailModal(context),
            // Views Modal
            ViewsModal(
              isOpen: _showViewsModal,
              onClose: () {
                setState(() {
                  _showViewsModal = false;
                  _selectedLessonForViews = null;
                });
              },
              viewableType: _selectedLessonForViews != null
                  ? 'App\\Models\\Lesson'
                  : null,
              viewableId: _selectedLessonForViews?['id'],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModal(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.95,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header with gradient
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    gradient: LinearGradient(
                      colors: [Colors.amber[50]!, Colors.amber[100]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _editingLesson != null
                                    ? Icons.edit
                                    : Icons.add_circle,
                                color: Colors.amber[800],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _editingLesson != null
                                    ? 'Edit Lesson'
                                    : 'Create New Lesson',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _editingLesson != null
                                ? 'Update lesson information'
                                : 'Fill in the details to create a new lesson',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _showModal = false),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Basic Information Section
                        _buildSection(
                          title: 'Basic Information',
                          icon: Icons.book,
                          color: Colors.grey[50]!,
                          borderColor: Colors.grey[200]!,
                          children: [
                            TextFormField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                labelText: 'Lesson Title',
                                hintText:
                                    'Enter the lesson title (e.g., Introduction to Buddhism)',
                                helperText: 'Required field',
                                helperMaxLines: 2,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(
                                  Icons.title,
                                  color: Colors.amber,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              style: const TextStyle(fontSize: 16),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a title';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                hintText:
                                    'Enter a brief description of the lesson (optional)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(
                                  Icons.description,
                                  color: Colors.amber,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              maxLines: 3,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Class & Subject Section
                        _buildSection(
                          title: 'Class & Subject Details',
                          icon: Icons.school,
                          color: Colors.blue[50]!,
                          borderColor: Colors.blue[200]!,
                          children: [
                            DropdownButtonFormField<String>(
                              isExpanded: true, // Important to prevent overflow
                              value: _selectedClassId.isEmpty
                                  ? null
                                  : _selectedClassId,
                              decoration: InputDecoration(
                                labelText: 'Class',
                                hintText: 'Select a class',
                                helperText: 'Required field',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(
                                  Icons.class_,
                                  color: Colors.blue,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              items: _classes.map((classItem) {
                                return DropdownMenuItem<String>(
                                  value: classItem['id'].toString(),
                                  child: Text(
                                    classItem['name'] ?? '',
                                    style: const TextStyle(fontSize: 16),
                                    overflow: TextOverflow
                                        .ellipsis, // Prevent text overflow
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) => setState(
                                () => _selectedClassId = value ?? '',
                              ),
                              validator: (value) => value?.isEmpty ?? true
                                  ? 'Please select a class'
                                  : null,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _selectedSubjectId.isEmpty
                                  ? null
                                  : _selectedSubjectId,
                              decoration: InputDecoration(
                                labelText: 'Subject',
                                hintText: 'Select a subject',
                                helperText: 'Required field',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(
                                  Icons.subject,
                                  color: Colors.blue,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              items: _subjects.map((subject) {
                                return DropdownMenuItem<String>(
                                  value: subject['id'].toString(),
                                  child: Text(
                                    subject['name'] ?? '',
                                    style: const TextStyle(fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) => setState(
                                () => _selectedSubjectId = value ?? '',
                              ),
                              validator: (value) => value?.isEmpty ?? true
                                  ? 'Please select a subject'
                                  : null,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _selectedTeacherId.isEmpty
                                  ? null
                                  : _selectedTeacherId,
                              decoration: InputDecoration(
                                labelText: 'Teacher (Admin)',
                                hintText: 'Select a teacher',
                                helperText:
                                    'Required field - Select an admin user as teacher',
                                helperMaxLines: 2,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(
                                  Icons.person,
                                  color: Colors.blue,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              items: _teachers.map((teacher) {
                                return DropdownMenuItem<String>(
                                  value: teacher['id'].toString(),
                                  child: Text(
                                    '${teacher['name']} (${teacher['email']})',
                                    style: const TextStyle(fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) => setState(
                                () => _selectedTeacherId = value ?? '',
                              ),
                              validator: (value) => value?.isEmpty ?? true
                                  ? 'Please select a teacher'
                                  : null,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Schedule Section
                        _buildSection(
                          title: 'Schedule & Duration',
                          icon: Icons.calendar_today,
                          color: Colors.green[50]!,
                          borderColor: Colors.green[200]!,
                          children: [
                            InkWell(
                              onTap: () => _selectDate(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey[400]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.date_range,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Lesson Date',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _lessonDate != null
                                                ? DateFormat(
                                                    'yyyy-MM-dd',
                                                  ).format(_lessonDate!)
                                                : 'Tap to select date',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: _lessonDate != null
                                                  ? Colors.black
                                                  : Colors.grey[400],
                                              fontWeight: _lessonDate != null
                                                  ? FontWeight.w500
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.calendar_today,
                                      color: Colors.green[700],
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Duration',
                                hintText: '60',
                                helperText: 'Duration in minutes',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(
                                  Icons.access_time,
                                  color: Colors.green,
                                ),
                                suffixText: 'min',
                                suffixStyle: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              initialValue: _durationMinutes.toString(),
                              style: const TextStyle(fontSize: 16),
                              onChanged: (value) {
                                _durationMinutes = int.tryParse(value) ?? 60;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Content Section
                        _buildSection(
                          title: 'Lesson Content',
                          icon: Icons.edit_note,
                          color: Colors.purple[50]!,
                          borderColor: Colors.purple[200]!,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Content',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Required',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Write the main lesson content using the rich text editor below',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: SizedBox(
                                height: 300,
                                child: SimpleRichTextEditor(
                                  value: _contentController.text,
                                  onChange: (value) {
                                    _contentController.text = value;
                                  },
                                  placeholder:
                                      'Start writing your lesson content here...\n\nYou can format text, add headings, lists, and more using the toolbar above.',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Attachments Section
                        _buildSection(
                          title: 'Attachments',
                          icon: Icons.attach_file,
                          color: Colors.orange[50]!,
                          borderColor: Colors.orange[200]!,
                          children: [
                            Text(
                              'Add files, documents, or resources related to this lesson (optional)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _pickAttachments,
                              icon: const Icon(Icons.add_circle_outline),
                              label: Text(
                                'Add Files${_attachments.isNotEmpty ? ' (${_attachments.length})' : ''}',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            if (_attachments.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              Text(
                                'Attached Files:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              ..._attachments.asMap().entries.map((entry) {
                                final file = entry.value;
                                final fileName = file.path.split('/').last;
                                final fileSize = (file.lengthSync() / 1024)
                                    .toStringAsFixed(2);
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.insert_drive_file,
                                        color: Colors.orange,
                                        size: 24,
                                      ),
                                    ),
                                    title: Text(
                                      fileName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      '$fileSize KB',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          _removeAttachment(entry.key),
                                      tooltip: 'Remove file',
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Status Section
                        _buildSection(
                          title: 'Publication Status',
                          icon: Icons.settings,
                          color: Colors.grey[50]!,
                          borderColor: Colors.grey[200]!,
                          children: [
                            Text(
                              'Choose when this lesson should be visible to public users',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _status,
                              decoration: InputDecoration(
                                labelText: 'Status',
                                helperText: 'Required field',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                prefixIcon: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (child, animation) =>
                                      ScaleTransition(
                                        scale: animation,
                                        child: child,
                                      ),
                                  child: _status == 'published'
                                      ? Icon(
                                          Icons.check_circle,
                                          key: ValueKey('published'),
                                          color: Colors.green,
                                        )
                                      : Icon(
                                          Icons.edit,
                                          key: ValueKey('draft'),
                                          color: Colors.grey,
                                        ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              items: [
                                _buildDropdownItem(
                                  'draft',
                                  Icons.edit,
                                  Colors.grey,
                                  'Draft',
                                  'Not visible to public',
                                ),
                                _buildDropdownItem(
                                  'published',
                                  Icons.check_circle,
                                  Colors.green,
                                  'Published',
                                  'Visible to public',
                                ),
                              ],
                              onChanged: (value) {
                                setState(() => _status = value ?? 'draft');
                              },
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              dropdownColor: Colors.white,
                              elevation: 4,
                              selectedItemBuilder: (context) {
                                return ['draft', 'published'].map((value) {
                                  // Customize the selected item text color here
                                  return Text(
                                    value == 'draft' ? 'Draft' : 'Published',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Footer with Submit Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _showModal = false);
                            _resetForm();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            _editingLesson != null ? 'Update Lesson' : 'Submit',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DropdownMenuItem<String> _buildDropdownItem(
    String value,
    IconData icon,
    Color iconColor,
    String title,
    String subtitle,
  ) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required Color borderColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.amber[800], size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailModal(BuildContext context) {
    final lesson = _viewingLesson!;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lesson Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _showDetailModal = false;
                      _viewingLesson = null;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Title', lesson['title'] ?? 'N/A'),
              if (lesson['description'] != null)
                _buildDetailRow('Description', lesson['description']),
              _buildDetailRow('Class', lesson['class']?['name'] ?? 'N/A'),
              _buildDetailRow('Subject', lesson['subject']?['name'] ?? 'N/A'),
              _buildDetailRow('Teacher', lesson['teacher']?['name'] ?? 'N/A'),
              _buildDetailRow(
                'Lesson Date',
                lesson['lesson_date'] != null
                    ? DateFormat(
                        'yyyy-MM-dd',
                      ).format(DateTime.parse(lesson['lesson_date']))
                    : 'N/A',
              ),
              _buildDetailRow(
                'Duration',
                '${lesson['duration_minutes'] ?? 60} minutes',
              ),
              _buildDetailRow('Status', lesson['status'] ?? 'draft'),
              if (lesson['content'] != null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Content',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    lesson['content'].replaceAll(RegExp(r'<[^>]*>'), ''),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
              if (lesson['attachments'] != null &&
                  (lesson['attachments'] as List).isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Attachments',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                ...(lesson['attachments'] as List).asMap().entries.map((entry) {
                  return ListTile(
                    title: Text('Attachment ${entry.key + 1}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () {
                        // Handle download
                      },
                    ),
                  );
                }),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showDetailModal = false;
                          _handleEdit(lesson);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[600],
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Edit Lesson'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        _showDetailModal = false;
                        _viewingLesson = null;
                      }),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
