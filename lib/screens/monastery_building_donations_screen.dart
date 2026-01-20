import 'package:dhamma_apk/util/date_format_util.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/public_service.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/sidebar.dart';

class MonasteryBuildingDonationsScreen extends StatefulWidget {
  const MonasteryBuildingDonationsScreen({super.key});

  @override
  State<MonasteryBuildingDonationsScreen> createState() =>
      _MonasteryBuildingDonationsScreenState();
}

class _MonasteryBuildingDonationsScreenState
    extends State<MonasteryBuildingDonationsScreen> {
  final PublicService _publicService = PublicService();
  List<dynamic> _donations = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDonations();
  }

  Future<void> _fetchDonations() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final response = await _publicService.getMonasteryBuildingDonations();
      debugPrint('Building Donations API Response: $response');

      dynamic donationsData;
      if (response is Map) {
        donationsData = response['data'] ?? [];
      } else {
        donationsData = response;
      }

      if (mounted) {
        setState(() {
          if (donationsData is List) {
            _donations = donationsData;
          } else {
            _donations = [];
          }
          _loading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching building donations: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage =
              'Failed to load building donations. Please try again later.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _donations.fold<double>(0, (sum, donation) {
      final amount = donation['amount'] ?? donation['donation_amount'] ?? 0;
      if (amount is num) return sum + amount.toDouble();
      if (amount is String) return sum + (double.tryParse(amount) ?? 0);
      return sum;
    });

    Future<bool> onWillPop() async {
      Navigator.canPop(context) ? Navigator.pop(context) : Navigator.pushNamedAndRemoveUntil(context, "/home", (route) => false);
      return false;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        onWillPop();
      },
      child: Scaffold(
        appBar: const CustomAppBar(),
        drawer: const Sidebar(),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchDonations,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monastery Building Donations',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Contributions for monastery building projects',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
      
                    // Responsive Summary Cards
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return _buildSummaryCards(
                          constraints.maxWidth,
                          totalAmount,
                        );
                      },
                    ),
      
                    const SizedBox(height: 24),
      
                    // Donations Table
                    if (_donations.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'No building donations available at the moment.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      Card(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Donor Name')),
                              DataColumn(label: Text('Amount')),
                              DataColumn(label: Text('Purpose')),
                              DataColumn(label: Text('Date')),
                            ],
                            rows: _donations.map((donation) {
                              final donorName =
                                  donation['donor_name'] ??
                                  donation['donorName'] ??
                                  donation['name'] ??
                                  '';
      
                              final amount =
                                  donation['amount'] ??
                                  donation['donation_amount'] ??
                                  donation['donationAmount'] ??
                                  0;
                              final amountValue = amount is num
                                  ? amount.toDouble()
                                  : (amount is String
                                        ? (double.tryParse(amount) ?? 0)
                                        : 0);
      
                              final purpose =
                                  donation['donation_purpose'] ??
                                  donation['donationPurpose'] ??
                                  donation['purpose'] ??
                                  '';
      
                              String dateStr = 'N/A';
                              try {
                                final dateValue =
                                    donation['date'] ??
                                    donation['created_at'] ??
                                    donation['createdAt'];
                                if (dateValue != null) {
                                  final parsedDate = DateTime.parse(
                                    dateValue.toString(),
                                  );
                                  dateStr = DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(parsedDate);
                                }
                              } catch (e) {
                                debugPrint('Error parsing date: $e');
                              }
      
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      donorName.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      '${amountValue.toStringAsFixed(0)} MMK',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(purpose.toString())),
                                  DataCell(
                                    Text(DateFormatUtil.formatDate(dateStr)),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  // Responsive Summary Cards
  Widget _buildSummaryCards(double maxWidth, double totalAmount) {
    final isSmallScreen = maxWidth < 400;
    final cardWidth = isSmallScreen ? maxWidth : (maxWidth - 16) / 2;

    final cards = [
      _buildSummaryCard(
        'Total Donations',
        '${totalAmount.toStringAsFixed(0)} MMK',
        Icons.attach_money,
        cardWidth,
      ),
      _buildSummaryCard(
        'Total Donors',
        '${_donations.length}',
        Icons.people,
        cardWidth,
      ),
    ];

    return Wrap(spacing: 8, runSpacing: 8, children: cards);
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    double width,
  ) {
    return SizedBox(
      width: width,
      child: Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    // ✅ Expanded is fine here
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(icon, size: 32, color: Colors.amber),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
