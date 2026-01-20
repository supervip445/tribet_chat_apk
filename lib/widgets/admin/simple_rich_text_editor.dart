import 'package:flutter/material.dart';

class SimpleRichTextEditor extends StatefulWidget {
  final String value;
  final Function(String) onChange;
  final String placeholder;

  const SimpleRichTextEditor({
    super.key,
    required this.value,
    required this.onChange,
    this.placeholder = 'Enter content...',
  });

  @override
  State<SimpleRichTextEditor> createState() => _SimpleRichTextEditorState();
}

class _SimpleRichTextEditorState extends State<SimpleRichTextEditor> {
  late TextEditingController _controller;
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _stripHtml(widget.value));
    _controller.addListener(_updateHtml);
  }

  @override
  void didUpdateWidget(SimpleRichTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _getHtml()) {
      _controller.text = _stripHtml(widget.value);
    }
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  String _getHtml() {
    String text = _controller.text;
    // Apply formatting tags
    if (_isBold) text = '<strong>$text</strong>';
    if (_isItalic) text = '<em>$text</em>';
    if (_isUnderline) text = '<u>$text</u>';
    return text;
  }

  void _updateHtml() {
    widget.onChange(_getHtml());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Wrap(
              spacing: 8,
              children: [
                _buildToolbarButton(
                  icon: Icons.format_bold,
                  isActive: _isBold,
                  onPressed: () {
                    setState(() {
                      _isBold = !_isBold;
                      _updateHtml();
                    });
                  },
                ),
                _buildToolbarButton(
                  icon: Icons.format_italic,
                  isActive: _isItalic,
                  onPressed: () {
                    setState(() {
                      _isItalic = !_isItalic;
                      _updateHtml();
                    });
                  },
                ),
                _buildToolbarButton(
                  icon: Icons.format_underlined,
                  isActive: _isUnderline,
                  onPressed: () {
                    setState(() {
                      _isUnderline = !_isUnderline;
                      _updateHtml();
                    });
                  },
                ),
              ],
            ),
          ),
          // Editor
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              expands: true,
              decoration: InputDecoration(
                hintText: widget.placeholder,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
              style: TextStyle(
                fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
                fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
                decoration: _isUnderline ? TextDecoration.underline : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      color: isActive ? Colors.amber[600] : Colors.grey[700],
      style: IconButton.styleFrom(
        backgroundColor: isActive ? Colors.amber[50] : Colors.transparent,
      ),
    );
  }
}

