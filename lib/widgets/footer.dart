import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;

    final quickLinks = [
      {'route': '/', 'label': 'Home'},
      {'route': '/posts', 'label': 'Posts'},
      {'route': '/dhammas', 'label': 'Dhamma Talks'},
      {'route': '/biographies', 'label': 'Biographies'},
      {'route': '/donations', 'label': 'Donations'},
      {'route': '/monasteries', 'label': 'Monasteries'},
    ];

    final resources = [
      {'route': '/posts', 'label': 'Latest Posts'},
      {'route': '/dhammas', 'label': 'Dhamma Talks'},
      {'route': '/biographies', 'label': 'Biographies'},
      {'route': '/donations', 'label': 'Support Us'},
      {'route': '/monasteries', 'label': 'Monasteries'},
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[900]!, Colors.grey[800]!],
        ),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // Main content grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 768;
              return isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAboutSection(context),
                        const SizedBox(height: 32),
                        _buildQuickLinks(context, quickLinks),
                        const SizedBox(height: 32),
                        _buildResources(context, resources),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildAboutSection(context)),
                        const SizedBox(width: 32),
                        Expanded(child: _buildQuickLinks(context, quickLinks)),
                        const SizedBox(width: 32),
                        Expanded(child: _buildResources(context, resources)),
                      ],
                    );
            },
          ),
          // Bottom bar
          const Divider(color: Colors.grey, thickness: 1, height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 768;
              return isMobile
                  ? Column(
                      children: [
                        Text(
                          '© $currentYear Tri Chat. All rights reserved.',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Tri Bet Team',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '•',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/login'),
                              child: Text(
                                'Admin Login',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '© $currentYear Tri Chat. All rights reserved.',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'Tri Bet Team',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '•',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 16),
                            InkWell(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/login'),
                              child: Text(
                                'Admin Login',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.amber[600]!, Colors.amber[800]!],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'ဓ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Tri Chat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          ' Tri Chat is a platform for the public to access the Online Games and for the community to connect with each other.',
          style: TextStyle(color: Colors.grey[300], fontSize: 14, height: 1.6),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildSocialIcon('📘', 'Facebook'),
            const SizedBox(width: 16),
            _buildSocialIcon('📺', 'YouTube'),
            const SizedBox(width: 16),
            _buildSocialIcon('📧', 'Contact'),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialIcon(String emoji, String label) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[700],
        shape: BoxShape.circle,
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
    );
  }

  Widget _buildQuickLinks(
    BuildContext context,
    List<Map<String, String>> links,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Links',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...links.map(
          (link) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                if (link['route'] != null) {
                  Navigator.pushNamed(context, link['route']!);
                }
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Text(
                  link['label']!,
                  style: TextStyle(color: Colors.grey[300], fontSize: 14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResources(
    BuildContext context,
    List<Map<String, String>> links,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resources',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...links.map(
          (link) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                if (link['route'] != null) {
                  Navigator.pushNamed(context, link['route']!);
                }
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Text(
                  link['label']!,
                  style: TextStyle(color: Colors.grey[300], fontSize: 14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
