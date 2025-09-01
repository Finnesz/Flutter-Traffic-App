// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  // Ensure that the Flutter bindings are initialized before calling native code.
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

// The root widget for your application.
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartTrafficMalabon',
      debugShowCheckedModeBanner: false, // Remove debug banner
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.cyan,
        scaffoldBackgroundColor:
            const Color(0xFF192A31), // New background color
        cardColor: const Color(0xFF293949), // New card color
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF192A31), // New app bar background
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFFFFFFF)), // White text
          bodyMedium: TextStyle(color: Color(0xFFB0BEC5)), // Light Gray text
          headlineSmall:
              TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold),
        ),
        chipTheme: const ChipThemeData(
          backgroundColor: Color(0xFF586A80), // Unselected chip color
          selectedColor: Color(0xFF00C8FA), // Selected chip color
          labelStyle: TextStyle(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C8FA), // New button color
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const C4TrafficPredictionScreen(),
    );
  }
}

// A stateful widget to fetch and display C4 road traffic data.
class C4TrafficPredictionScreen extends StatefulWidget {
  const C4TrafficPredictionScreen({Key? key}) : super(key: key);

  @override
  State<C4TrafficPredictionScreen> createState() =>
      _C4TrafficPredictionScreenState();
}

class _C4TrafficPredictionScreenState extends State<C4TrafficPredictionScreen> {
  // Futures to hold the data fetched from JSON files.
  late Future<Map<String, dynamic>> _trafficRecommendationsFuture;
  late Future<Map<String, dynamic>> _forecastDataFuture;
  late Future<Map<String, dynamic>> _predictionSummaryFuture;

  // Current selected time period
  String _selectedPeriod = 'hourly';

  // Store the actual data timestamp
  DateTime? _lastDataUpdate;

  // For custom prediction request
  DateTime? _selectedDateTime;
  Map<String, dynamic>? _customPredictionResult;
  bool _isLoadingCustomPrediction = false;

  // Available time periods
  final List<String> _timePeriods = ['hourly', 'daily', 'weekly', 'monthly'];

  @override
  void initState() {
    super.initState();
    // Initialize the futures when the widget is created.
    _refreshData();
  }

  // Method to refresh all data
  void _refreshData() {
    setState(() {
      _trafficRecommendationsFuture = _loadTrafficRecommendations();
      _forecastDataFuture = _loadForecastData();
      _predictionSummaryFuture = _loadPredictionSummary();
    });
  }

  // Asynchronously loads traffic recommendations from FastAPI
  Future<Map<String, dynamic>> _loadTrafficRecommendations() async {
    try {
      final url = Uri.parse(
          'https://ravishing-education-production.up.railway.app/api/dashboard/user/end-user-traffic-recommendations');
      final response = await http.get(
        url,
        headers: {
          'accept': 'application/json',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        // Update the last data update timestamp
        setState(() {
          _lastDataUpdate = DateTime.now();
        });
        return data;
      } else {
        throw Exception(
            'Failed to load traffic recommendations: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load traffic recommendations: $e');
    }
  }

  // Asynchronously loads forecast data from FastAPI
  Future<Map<String, dynamic>> _loadForecastData() async {
    try {
      final url = Uri.parse(
          'https://ravishing-education-production.up.railway.app/api/dashboard/user/end-user-prediction-detail');
      final response = await http.get(
        url,
        headers: {
          'accept': 'application/json',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        // Transform the API response to match the expected format
        Map<String, dynamic> transformedData = {};

        // Transform hourly data
        if (data['hourly'] != null) {
          transformedData['hourly'] = (data['hourly'] as List).map((item) {
            return {
              'ds': item['time'],
              'yhat': item['value'],
            };
          }).toList();
        }

        // Transform daily data
        if (data['daily'] != null) {
          transformedData['daily'] = (data['daily'] as List).map((item) {
            return {
              'ds': item['date'],
              'yhat': item['value'],
            };
          }).toList();
        }

        // Transform weekly data
        if (data['weekly'] != null) {
          transformedData['weekly'] = (data['weekly'] as List).map((item) {
            return {
              'ds': item['week_start'], // Use week_start as the date
              'yhat': item['value'],
            };
          }).toList();
        }

        // Transform monthly data
        if (data['monthly'] != null) {
          transformedData['monthly'] = (data['monthly'] as List).map((item) {
            return {
              'ds': item['month'],
              'yhat': item['value'],
            };
          }).toList();
        }

        return transformedData;
      } else {
        throw Exception(
            'Failed to load forecast data: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load forecast data: $e');
    }
  }

  // Asynchronously loads prediction summary from FastAPI
  Future<Map<String, dynamic>> _loadPredictionSummary() async {
    try {
      final url = Uri.parse(
          'https://ravishing-education-production.up.railway.app/api/dashboard/user/end-user-prediction-summary');
      final response = await http.get(
        url,
        headers: {
          'accept': 'application/json',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        throw Exception(
            'Failed to load prediction summary: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load prediction summary: $e');
    }
  }

  // Method to make custom prediction request
  Future<Map<String, dynamic>?> _makeCustomPredictionRequest(
      DateTime dateTime) async {
    setState(() {
      _isLoadingCustomPrediction = true;
    });

    try {
      final url = Uri.parse(
          'https://ravishing-education-production.up.railway.app/api/dashboard/user/end-user-prediction-req');

      final requestBody = {
        'time': dateTime.toIso8601String(),
      };

      final response = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          _customPredictionResult = data;
          _isLoadingCustomPrediction = false;
        });
        return data;
      } else {
        throw Exception(
            'Failed to get custom prediction: HTTP ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoadingCustomPrediction = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get prediction: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  // Method to show date and time picker
  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00C8FA),
              onPrimary: Colors.white,
              surface: Color(0xFF293949),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF00C8FA),
                onPrimary: Colors.white,
                surface: Color(0xFF293949),
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          _selectedDateTime = selectedDateTime;
        });

        // Make the prediction request
        await _makeCustomPredictionRequest(selectedDateTime);
      }
    }
  }

  // Helper method to get traffic level color
  Color _getTrafficLevelColor(double yhat) {
    if (yhat <= 50) return const Color(0xFF4CAF50); // Green for light traffic
    if (yhat <= 100) {
      return const Color.fromARGB(
          255, 0, 17, 255); // Orange for moderate traffic
    }
    return const Color.fromARGB(255, 111, 54, 244); // Red for heavy traffic
  }

  // Helper method to format date based on period
  String _formatDate(String dateStr, String period) {
    try {
      DateTime date = DateTime.parse(dateStr);
      switch (period) {
        case 'hourly':
          int hour = date.hour;
          String period = hour >= 12 ? 'PM' : 'AM';
          int displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
          return '$displayHour $period';
        case 'daily':
          const List<String> dayNames = [
            'Mon',
            'Tue',
            'Wed',
            'Thu',
            'Fri',
            'Sat',
            'Sun'
          ];
          return dayNames[date.weekday - 1];
        case 'weekly':
          return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
        case 'monthly':
          const List<String> monthNames = [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec'
          ];
          return monthNames[date.month - 1];
        default:
          return dateStr;
      }
    } catch (e) {
      return dateStr;
    }
  }

  // Line chart widget for forecast visualization
  Widget _buildForecastChart(List<dynamic> forecastData) {
    if (forecastData.isEmpty) return const Text('No forecast data available');

    // Limit items based on period for better visualization
    int maxItems;
    switch (_selectedPeriod) {
      case 'hourly':
        maxItems = 24; // Show all 24 hours
        break;
      case 'daily':
        maxItems = 7; // Show 7 days
        break;
      case 'weekly':
        maxItems = 4; // Show 4 weeks
        break;
      case 'monthly':
        maxItems = 12; // Show all 12 months
        break;
      default:
        maxItems = 7;
    }

    final displayData = forecastData.length > maxItems
        ? forecastData.take(maxItems).toList()
        : forecastData;

    // Find max and min values for scaling
    double maxYhat = displayData.fold(0.0, (max, item) {
      final yhat = item['yhat']?.toDouble() ?? 0.0;
      return yhat > max ? yhat : max;
    });

    double minYhat = displayData.fold(double.infinity, (min, item) {
      final yhat = item['yhat']?.toDouble() ?? 0.0;
      return yhat < min ? yhat : min;
    });

    // Add some padding to the range
    final range = maxYhat - minYhat;
    maxYhat += range * 0.1;
    minYhat -= range * 0.1;
    if (minYhat < 0) minYhat = 0;

    return Container(
      height: MediaQuery.of(context).orientation == Orientation.landscape
          ? MediaQuery.of(context).size.height * 0.8
          : MediaQuery.of(context).size.height * 0.35, // Responsive height
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Traffic Forecast',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFFFFF)), // White text
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: (_selectedPeriod == 'hourly' ||
                      _selectedPeriod == 'monthly')
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        width: displayData.length *
                                (_selectedPeriod == 'hourly' ? 40.0 : 60.0) +
                            40, // Different spacing for hourly vs monthly
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12), // Add padding for edge labels
                        child: CustomPaint(
                          size: Size(
                              displayData.length *
                                  (_selectedPeriod == 'hourly' ? 40.0 : 60.0),
                              MediaQuery.of(context).orientation ==
                                      Orientation.landscape
                                  ? MediaQuery.of(context).size.height * 0.6
                                  : MediaQuery.of(context).size.height * 0.25),
                          painter: LineChartPainter(
                            displayData,
                            maxYhat,
                            minYhat,
                            _getTrafficLevelColor,
                            _formatDate,
                            _selectedPeriod,
                          ),
                        ),
                      ),
                    )
                  : CustomPaint(
                      size: Size(
                          double.infinity,
                          MediaQuery.of(context).orientation ==
                                  Orientation.landscape
                              ? MediaQuery.of(context).size.height * 0.6
                              : MediaQuery.of(context).size.height * 0.25),
                      painter: LineChartPainter(
                        displayData,
                        maxYhat,
                        minYhat,
                        _getTrafficLevelColor,
                        _formatDate,
                        _selectedPeriod,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to format recommendation text
  Widget _buildRecommendationText(String text) {
    // Split by newlines and format
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        line = line.trim();
        if (line.isEmpty) return const SizedBox(height: 8);

        if (line.contains(':') &&
            (line.contains('Peak') ||
                line.contains('Lowest') ||
                line.contains('Average'))) {
          // This is a section header
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              line,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00C8FA), // New highlighted color
              ),
            ),
          );
        } else if (line.startsWith('- ')) {
          // This is a bullet point
          return Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ',
                    style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF00C8FA))), // New highlighted color
                Expanded(
                  child: Text(
                    line.substring(2),
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFFB0BEC5)), // Light Gray
                  ),
                ),
              ],
            ),
          );
        } else if (line.startsWith('* ')) {
          // This is also a bullet point
          return Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ',
                    style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF00C8FA))), // New highlighted color
                Expanded(
                  child: Text(
                    line.substring(2),
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFFB0BEC5)), // Light Gray
                  ),
                ),
              ],
            ),
          );
        } else {
          // Regular text
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              line,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFFB0BEC5)), // Light Gray
            ),
          );
        }
      }).toList(),
    );
  }

  // Helper method to build prediction summary widget
  Widget _buildPredictionSummary(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Traffic Summary',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(color: const Color(0xFFFFFFFF)), // White text
        ),
        const SizedBox(height: 12),

        // Today's Summary
        Card(
          elevation: 2,
          color: const Color(0xFF1A252F),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today (${_formatApiDate(data['today']?.toString() ?? '')})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00C8FA),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Vehicles: ${data['vhcl_today_sum']?.toString() ?? 'N/A'}',
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFFB0BEC5)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Peak: ${_formatTime(data['today_analytics']?['peak']?['time'])} (${data['today_analytics']?['peak']?['value']} vehicles)',
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFFB0BEC5)),
                      ),
                    ),
                    _buildConditionBadge(
                        data['today_analytics']?['peak']?['condition']),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Low: ${_formatTime(data['today_analytics']?['low']?['time'])} (${data['today_analytics']?['low']?['value']} vehicles)',
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFFB0BEC5)),
                      ),
                    ),
                    _buildConditionBadge(
                        data['today_analytics']?['low']?['condition']),
                  ],
                ),
                Text(
                  'Average: ${data['today_analytics']?['avg']?.toString() ?? 'N/A'} vehicles/hour',
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFFB0BEC5)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Current Week Summary
        Card(
          elevation: 2,
          color: const Color(0xFF1A252F),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This Week (${_formatApiDate(data['current_week_range']?['start'])} - ${_formatApiDate(data['current_week_range']?['end'])})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00C8FA),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Vehicles: ${data['vhcl_current_week_sum']?.toString() ?? 'N/A'}',
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFFB0BEC5)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Peak Day: ${_formatApiDate(data['weekly_analytics']?['peak']?['date'])} (${data['weekly_analytics']?['peak']?['value']} vehicles)',
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFFB0BEC5)),
                      ),
                    ),
                    _buildConditionBadge(
                        data['weekly_analytics']?['peak']?['condition']),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Low Day: ${_formatApiDate(data['weekly_analytics']?['low']?['date'])} (${data['weekly_analytics']?['low']?['value']} vehicles)',
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFFB0BEC5)),
                      ),
                    ),
                    _buildConditionBadge(
                        data['weekly_analytics']?['low']?['condition']),
                  ],
                ),
                Text(
                  'Daily Average: ${data['weekly_analytics']?['avg']?.toString() ?? 'N/A'} vehicles',
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFFB0BEC5)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Three Months Summary
        Card(
          elevation: 2,
          color: const Color(0xFF1A252F),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Three Months (${_formatApiDate(data['three_months_range']?['start'])} - ${_formatApiDate(data['three_months_range']?['end'])})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00C8FA),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Vehicles: ${data['vhcl_three_months_sum']?.toString() ?? 'N/A'}',
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFFB0BEC5)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Peak Month: ${_formatApiDate(data['three_months_analytics']?['peak']?['month'])} (${data['three_months_analytics']?['peak']?['value']} vehicles)',
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFFB0BEC5)),
                      ),
                    ),
                    _buildConditionBadge(
                        data['three_months_analytics']?['peak']?['condition']),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Low Month: ${_formatApiDate(data['three_months_analytics']?['low']?['month'])} (${data['three_months_analytics']?['low']?['value']} vehicles)',
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFFB0BEC5)),
                      ),
                    ),
                    _buildConditionBadge(
                        data['three_months_analytics']?['low']?['condition']),
                  ],
                ),
                Text(
                  'Monthly Average: ${data['three_months_analytics']?['avg']?.toString() ?? 'N/A'} vehicles',
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFFB0BEC5)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to format API dates
  String _formatApiDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  // Helper method to format time from API
  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return 'N/A';
    try {
      final time = DateTime.parse(timeStr);
      int hour = time.hour;
      String period = hour >= 12 ? 'PM' : 'AM';
      int displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$displayHour $period';
    } catch (e) {
      return timeStr;
    }
  }

  // Helper method to capitalize condition text
  String _capitalizeCondition(String? condition) {
    if (condition == null || condition.isEmpty) return 'N/A';
    return condition[0].toUpperCase() + condition.substring(1);
  }

  // Helper method to get color for traffic condition
  Color _getConditionColor(String? condition) {
    if (condition == null) return Colors.grey;
    switch (condition.toLowerCase()) {
      case 'light':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'heavy':
      case 'congested':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper method to build condition badge
  Widget _buildConditionBadge(String? condition) {
    final color = _getConditionColor(condition);
    final text = _capitalizeCondition(condition);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Helper method to format custom selected datetime
  String _formatCustomDateTime(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    int hour = dateTime.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    int displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at $displayHour:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }

  // Helper method to extract numeric prediction value
  double? _extractPredictionValue(Map<String, dynamic> result) {
    if (result.isEmpty) return null;

    // Check if there's a forecast array (new API format)
    if (result.containsKey('forecast') && result['forecast'] is List) {
      final forecast = result['forecast'] as List;
      if (forecast.isNotEmpty) {
        final firstForecast = forecast[0];
        if (firstForecast is Map<String, dynamic> &&
            firstForecast.containsKey('value')) {
          final value = firstForecast['value'];
          if (value is num) {
            return value.toDouble();
          }
        }
      }
    }

    // If there's a prediction value
    if (result.containsKey('prediction')) {
      final prediction = result['prediction'];
      if (prediction is num) {
        return prediction.toDouble();
      }
    }

    // If there's a direct traffic count
    if (result.containsKey('traffic_count')) {
      final count = result['traffic_count'];
      if (count is num) {
        return count.toDouble();
      }
    }

    // If there's any numeric value, use the first one found
    for (final entry in result.entries) {
      if (entry.value is num) {
        return (entry.value as num).toDouble();
      }
    }

    return null;
  }

  // Build custom prediction chart
  Widget _buildCustomPredictionChart(Map<String, dynamic> result) {
    final predictionValue = _extractPredictionValue(result);
    if (predictionValue == null) {
      return Container(
        height: 238, // Reduced height to prevent overflow (280 - 42)
        child: const Center(
          child: Text(
            'Unable to display chart: No numeric prediction data',
            style: TextStyle(color: Color(0xFFB0BEC5)),
          ),
        ),
      );
    }

    return Container(
      height: 238, // Reduced height to prevent overflow (280 - 42)
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Expanded(
            child: CustomPaint(
              size: const Size(double.infinity, 218), // Reduced from 260 to 218
              painter: CustomPredictionChartPainter(
                predictionValue: predictionValue,
                selectedDateTime: _selectedDateTime!,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF192A31), // New background color
      appBar: AppBar(
        title: RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            children: [
              TextSpan(text: 'SmartTraffic'),
              TextSpan(
                text: 'Malabon',
                style: TextStyle(
                  color: Color(0xFF00C8FA), // Cyan color for Malabon
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFF192A31), // New app bar background
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF00C8FA), // New refresh indicator color
        onRefresh: () async {
          _refreshData();
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Dashboard - Current Status
              _buildCurrentStatusHeader(),

              _buildMainContentTabs(),
            ],
          ),
        ),
      ),
    );
  }

  // New methods for improved design
  Widget _buildCurrentStatusHeader() {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Container(
      margin: EdgeInsets.all(isPortrait ? 8 : 12), // Further reduced margin
      child: Card(
        elevation: 8,
        color: const Color(0xFF1A252F),
        child: Container(
          padding:
              EdgeInsets.all(isPortrait ? 12 : 16), // Further reduced padding
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFF1A252F), Color(0xFF293949)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    // Make the title section flexible
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'C4 Road - Malabon City',
                          style: TextStyle(
                            fontSize: isPortrait
                                ? 18
                                : 22, // Smaller font in portrait
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Updated: ${_lastDataUpdate?.toString().split('.')[0] ?? 'Loading...'}',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: isPortrait
                                ? 10
                                : 12, // Smaller font in portrait
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(
                  height: isPortrait ? 8 : 10), // Reduced spacing in portrait
              FutureBuilder<Map<String, dynamic>>(
                future: _predictionSummaryFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final data = snapshot.data!;
                    final todayAnalytics = data['today_analytics'];
                    return Row(
                      children: [
                        Expanded(
                          child: _buildStatusMetric(
                            'Current Traffic',
                            todayAnalytics?['avg']?.toString() ?? 'N/A',
                            'vehicles/hour',
                            Icons.traffic,
                            const Color(0xFF00C8FA),
                          ),
                        ),
                        SizedBox(
                            width: isPortrait
                                ? 6
                                : 8), // Reduced spacing in portrait
                        Expanded(
                          child: _buildStatusMetric(
                            'Today\'s Total',
                            data['vhcl_today_sum']?.toString() ?? 'N/A',
                            'vehicles',
                            Icons.directions_car,
                            const Color(0xFF00C8FA),
                          ),
                        ),
                      ],
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusMetric(
      String title, String value, String unit, IconData icon, Color color) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Container(
      padding:
          EdgeInsets.all(isPortrait ? 12 : 16), // Reduced padding in portrait
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  color: color,
                  size: isPortrait ? 18 : 20), // Smaller icon in portrait
              const SizedBox(width: 6),
              Flexible(
                // Make text flexible to prevent overflow
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isPortrait ? 12 : 14, // Smaller font in portrait
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: isPortrait ? 6 : 8), // Reduced spacing in portrait
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isPortrait ? 20 : 24, // Smaller font in portrait
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Text(
            unit,
            style: TextStyle(
              color: Colors.white60,
              fontSize: isPortrait ? 10 : 12, // Smaller font in portrait
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildMainContentTabs() {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return DefaultTabController(
      length: 3,
      child: Container(
        margin: const EdgeInsets.all(12), // Reduced margin from 16 to 12
        child: Card(
          elevation: 4,
          color: const Color(0xFF293949),
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1A252F),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: TabBar(
                  labelColor: const Color(0xFF00C8FA),
                  unselectedLabelColor: Colors.white60,
                  indicatorColor: const Color(0xFF00C8FA),
                  tabs: isPortrait
                      ? [
                          // Icon-only tabs for portrait mode
                          const Tab(icon: Icon(Icons.trending_up, size: 20)),
                          const Tab(icon: Icon(Icons.lightbulb, size: 20)),
                          const Tab(icon: Icon(Icons.analytics, size: 20)),
                        ]
                      : [
                          // Text + icon tabs for landscape mode
                          const Tab(
                              text: 'Forecast',
                              icon: Icon(Icons.trending_up, size: 20)),
                          const Tab(
                              text: 'Recommendations',
                              icon: Icon(Icons.lightbulb, size: 20)),
                          const Tab(
                              text: 'Summary',
                              icon: Icon(Icons.analytics, size: 20)),
                        ],
                ),
              ),
              SizedBox(
                height: 480, // Increased height from 400 to 480
                child: TabBarView(
                  children: [
                    _buildForecastTab(),
                    _buildRecommendationsTab(),
                    _buildSummaryTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForecastTab() {
    return Padding(
      padding: const EdgeInsets.all(12), // Reduced padding
      child: Column(
        children: [
          // Custom Prediction Section
          Card(
            elevation: 2,
            color: const Color(0xFF1A252F),
            child: Padding(
              padding: const EdgeInsets.all(12), // Reduced padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Custom Prediction',
                    style: TextStyle(
                      fontSize: 14, // Slightly smaller
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00C8FA),
                    ),
                  ),
                  const SizedBox(height: 6), // Reduced spacing
                  const Text(
                    'Select date and time for prediction',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11), // Smaller and shorter text
                  ),
                  const SizedBox(height: 10), // Reduced spacing

                  // Date Time Selection Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          _isLoadingCustomPrediction ? null : _selectDateTime,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        _selectedDateTime == null
                            ? 'Select Date & Time'
                            : _formatCustomDateTime(_selectedDateTime!),
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C8FA),
                        foregroundColor: const Color(0xFF1A252F),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8), // Reduced padding
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  if (_isLoadingCustomPrediction) ...[
                    const SizedBox(height: 8), // Reduced spacing
                    const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00C8FA),
                        strokeWidth: 2,
                      ),
                    ),
                  ],

                  // Custom Prediction Result
                  if (_customPredictionResult != null) ...[
                    const SizedBox(height: 8), // Reduced spacing
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8), // Reduced padding
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Prediction Result:',
                                style: TextStyle(
                                  color: Color(0xFF00C8FA),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12, // Smaller font
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _customPredictionResult = null;
                                    _selectedDateTime = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A252F),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back,
                                    size: 16,
                                    color: Color(0xFF00C8FA),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6), // Reduced spacing
                          _buildCustomPredictionChart(_customPredictionResult!),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 12), // Reduced spacing

          // Time Period Selector - only show when no custom prediction is active
          if (_customPredictionResult == null)
            LayoutBuilder(
              builder: (context, constraints) {
                final isPortrait =
                    MediaQuery.of(context).orientation == Orientation.portrait;
                final horizontalMargin = isPortrait ? 1.0 : 4.0;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _timePeriods.map((period) {
                    final isSelected = period == _selectedPeriod;
                    return Expanded(
                      child: Container(
                        margin:
                            EdgeInsets.symmetric(horizontal: horizontalMargin),
                        child: ChoiceChip(
                          label: Text(
                            period.capitalize(),
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: isPortrait ? 11 : 12,
                            ),
                          ),
                          selected: isSelected,
                          showCheckmark: false,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedPeriod = period;
                              });
                            }
                          },
                          selectedColor: const Color(0xFF00C8FA),
                          backgroundColor: const Color(0xFF586A80),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          if (_customPredictionResult == null)
            const SizedBox(height: 12), // Reduced spacing
          // Forecast Chart - only show when no custom prediction is active
          if (_customPredictionResult == null)
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _forecastDataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF00C8FA)));
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            'Error loading forecast',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  } else if (snapshot.hasData) {
                    final data = snapshot.data!;
                    final forecastList =
                        data[_selectedPeriod] as List<dynamic>? ?? [];
                    return _buildForecastChart(forecastList);
                  }
                  return const SizedBox();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _trafficRecommendationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00C8FA)));
        } else if (snapshot.hasError) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text(
                  'Error loading recommendations',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          );
        } else if (snapshot.hasData) {
          return _buildTrafficRecommendations(snapshot.data!);
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildSummaryTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _predictionSummaryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00C8FA)));
        } else if (snapshot.hasError) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text(
                  'Error loading summary',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          );
        } else if (snapshot.hasData) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildPredictionSummary(snapshot.data!),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildTrafficRecommendations(Map<String, dynamic> data) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    String recoKey = '${_selectedPeriod}_reco';
    final recommendationText = data[recoKey] as String? ?? '';

    return SingleChildScrollView(
      padding: EdgeInsets.all(isPortrait ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Traffic Recommendations (${_selectedPeriod.capitalize()})',
            style: TextStyle(
              fontSize: isPortrait ? 16 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isPortrait ? 12 : 16),
          if (recommendationText.isEmpty)
            Card(
              color: const Color(0xFF1A252F),
              child: Padding(
                padding: EdgeInsets.all(isPortrait ? 16 : 20),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.orange, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No $_selectedPeriod recommendations available.',
                        style: const TextStyle(color: Color(0xFFB0BEC5)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              elevation: 2,
              color: const Color(0xFF1A252F),
              child: Padding(
                padding: EdgeInsets.all(isPortrait ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb,
                            color: Color(0xFF00C8FA), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Recommendations',
                            style: TextStyle(
                              fontSize: isPortrait ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF00C8FA),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isPortrait ? 12 : 16),
                    _buildRecommendationText(recommendationText),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Extension to capitalize strings
extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

// Custom painter for line chart
class LineChartPainter extends CustomPainter {
  final List<dynamic> data;
  final double maxYhat;
  final double minYhat;
  final Color Function(double) getTrafficLevelColor;
  final String Function(String, String) formatDate;
  final String period;

  LineChartPainter(
    this.data,
    this.maxYhat,
    this.minYhat,
    this.getTrafficLevelColor,
    this.formatDate,
    this.period,
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final pointPaint = Paint()..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = const Color(0xFF00C8FA) // New highlighted color for line
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final gridPaint = Paint()
      ..color = const Color(0xFF293949).withOpacity(0.3) // New grid color
      ..strokeWidth = 1.0;

    // Draw grid lines
    const gridLines = 5;
    for (int i = 0; i <= gridLines; i++) {
      final y =
          (size.height - 40) * i / gridLines + 20; // Leave space for labels
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Calculate points
    final points = <Offset>[];
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final yhat = data[i]['yhat']?.toDouble() ?? 0.0;
      final normalizedY = (yhat - minYhat) / (maxYhat - minYhat);
      final x = i * stepX;
      final y = size.height -
          40 -
          (normalizedY * (size.height - 60)); // Leave space for labels
      points.add(Offset(x, y));
    }

    // Draw line
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);

      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }

      canvas.drawPath(path, linePaint);
    }

    // Draw points and labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < points.length; i++) {
      final yhat = data[i]['yhat']?.toDouble() ?? 0.0;
      final point = points[i];

      // Draw point
      pointPaint.color = const Color(0xFF00C8FA);
      canvas.drawCircle(point, 6, pointPaint);

      // Draw value label above point
      textPainter.text = TextSpan(
        text: yhat.toInt().toString(),
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(point.dx - textPainter.width / 2, point.dy - 20),
      );

      // Draw date label below chart
      final date = data[i]['ds'] ?? 'Unknown';
      textPainter.text = TextSpan(
        text: formatDate(date.toString(), period),
        style: const TextStyle(
          color: Color(0xFFB0BEC5),
          fontSize: 9,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(point.dx - textPainter.width / 2, size.height - 15),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom painter for prediction chart
class CustomPredictionChartPainter extends CustomPainter {
  final double predictionValue;
  final DateTime selectedDateTime;

  CustomPredictionChartPainter({
    required this.predictionValue,
    required this.selectedDateTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create forecast data with a simple trend around the prediction
    final forecastData = _createPredictionForecast();

    if (forecastData.isEmpty) return;

    // Use same styling as the main line chart
    final pointPaint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = const Color(0xFF00C8FA)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final gridPaint = Paint()
      ..color = const Color(0xFF293949).withOpacity(0.3)
      ..strokeWidth = 1.0;

    // Calculate min/max for scaling
    final values = forecastData.map((e) => e['value'] as double).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;
    final paddedMax = maxValue + range * 0.1;
    final paddedMin = (minValue - range * 0.1).clamp(0.0, double.infinity);

    // Draw grid lines
    const gridLines = 5;
    for (int i = 0; i <= gridLines; i++) {
      final y = (size.height - 40) * i / gridLines + 20;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Calculate points
    final points = <Offset>[];
    final stepX = size.width / (forecastData.length - 1);
    for (int i = 0; i < forecastData.length; i++) {
      final value = forecastData[i]['value'] as double;
      final normalizedY = (value - paddedMin) / (paddedMax - paddedMin);
      final x = i * stepX;
      final y = size.height - 40 - (normalizedY * (size.height - 60));
      points.add(Offset(x, y));
    }

    // Draw line
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // Draw points and labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < points.length; i++) {
      final value = forecastData[i]['value'] as double;
      final time = forecastData[i]['time'] as DateTime;
      final point = points[i];
      final isMainPrediction = forecastData[i]['isMain'] as bool;

      // Draw point - highlight the main prediction
      pointPaint.color = isMainPrediction
          ? const Color(0xFFFFD700) // Gold for main prediction
          : const Color(0xFF00C8FA); // Cyan for other points
      canvas.drawCircle(point, isMainPrediction ? 8 : 6, pointPaint);

      // Draw value label above point
      textPainter.text = TextSpan(
        text: value.toInt().toString(),
        style: TextStyle(
          color: isMainPrediction
              ? const Color(0xFFFFD700)
              : const Color(0xFFFFFFFF),
          fontSize: isMainPrediction ? 12 : 10,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset(point.dx - textPainter.width / 2,
              point.dy - (isMainPrediction ? 25 : 20)));

      // Draw time label below chart
      textPainter.text = TextSpan(
        text: _formatHour(time),
        style: TextStyle(
          color: isMainPrediction
              ? const Color(0xFFFFD700)
              : const Color(0xFFB0BEC5),
          fontSize: 9,
          fontWeight: isMainPrediction ? FontWeight.bold : FontWeight.normal,
        ),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(point.dx - textPainter.width / 2, size.height - 15));
    }
  }

  List<Map<String, dynamic>> _createPredictionForecast() {
    // Create a 5-point forecast centered around the selected time
    final centerIndex = 2; // Middle point
    final forecastData = <Map<String, dynamic>>[];

    for (int i = 0; i < 5; i++) {
      final offsetHours = i - centerIndex;
      final time = selectedDateTime.add(Duration(hours: offsetHours));
      final isMain = i == centerIndex;

      // Create slight variations around the prediction value
      double value = predictionValue;
      if (!isMain) {
        // Add some realistic variation (±5-15 vehicles)
        final variation = (10 - (i - centerIndex).abs() * 3);
        value += (offsetHours * 2) + variation;
        value = value.clamp(predictionValue - 20, predictionValue + 20);
      }

      forecastData.add({
        'time': time,
        'value': value,
        'isMain': isMain,
      });
    }

    return forecastData;
  }

  String _formatHour(DateTime time) {
    int hour = time.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    int displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour $period';
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
