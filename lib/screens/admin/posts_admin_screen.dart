import 'package:dhamma_apk/widgets/admin/admin_pagination.dart';
import 'package:flutter/material.dart';
import '../../widgets/admin/admin_layout.dart';
import '../../widgets/admin/simple_rich_text_editor.dart';
import '../../widgets/admin/image_uploader.dart';
import '../../widgets/admin/views_modal.dart';
import '../../services/admin/post_service.dart';
import '../../services/admin/category_service.dart';
import '../../services/api_service.dart';
import 'dart:io';

class PostsAdminScreen extends StatefulWidget {
  const PostsAdminScreen({super.key});

  @override
  State<PostsAdminScreen> createState() => _PostsAdminScreenState();
}

class _PostsAdminScreenState extends State<PostsAdminScreen> {
  final AdminPostService _postService = AdminPostService();
  final AdminCategoryService _categoryService = AdminCategoryService();
  final _formKey = GlobalKey<FormState>();
  int _currentPage = 1;
  bool _hasMorePages = true;
  bool _isLoadingMore = false;

  List<dynamic> _posts = [];
  List<dynamic> _categories = [];
  bool _loading = true;
  bool _showModal = false;
  bool _showViewsModal = false;
  Map<String, dynamic>? _editingPost;
  Map<String, dynamic>? _selectedPostForViews;

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedCategoryId = '';
  String _status = 'published';
  List<File> _images = [];

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _fetchPosts({bool loadMore = false}) async {
    if (loadMore && !_hasMorePages) return;

    setState(() {
      loadMore ? _isLoadingMore = true : _loading = true;
    });

    try {
      final postsRes = await _postService.getAll(_currentPage);
      final pagination = postsRes['pagination'];

      if (_categories.isEmpty) {
        final categoriesRes = await _categoryService.getAll();
        _categories = categoriesRes['data'] ?? [];
      }

      setState(() {
        _posts = postsRes['data'] ?? [];
        _hasMorePages = pagination['has_more_pages'] ?? false;
        _loading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _isLoadingMore = false;
      });
      _showError('Failed to load posts');
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final formData = FormData();
      formData.append('title', _titleController.text);
      formData.append('content', _contentController.text);
      formData.append('category_id', _selectedCategoryId);
      formData.append('status', _status);

      // Append images as array
      for (int i = 0; i < _images.length; i++) {
        formData.append('images[$i]', _images[i]);
      }

      if (_editingPost != null) {
        await _postService.update(_editingPost!['id'], formData);
        _showSuccess('Post updated successfully');
      } else {
        await _postService.create(formData);
        _showSuccess('Post created successfully');
      }

      _resetForm();
    } catch (e) {
      _showError('Error saving post: $e');
    }
  }

  void _handleEdit(Map<String, dynamic> post) {
    setState(() {
      _editingPost = post;
      _titleController.text = post['title'] ?? '';
      _contentController.text = post['content'] ?? '';
      _selectedCategoryId = post['category_id']?.toString() ?? '';
      _status = post['status'] ?? 'published';
      _images = [];
      _showModal = true;
    });
  }

  Future<void> _handleDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _postService.delete(id);
        _showSuccess('Post deleted successfully');
        _fetchPosts();
      } catch (e) {
        _showError('Error deleting post: $e');
      }
    }
  }

  void _resetForm() {
    _titleController.clear();
    _contentController.clear();
    _selectedCategoryId = '';
    _status = 'published';
    _images = [];
    _editingPost = null;
    _showModal = false;
    _currentPage = 1;
    _fetchPosts();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _handleViewCountClick(Map<String, dynamic> post) {
    setState(() {
      _selectedPostForViews = post;
      _showViewsModal = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Posts',
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
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
                      label: const Text('Add New Post'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: _posts.isEmpty
                              ? const Center(child: Text('No posts found'))
                              : Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Scrollbar(
                                    thumbVisibility: true,
                                    child: SingleChildScrollView(
                                      // ✅ VERTICAL SCROLL
                                      child: SingleChildScrollView(
                                        // ✅ HORIZONTAL SCROLL
                                        scrollDirection: Axis.horizontal,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minWidth: MediaQuery.of(
                                              context,
                                            ).size.width,
                                          ),
                                          child: DataTable(
                                            columnSpacing: 24,
                                            columns: const [
                                              DataColumn(label: Text('Title')),
                                              DataColumn(
                                                label: Text('Category'),
                                              ),
                                              DataColumn(label: Text('Status')),
                                              DataColumn(label: Text('Views')),
                                              DataColumn(
                                                label: Text('Actions'),
                                              ),
                                            ],
                                            rows: _posts.map((post) {
                                              return DataRow(
                                                cells: [
                                                  DataCell(
                                                    SizedBox(
                                                      width: 180,
                                                      child: Text(
                                                        post['title'] ?? '',
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      post['category']?['name'] ??
                                                          'N/A',
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      post['status'] ?? 'draft',
                                                    ),
                                                  ),
                                                  DataCell(
                                                    InkWell(
                                                      onTap: () =>
                                                          _handleViewCountClick(
                                                            post,
                                                          ),
                                                      child: Text(
                                                        '${post['views_count'] ?? 0}',
                                                        style: const TextStyle(
                                                          color: Colors.blue,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Row(
                                                      children: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              _handleEdit(post),
                                                          child: const Text(
                                                            'Edit',
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () =>
                                                              _handleDelete(
                                                                post['id'],
                                                              ),
                                                          child: const Text(
                                                            'Delete',
                                                            style: TextStyle(
                                                              color: Colors.red,
                                                            ),
                                                          ),
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
                                ),
                        ),

                        // pagination stay outside of the scroll
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AdminPagination(
                              currentPage: _currentPage,
                              hasMorePages: _hasMorePages,
                              isLoading: _isLoadingMore,
                              onPrevious: () {
                                setState(() => _currentPage--);
                                _fetchPosts();
                              },
                              onNext: () {
                                setState(() => _currentPage++);
                                _fetchPosts();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Create/Edit Modal
          if (_showModal)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.95,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // wrap content
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _editingPost != null
                                    ? 'Edit Post'
                                    : 'Create New Post',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () =>
                                    setState(() => _showModal = false),
                              ),
                            ],
                          ),
                        ),
                        // Form Content
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _titleController,
                                decoration: const InputDecoration(
                                  labelText: 'Title *',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a title';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedCategoryId.isEmpty
                                    ? null
                                    : _selectedCategoryId,
                                decoration: const InputDecoration(
                                  labelText: 'Category *',
                                  border: OutlineInputBorder(),
                                ),
                                items: _categories.map((cat) {
                                  return DropdownMenuItem(
                                    value: cat['id'].toString(),
                                    child: Text(cat['name'] ?? ''),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(
                                    () => _selectedCategoryId = value ?? '',
                                  );
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select a category';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              const Text('Content *'),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 300,
                                child: SimpleRichTextEditor(
                                  value: _contentController.text,
                                  onChange: (value) {
                                    _contentController.text = value;
                                  },
                                  placeholder:
                                      'Write your post content here...',
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text('Images'),
                              const SizedBox(height: 8),
                              ImageUploader(
                                images: _images,
                                onImagesChange: (images) {
                                  setState(() => _images = images);
                                },
                                maxImages: 10,
                                enableCrop: false,
                              ),
                              if (_editingPost != null &&
                                  _editingPost!['image'] != null &&
                                  _images.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Current Image:'),
                                      const SizedBox(height: 8),
                                      Image.network(
                                        _editingPost!['image'],
                                        height: 128,
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _status,
                                decoration: const InputDecoration(
                                  labelText: 'Status',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'draft',
                                    child: Text('Draft'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'published',
                                    child: Text('Published'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(
                                    () => _status = value ?? 'published',
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        // Footer
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() => _showModal = false);
                                    _resetForm();
                                  },
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
                                  ),
                                  child: Text(
                                    _editingPost != null ? 'Update' : 'Create',
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
            ),
          // Views Modal
          if (_showViewsModal)
            Center(
              child: SingleChildScrollView(
                child: ViewsModal(
                  isOpen: _showViewsModal,
                  onClose: () {
                    setState(() {
                      _showViewsModal = false;
                      _selectedPostForViews = null;
                    });
                  },
                  viewableType: _selectedPostForViews != null
                      ? 'App\\Models\\Post'
                      : null,
                  viewableId: _selectedPostForViews?['id'],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
