import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../components/location_summary_card.dart';
import '../../providers/location_provider.dart';
import '../../models/location_summary.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  DateTime _selectedDate = DateTime.now();
  List<LocationSummary> _summaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSummaries();
  }

  Future<void> _loadSummaries() async {
    setState(() {
      _isLoading = true;
    });

    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    final summaries = await locationProvider.getLocationSummary(_selectedDate);

    setState(() {
      _summaries = summaries;
      _isLoading = false;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadSummaries();
    }
  }

  // Calculate total time spent across all locations
  Duration _getTotalTimeSpent() {
    Duration total = Duration.zero;
    for (var summary in _summaries) {
      total += summary.timeSpent;
    }
    return total;
  }

  // Format duration as hours, minutes and seconds
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return '$hours h $minutes min $seconds sec';
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE, MMMM d, y').format(_selectedDate);
    final totalTime = _getTotalTimeSpent();

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Location Summary'), elevation: 0),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Change Date'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),
          ),
          if (!_isLoading && _summaries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Total: ${_formatDuration(totalTime)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'Time Distribution:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      // Progress indicators for locations
                      ...buildLocationProgressBars(totalTime),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _summaries.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No location data for ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: _summaries.length,
                      itemBuilder: (context, index) {
                        return LocationSummaryCard(summary: _summaries[index]);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  List<Widget> buildLocationProgressBars(Duration totalTime) {
    // Sort summaries by time spent (descending)
    final sortedSummaries = [..._summaries];
    sortedSummaries.sort((a, b) => b.timeSpent.compareTo(a.timeSpent));

    // Different colors for different locations
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];

    return sortedSummaries.asMap().entries.map((entry) {
      final index = entry.key;
      final summary = entry.value;
      final percentage =
          totalTime.inSeconds > 0
              ? summary.timeSpent.inSeconds / totalTime.inSeconds
              : 0.0;
      final color = colors[index % colors.length];

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    summary.locationName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatDuration(summary.timeSpent),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 2),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }).toList();
  }
}
