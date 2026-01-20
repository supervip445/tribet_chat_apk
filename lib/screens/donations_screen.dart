import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/donation.dart';
import '../services/public_service.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/sidebar.dart';

class DonationsScreen extends StatefulWidget {
  const DonationsScreen({super.key});

  @override
  State<DonationsScreen> createState() => _DonationsScreenState();
}

class _DonationsScreenState extends State<DonationsScreen> {
  final PublicService _publicService = PublicService();
  final ScrollController _scrollController = ScrollController();

  List<Donation> _donations = [];

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMorePages = true;

  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _fetchDonations();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMorePages) {
      _fetchMoreDonations();
    }
  }

  Future<void> _fetchDonations() async {
    try {
      final response = await _publicService.getDonations(_currentPage);

      final donations = (response['data'] as List)
          .map((e) => Donation.fromJson(e))
          .toList();

      final pagination = response['pagination'];

      if (!mounted) return;

      setState(() {
        _donations = donations;
        _hasMorePages = pagination['has_more_pages'];
        _isInitialLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error fetching donations: $e');
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    }
  }

  Future<void> _fetchMoreDonations() async {
    if (!_hasMorePages) return;

    setState(() => _isLoadingMore = true);
    _currentPage++;

    try {
      final response = await _publicService.getDonations(_currentPage);

      final donations = (response['data'] as List)
          .map((e) => Donation.fromJson(e))
          .toList();

      final pagination = response['pagination'];

      if (!mounted) return;

      setState(() {
        _donations.addAll(donations);
        _hasMorePages = pagination['has_more_pages'];
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading more donations: $e');
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        drawer: Builder(
          builder: (context) {
            return const Sidebar();
          },
        ),
        backgroundColor: const Color(0xFFFFF8E1), // Light amber background
        body: _isInitialLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFB300)),
                ),
              )
            : _donations.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _donations.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _donations.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return _buildDonationCard(_donations[index]);
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No donations yet',
        style: TextStyle(color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildDonationCard(Donation donation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Could show donation details in a dialog or bottom sheet
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon/Status Indicator
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.amber[400]!, Colors.amber[600]!],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Donation Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  donation.donorName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF424242),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.category_outlined,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        donation.donationType,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.amber[200]!,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${_formatAmount(donation.amount)} MMK',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(donation.date),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
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

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
}
