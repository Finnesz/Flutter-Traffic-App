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
      title: 'C4 Road Traffic Prediction',
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
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF586A80), // Unselected chip color
          selectedColor: const Color(0xFF00C8FA), // Selected chip color
          labelStyle: const TextStyle(color: Colors.white),
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
    if (yhat <= 100)
      return const Color.fromARGB(
          // TODO: Change the dots to #00C8FA regardless of traffic
          255,
          0,
          17,
          255); // Orange for moderate traffic
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
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
                            horizontal: 20), // Add padding for edge labels
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
          color: const Color(0xFF293949),
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
                Text(
                  'Peak: ${_formatTime(data['today_analytics']?['peak']?['time'])} (${data['today_analytics']?['peak']?['value']} vehicles) - ${_capitalizeCondition(data['today_analytics']?['peak']?['condition'])}',
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFFB0BEC5)),
                ),
                Text(
                  'Low: ${_formatTime(data['today_analytics']?['low']?['time'])} (${data['today_analytics']?['low']?['value']} vehicles) - ${_capitalizeCondition(data['today_analytics']?['low']?['condition'])}',
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFFB0BEC5)),
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
          color: const Color(0xFF293949),
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
                Text(
                  'Peak Day: ${_formatApiDate(data['weekly_analytics']?['peak']?['date'])} (${data['weekly_analytics']?['peak']?['value']} vehicles) - ${_capitalizeCondition(data['weekly_analytics']?['peak']?['condition'])}',
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFFB0BEC5)),
                ),
                Text(
                  'Low Day: ${_formatApiDate(data['weekly_analytics']?['low']?['date'])} (${data['weekly_analytics']?['low']?['value']} vehicles) - ${_capitalizeCondition(data['weekly_analytics']?['low']?['condition'])}',
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFFB0BEC5)),
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
          color: const Color(0xFF293949),
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
                Text(
                  'Peak Month: ${_formatApiDate(data['three_months_analytics']?['peak']?['month'])} (${data['three_months_analytics']?['peak']?['value']} vehicles) - ${_capitalizeCondition(data['three_months_analytics']?['peak']?['condition'])}',
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFFB0BEC5)),
                ),
                Text(
                  'Low Month: ${_formatApiDate(data['three_months_analytics']?['low']?['month'])} (${data['three_months_analytics']?['low']?['value']} vehicles) - ${_capitalizeCondition(data['three_months_analytics']?['low']?['condition'])}',
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFFB0BEC5)),
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

  // Helper method to format prediction result
  String _formatPredictionResult(Map<String, dynamic> result) {
    // Since the API response structure isn't clear from the example,
    // let's handle different possible response formats
    if (result.isEmpty) {
      return 'No prediction data available for the selected time.';
    }

    // Check if there's a forecast array (new API format)
    if (result.containsKey('forecast') && result['forecast'] is List) {
      final forecast = result['forecast'] as List;
      if (forecast.isNotEmpty) {
        final firstForecast = forecast[0];
        if (firstForecast is Map<String, dynamic> &&
            firstForecast.containsKey('value')) {
          final value = firstForecast['value'];
          if (value is num) {
            return 'Predicted traffic: ${value.round()} vehicles for the selected time';
          }
        }
      }
    }

    // If there's a prediction value
    if (result.containsKey('prediction')) {
      final prediction = result['prediction'];
      if (prediction is num) {
        return 'Predicted traffic: ${prediction.round()} vehicles';
      }
    }

    // If there's a direct traffic count
    if (result.containsKey('traffic_count')) {
      final count = result['traffic_count'];
      if (count is num) {
        return 'Predicted traffic: ${count.round()} vehicles';
      }
    }

    // If there's any numeric value, use the first one found
    for (final entry in result.entries) {
      if (entry.value is num) {
        return 'Predicted traffic: ${(entry.value as num).round()} vehicles';
      }
    }

    // Fallback: show the raw JSON in a readable format
    return 'Prediction data: ${result.toString()}';
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
        height: 200,
        child: const Center(
          child: Text(
            'Unable to display chart: No numeric prediction data',
            style: TextStyle(color: Color(0xFFB0BEC5)),
          ),
        ),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: CustomPaint(
              size: const Size(double.infinity, 180),
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
        title: const Text('C4 Road - Malabon City'),
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header Card
            Card(
              elevation: 4,
              color: const Color(0xFF293949), // New card color
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'C4 Road Traffic Status',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              color: const Color(0xFFFFFFFF)), // White text
                    ),
                    const SizedBox(height: 8),
                    Text(
                        'Updated: ${_lastDataUpdate?.toString().split('.')[0] ?? 'Loading...'}',
                        style: const TextStyle(
                            color: Color(0xFFB0BEC5))), // Light Gray
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Custom Prediction Request Card
            Card(
              elevation: 2,
              color: const Color(0xFF293949),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Custom Prediction Request',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              color: const Color(0xFFFFFFFF), fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select a specific date and time to get traffic prediction',
                      style: const TextStyle(
                          color: Color(0xFFB0BEC5), fontSize: 14),
                    ),
                    const SizedBox(height: 16),

                    // Date Time Selection Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            _isLoadingCustomPrediction ? null : _selectDateTime,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _selectedDateTime == null
                              ? 'Select Date & Time'
                              : 'Selected: ${_formatCustomDateTime(_selectedDateTime!)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),

                    if (_isLoadingCustomPrediction) ...[
                      const SizedBox(height: 16),
                      const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00C8FA),
                        ),
                      ),
                    ],

                    // Custom Prediction Result
                    if (_customPredictionResult != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF192A31),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF00C8FA), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prediction Result:',
                              style: const TextStyle(
                                color: Color(0xFF00C8FA),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Chart visualization
                            _buildCustomPredictionChart(
                                _customPredictionResult!),
                            const SizedBox(height: 8),
                            // Text summary
                            Text(
                              _formatPredictionResult(_customPredictionResult!),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Time Period Selector and Forecast Chart Combined
            Card(
              elevation: 2,
              color: const Color(0xFF293949), // New card color
              child: Column(
                children: [
                  // Time Period Selector
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 0),
                        Row(
                          children: _timePeriods.map((period) {
                            final isSelected = period == _selectedPeriod;
                            final isLandscape =
                                MediaQuery.of(context).orientation ==
                                    Orientation.landscape;
                            return Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                child: ChoiceChip(
                                  label: Text(
                                    period.capitalize(),
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: isLandscape
                                          ? 14
                                          : 9, // Larger font in landscape
                                    ),
                                  ),
                                  selected: isSelected,
                                  showCheckmark: false, // Remove the check icon
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedPeriod = period;
                                      });
                                    }
                                  },
                                  selectedColor: const Color(
                                      0xFF00C8FA), // New highlighted color
                                  backgroundColor: const Color(
                                      0xFF586A80), // New unselected button color
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isLandscape ? 16 : 8,
                                    vertical: isLandscape ? 12 : 8,
                                  ), // Larger padding in landscape
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  // Forecast Chart
                  FutureBuilder<Map<String, dynamic>>(
                    future: _forecastDataFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SizedBox(
                          height: MediaQuery.of(context).size.height * 0.35,
                          child: const Center(
                              child: CircularProgressIndicator(
                                  color: Color(
                                      0xFF00C8FA))), // New highlighted color
                        );
                      } else if (snapshot.hasError) {
                        return Container(
                          height: MediaQuery.of(context).size.height * 0.35,
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              'Error loading forecast: ${snapshot.error}',
                              style: const TextStyle(
                                  color: Color(0xFFF44336)), // Red error text
                            ),
                          ),
                        );
                      } else if (snapshot.hasData) {
                        final data = snapshot.data!;
                        final forecastList =
                            data[_selectedPeriod] as List<dynamic>? ?? [];
                        return _buildForecastChart(forecastList);
                      }
                      return SizedBox(
                          height: MediaQuery.of(context).size.height * 0.35);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Traffic Recommendations
            FutureBuilder<Map<String, dynamic>>(
              future: _trafficRecommendationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF00C8FA))); // New highlighted color
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64,
                            color: const Color(0xFFF44336)), // Red error icon
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}',
                            style: const TextStyle(
                                color: Color(0xFFFFFFFF))), // White text
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                                0xFF00C8FA), // New highlighted color
                          ),
                          onPressed: () {
                            setState(() {
                              _trafficRecommendationsFuture =
                                  _loadTrafficRecommendations();
                            });
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                } else if (snapshot.hasData) {
                  final data = snapshot.data!;
                  // Map period to the correct key in JSON
                  String recoKey = '${_selectedPeriod}_reco';

                  final recommendationText = data[recoKey] as String? ?? '';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Traffic Recommendations (${_selectedPeriod.capitalize()})',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                                color: const Color(0xFFFFFFFF)), // White text
                      ),
                      const SizedBox(height: 12),
                      if (recommendationText.isEmpty)
                        Card(
                          color: const Color(0xFF293949), // New card color
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No ${_selectedPeriod} recommendations available.',
                              style: const TextStyle(
                                  color: Color(0xFFB0BEC5)), // Light Gray
                            ),
                          ),
                        )
                      else
                        Card(
                          elevation: 2,
                          color: const Color(0xFF293949), // New card color
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: _buildRecommendationText(recommendationText),
                          ),
                        ),
                    ],
                  );
                } else {
                  return const Center(
                      child: Text('No recommendations available.',
                          style: TextStyle(
                              color: Color(0xFFFFFFFF)))); // White text
                }
              },
            ),
            FutureBuilder<Map<String, dynamic>>(
              future: _predictionSummaryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                } else if (snapshot.hasError) {
                  return const SizedBox.shrink();
                } else if (snapshot.hasData) {
                  final data = snapshot.data!;
                  return _buildPredictionSummary(data);
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
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
