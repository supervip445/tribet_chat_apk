import 'package:flutter/material.dart';
import '../models/biography.dart';
import '../services/public_service.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/sidebar.dart';

class BiographiesScreen extends StatefulWidget {
  const BiographiesScreen({super.key});

  @override
  State<BiographiesScreen> createState() => _BiographiesScreenState();
}

class _BiographiesScreenState extends State<BiographiesScreen> {
  final PublicService _publicService = PublicService();
  List<Biography> _biographies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchBiographies();
  }

  Future<void> _fetchBiographies() async {
    try {
      final response = await _publicService.getBiographies();
      setState(() {
        _biographies = (response['data'] as List)
            .map((item) => Biography.fromJson(item))
            .toList();
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching biographies: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount;
    if (screenWidth >= 1200) {
      crossAxisCount = 4;
    } else if (screenWidth >= 900) {
      crossAxisCount = 3;
    } else if (screenWidth >= 600) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 1;
    }

    final double cardWidth =
        (screenWidth - 16 * (crossAxisCount + 1)) / crossAxisCount;
    final double cardHeight = 100;
    final double aspectRatio = cardWidth / cardHeight;

    Future<bool> onWillPop() async {
      Navigator.canPop(context)
          ? Navigator.pop(context)
          : Navigator.pushNamedAndRemoveUntil(
              context,
              "/home",
              (route) => false,
            );
      return false;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        onWillPop();
      },
      child: Scaffold(
        appBar: CustomAppBar(),
        drawer: const Sidebar(),
        body: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _biographies.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.account_circle,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Promotions available at the moment.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Check back later for new Promotions.',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Promotions',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Promotions for the public to access the Online Games and for the community to connect with each other',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 24),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _biographies.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: aspectRatio,
                                ),
                            itemBuilder: (context, index) {
                              final biography = _biographies[index];
                              return _buildBiographyCard(biography);
                            },
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiographyCard(Biography biography) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        splashColor: null,
        onTap: () => Navigator.pushNamed(
          context,
          "/biography-detail",
          arguments: biography.id,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (biography.image != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  biography.image!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.person),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    biography.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (biography.birthYear != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      biography.birthYear!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
