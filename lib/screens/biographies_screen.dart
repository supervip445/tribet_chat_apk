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

  Future<bool> onWillPop() async {
    Navigator.canPop(context)
        ? Navigator.pop(context)
        : Navigator.pushNamedAndRemoveUntil(context, "/home", (route) => false);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        onWillPop();
      },
      child: Scaffold(
        appBar: CustomAppBar(),
        drawer: const Sidebar(),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _biographies.isEmpty
                ? _buildEmptyState()
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
                        LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount;
                            if (constraints.maxWidth >= 1200) {
                              crossAxisCount = 4;
                            } else if (constraints.maxWidth >= 900) {
                              crossAxisCount = 3;
                            } else if (constraints.maxWidth >= 600) {
                              crossAxisCount = 2;
                            } else {
                              crossAxisCount = 1;
                            }

                            const double spacing = 16;
                            final double itemWidth =
                                (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                                    crossAxisCount;

                            return Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: _biographies.map((bio) {
                                return SizedBox(
                                  width: itemWidth,
                                  child: _buildBiographyCard(bio),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new Promotions.',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
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
        splashColor: Colors.grey.withOpacity(0.2),
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
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    biography.image!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.person,
                          size: 64,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
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
                  const SizedBox(height: 4),
                  Text(
                    biography.sanghaDhamma ?? "",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
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
