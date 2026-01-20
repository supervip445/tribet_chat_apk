import 'package:flutter/material.dart';
import '../models/monastery.dart';
import '../services/public_service.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/sidebar.dart';

class MonasteriesScreen extends StatefulWidget {
  const MonasteriesScreen({super.key});

  @override
  State<MonasteriesScreen> createState() => _MonasteriesScreenState();
}

class _MonasteriesScreenState extends State<MonasteriesScreen> {
  final PublicService _publicService = PublicService();
  MonasteriesData? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchMonasteries();
  }

  Future<void> _fetchMonasteries() async {
    try {
      final response = await _publicService.getMonasteries();
      if (mounted) {
        setState(() {
          _data = MonasteriesData.fromJson(response['data']);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching top sellers: $e');
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
        appBar: const CustomAppBar(),
        drawer: const Sidebar(),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _data == null
            ? const Center(child: Text('No data available'))
            : LayoutBuilder(
                builder: (context, constraints) {
                  bool isSmallScreen = constraints.maxWidth < 600;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // title and subtitle
                        Center(
                          child: Column(
                            children: [
                              Text(
                                // _data!.title,
                                "Tri Chat\n ရောင်းအားအကောင်းဆုံး",
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 24 : 32,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              // const SizedBox(height: 8),
                              // Text(
                              //   _data!.subtitle,
                              //   style: TextStyle(
                              //     fontSize: isSmallScreen ? 14 : 18,
                              //     color: Colors.grey[600],
                              //   ),
                              //   textAlign: TextAlign.center,
                              // ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'TopSellers',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('No.')),
                                DataColumn(label: Text('Name')),
                                // DataColumn(label: Text('Price')),
                                // DataColumn(label: Text('Qty')),
                                DataColumn(label: Text('Total')),
                              ],
                              rows: _data!.monasteries.isNotEmpty
                                  ? _data!.monasteries.asMap().entries.map((
                                      entry,
                                    ) {
                                      final index = entry.key;
                                      final monastery = entry.value;
                                      return DataRow(
                                        cells: [
                                          DataCell(Text('${index + 1}')),
                                          DataCell(Text(monastery.name)),
                                          // DataCell(Text('${monastery.monks}')),
                                          // DataCell(
                                          //   Text('${monastery.novices}'),
                                          // ),
                                          DataCell(
                                            Text(
                                              '${monastery.total}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList()
                                  : [
                                      const DataRow(
                                        cells: [
                                          DataCell(Text('-')),
                                          DataCell(Text('No data available')),
                                          // DataCell(Text('-')),
                                          // DataCell(Text('-')),
                                          DataCell(Text('-')),
                                        ],
                                      ),
                                    ],
                            ),
                          ),
                        ),
                        // Buildings Table
                        if (_data!.buildings.isNotEmpty ||
                            _data!.buildings.isEmpty) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'TopSellers',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('No.')),
                                  // DataColumn(label: Text('Name')),
                                  DataColumn(label: Text('Price')),
                                  DataColumn(label: Text('Customers')),
                                  DataColumn(label: Text('Qty')),
                                  DataColumn(label: Text('Total')),
                                ],
                                rows: _data!.buildings.isNotEmpty
                                    ? _data!.buildings.asMap().entries.map((
                                        entry,
                                      ) {
                                        final index = entry.key;
                                        final building = entry.value;
                                        return DataRow(
                                          cells: [
                                            DataCell(Text('${index + 1}')),
                                            // DataCell(Text(building.name)),
                                            DataCell(
                                              Text(
                                                building.monasteryName ?? 'N/A',
                                              ),
                                            ),
                                            DataCell(Text('${building.monks}')),
                                            DataCell(
                                              Text('${building.novices}'),
                                            ),
                                            DataCell(
                                              Text(
                                                '${building.total}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.amber,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList()
                                    : [
                                        const DataRow(
                                          cells: [
                                            DataCell(Text('-')),
                                            // DataCell(Text('No data available')),
                                            DataCell(Text('-')),
                                            DataCell(Text('-')),
                                            DataCell(Text('-')),
                                            DataCell(Text('-')),
                                          ],
                                        ),
                                      ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
