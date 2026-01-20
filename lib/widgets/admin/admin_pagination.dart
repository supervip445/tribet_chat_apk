import 'package:flutter/material.dart';

class AdminPagination extends StatelessWidget {
  final int currentPage;
  final bool hasMorePages;
  final bool isLoading;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const AdminPagination({
    super.key,
    required this.currentPage,
    required this.hasMorePages,
    required this.isLoading,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: currentPage > 1 ? onPrevious : null,
            child: const Text('Previous'),
          ),
          const SizedBox(width: 12),
          Text(
            'Page $currentPage',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: hasMorePages && !isLoading ? onNext : null,
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Next'),
          ),
        ],
      ),
    );
  }
}
