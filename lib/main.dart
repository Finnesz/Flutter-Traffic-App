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
  Map<String, dynamic>? _customPredictionRecommendations;
  bool _isLoadingCustomRecommendations = false;

  // For recommendations tabs
  int _selectedRecommendationTab = 0; // 0 = General, 1 = Custom Prediction

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

        // Automatically fetch recommendations for the predicted date/time
        await _makeCustomRecommendationRequest(dateTime);

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

  // Method to fetch custom prediction recommendations
  Future<Map<String, dynamic>?> _makeCustomRecommendationRequest(
      DateTime dateTime) async {
    setState(() {
      _isLoadingCustomRecommendations = true;
    });

    try {
      final url = Uri.parse(
          'https://ravishing-education-production.up.railway.app/api/dashboard/user/end-user-traffic-req-recommendations');

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
        dynamic responseData;
        try {
          responseData = json.decode(response.body);
        } catch (e) {
          // If JSON decoding fails, treat response as plain text
          responseData = {'message': response.body};
        }

        Map<String, dynamic> data;
        if (responseData is Map<String, dynamic>) {
          data = responseData;
        } else if (responseData is String) {
          data = {'message': responseData};
        } else {
          data = {'message': responseData.toString()};
        }

        setState(() {
          _customPredictionRecommendations = data;
          _isLoadingCustomRecommendations = false;
        });
        return data;
      } else {
        throw Exception(
            'Failed to get custom recommendations: HTTP ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoadingCustomRecommendations = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get recommendations: $e'),
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
          ? MediaQuery.of(context).size.height * 0.6
          : MediaQuery.of(context).size.height *
              0.25, // Smaller responsive height
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
                                      (_selectedPeriod == 'hourly'
                                          ? 40.0
                                          : 60.0) +
                                  40, // Add extra space for edge labels
                              MediaQuery.of(context).orientation ==
                                      Orientation.landscape
                                  ? MediaQuery.of(context).size.height * 0.4
                                  : MediaQuery.of(context).size.height * 0.15),
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
                              ? MediaQuery.of(context).size.height * 0.4
                              : MediaQuery.of(context).size.height * 0.15),
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

  Widget _buildEnhancedRecommendationText(String text) {
    // Clean up the text by removing asterisks and splitting by newlines
    final cleanText = text.replaceAll('*', '').trim();
    final lines =
        cleanText.split('\n').where((line) => line.trim().isNotEmpty).toList();

    if (lines.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF293949).withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'No recommendations available for this period.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.asMap().entries.map((entry) {
        final index = entry.key;
        var line = entry.value.trim();

        // Remove leading bullet points or dashes
        if (line.startsWith('- ') || line.startsWith('• ')) {
          line = line.substring(2).trim();
        }

        return Container(
          margin: EdgeInsets.only(bottom: index < lines.length - 1 ? 12 : 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF293949).withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF00C8FA).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: const Color(0xFF00C8FA),
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  line,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Helper method to build prediction summary widget
  Widget _buildPredictionSummary(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with icon
        Row(
          children: [
            const Icon(
              Icons.analytics,
              color: Color(0xFF00C8FA),
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Traffic Summary',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: const Color(0xFFFFFFFF)),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Today's Summary - Redesigned
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A252F), Color(0xFF293949)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00C8FA).withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C8FA).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.today,
                        color: Color(0xFF00C8FA),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Today',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00C8FA),
                            ),
                          ),
                          Text(
                            _formatApiDate(data['today']?.toString() ?? ''),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB0BEC5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C8FA),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${data['vhcl_today_sum']?.toString() ?? 'N/A'} vehicles',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A252F),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryMetric(
                        Icons.trending_up,
                        'Peak',
                        '${_formatTime(data['today_analytics']?['peak']?['time'])}',
                        '${data['today_analytics']?['peak']?['value']} vehicles',
                        data['today_analytics']?['peak']?['condition'],
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryMetric(
                        Icons.trending_down,
                        'Low',
                        '${_formatTime(data['today_analytics']?['low']?['time'])}',
                        '${data['today_analytics']?['low']?['value']} vehicles',
                        data['today_analytics']?['low']?['condition'],
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bar_chart,
                          color: Color(0xFF00C8FA), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Average: ${data['today_analytics']?['avg']?.toString() ?? 'N/A'} vehicles/hour',
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFFB0BEC5)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // This Week Summary - Redesigned
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A252F), Color(0xFF293949)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00C8FA).withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C8FA).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.calendar_view_week,
                        color: Color(0xFF00C8FA),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'This Week',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00C8FA),
                            ),
                          ),
                          Text(
                            '${_formatApiDate(data['current_week_range']?['start'])} - ${_formatApiDate(data['current_week_range']?['end'])}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB0BEC5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C8FA),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${data['vhcl_current_week_sum']?.toString() ?? 'N/A'} vehicles',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A252F),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryMetric(
                        Icons.trending_up,
                        'Peak Day',
                        _formatApiDate(
                            data['weekly_analytics']?['peak']?['date']),
                        '${data['weekly_analytics']?['peak']?['value']} vehicles',
                        data['weekly_analytics']?['peak']?['condition'],
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryMetric(
                        Icons.trending_down,
                        'Low Day',
                        _formatApiDate(
                            data['weekly_analytics']?['low']?['date']),
                        '${data['weekly_analytics']?['low']?['value']} vehicles',
                        data['weekly_analytics']?['low']?['condition'],
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bar_chart,
                          color: Color(0xFF00C8FA), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Daily Average: ${data['weekly_analytics']?['avg']?.toString() ?? 'N/A'} vehicles',
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFFB0BEC5)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Three Months Summary - Redesigned
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A252F), Color(0xFF293949)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00C8FA).withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C8FA).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.calendar_view_month,
                        color: Color(0xFF00C8FA),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Three Months',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00C8FA),
                            ),
                          ),
                          Text(
                            '${_formatApiDate(data['three_months_range']?['start'])} - ${_formatApiDate(data['three_months_range']?['end'])}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB0BEC5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C8FA),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${data['vhcl_three_months_sum']?.toString() ?? 'N/A'} vehicles',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A252F),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryMetric(
                        Icons.trending_up,
                        'Peak Month',
                        _formatApiDate(
                            data['three_months_analytics']?['peak']?['month']),
                        '${data['three_months_analytics']?['peak']?['value']} vehicles',
                        data['three_months_analytics']?['peak']?['condition'],
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryMetric(
                        Icons.trending_down,
                        'Low Month',
                        _formatApiDate(
                            data['three_months_analytics']?['low']?['month']),
                        '${data['three_months_analytics']?['low']?['value']} vehicles',
                        data['three_months_analytics']?['low']?['condition'],
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bar_chart,
                          color: Color(0xFF00C8FA), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Monthly Average: ${data['three_months_analytics']?['avg']?.toString() ?? 'N/A'} vehicles',
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFFB0BEC5)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // New helper method for summary metrics
  Widget _buildSummaryMetric(IconData icon, String label, String time,
      String value, String? condition, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            time,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFB0BEC5),
            ),
          ),
          if (condition != null) ...[
            const SizedBox(height: 6),
            _buildConditionBadge(condition),
          ],
        ],
      ),
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

  String _formatCompactDateTime(DateTime dateTime) {
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

    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} ${displayHour}:${dateTime.minute.toString().padLeft(2, '0')} $period';
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
        height: 180, // Increased height for bigger chart
        child: const Center(
          child: Text(
            'Unable to display chart: No numeric prediction data',
            style: TextStyle(color: Color(0xFFB0BEC5)),
          ),
        ),
      );
    }

    return Container(
      height: 180, // Increased height for bigger chart
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Expanded(
                child: Container(
                  width: constraints.maxWidth - 16, // Account for padding
                  height: constraints.maxHeight -
                      12, // Account for padding and spacing
                  child: CustomPaint(
                    size: Size(
                        constraints.maxWidth - 16, constraints.maxHeight - 12),
                    painter: CustomPredictionChartPainter(
                      predictionValue: predictionValue,
                      selectedDateTime: _selectedDateTime!,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEnhancedCustomRecommendationsList(
      Map<String, dynamic> recommendations) {
    // Extract recommendations from the response
    List<String> recommendationsList = [];

    // Handle different response formats
    if (recommendations.containsKey('recommendations')) {
      final recs = recommendations['recommendations'];
      if (recs is List) {
        recommendationsList = recs
            .map((item) => item.toString().replaceAll('*', '').trim())
            .toList();
      } else if (recs is String) {
        recommendationsList = [recs.replaceAll('*', '').trim()];
      }
    } else if (recommendations.containsKey('message')) {
      final message =
          recommendations['message'].toString().replaceAll('*', '').trim();
      // Split message by common delimiters if it contains multiple recommendations
      if (message.contains('\n')) {
        recommendationsList = message
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .map((line) => line.trim())
            .toList();
      } else if (message.contains('. ')) {
        recommendationsList = message
            .split('. ')
            .where((line) => line.trim().isNotEmpty)
            .map((line) => line.trim())
            .toList();
      } else {
        recommendationsList = [message];
      }
    } else if (recommendations.containsKey('data')) {
      final data = recommendations['data'];
      if (data is String) {
        recommendationsList = [data.replaceAll('*', '').trim()];
      } else if (data is List) {
        recommendationsList = data
            .map((item) => item.toString().replaceAll('*', '').trim())
            .toList();
      }
    } else {
      // Fallback: try to extract any string values from the response
      recommendations.forEach((key, value) {
        if (value is String && value.isNotEmpty) {
          recommendationsList.add(value.replaceAll('*', '').trim());
        }
      });
    }

    if (recommendationsList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF293949).withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'No specific recommendations available for this time period.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: recommendationsList.asMap().entries.map((entry) {
        final index = entry.key;
        final recommendation = entry.value;

        return Container(
          margin: EdgeInsets.only(
              bottom: index < recommendationsList.length - 1 ? 12 : 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF293949).withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF00C8FA).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: const Color(0xFF00C8FA),
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  recommendation,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
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

              // Traffic Recommendations Container
              _buildTrafficRecommendationsContainer(),
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
                          const Tab(icon: Icon(Icons.psychology, size: 20)),
                          const Tab(icon: Icon(Icons.analytics, size: 20)),
                        ]
                      : [
                          // Text + icon tabs for landscape mode
                          const Tab(
                              text: 'Forecast',
                              icon: Icon(Icons.trending_up, size: 20)),
                          const Tab(
                              text: 'Custom Prediction',
                              icon: Icon(Icons.psychology, size: 20)),
                          const Tab(
                              text: 'Summary',
                              icon: Icon(Icons.analytics, size: 20)),
                        ],
                ),
              ),
              SizedBox(
                height:
                    520, // Increased height from 480 to 520 for longer main content
                child: TabBarView(
                  children: [
                    _buildForecastTab(),
                    _buildCustomPredictionTab(),
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
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Time Period Selector
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
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPeriod = period;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF00C8FA)
                                : const Color(0xFF293949),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              period.capitalize(),
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFF1A252F)
                                    : Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: isPortrait ? 11 : 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 12),
          // Forecast Chart
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _forecastDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF00C8FA)));
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

  Widget _buildCustomPredictionTab() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Custom Prediction Section
          Card(
            elevation: 2,
            color: const Color(0xFF1A252F),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Custom Prediction',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00C8FA),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select date and time for traffic prediction',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  // Date Time Selection Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          _isLoadingCustomPrediction ? null : _selectDateTime,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Flexible(
                        child: Text(
                          _selectedDateTime == null
                              ? 'Select Date & Time'
                              : _formatCompactDateTime(_selectedDateTime!),
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C8FA),
                        foregroundColor: const Color(0xFF1A252F),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  if (_isLoadingCustomPrediction) ...[
                    const SizedBox(height: 16),
                    const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00C8FA),
                        strokeWidth: 2,
                      ),
                    ),
                  ],

                  // Custom Prediction Result
                  if (_customPredictionResult != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Prediction Result:',
                            style: TextStyle(
                              color: Color(0xFF00C8FA),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 0),
                          _buildCustomPredictionChart(_customPredictionResult!),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
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

  Widget _buildTrafficRecommendationsContainer() {
    return Container(
      margin: const EdgeInsets.all(12),
      child: Card(
        elevation: 4,
        color: const Color(0xFF293949),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF1A252F),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with icon and title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb,
                            color: Color(0xFF00C8FA), size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'Traffic Recommendations',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab selector
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedRecommendationTab = 0;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 8),
                              decoration: BoxDecoration(
                                color: _selectedRecommendationTab == 0
                                    ? const Color(0xFF00C8FA)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _selectedRecommendationTab == 0
                                      ? const Color(0xFF00C8FA)
                                      : const Color(0xFF00C8FA)
                                          .withOpacity(0.3),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'General',
                                  style: TextStyle(
                                    color: _selectedRecommendationTab == 0
                                        ? const Color(0xFF1A252F)
                                        : const Color(0xFF00C8FA),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedRecommendationTab = 1;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 8),
                              decoration: BoxDecoration(
                                color: _selectedRecommendationTab == 1
                                    ? const Color(0xFF00C8FA)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _selectedRecommendationTab == 1
                                      ? const Color(0xFF00C8FA)
                                      : const Color(0xFF00C8FA)
                                          .withOpacity(0.3),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Custom Prediction',
                                  style: TextStyle(
                                    color: _selectedRecommendationTab == 1
                                        ? const Color(0xFF1A252F)
                                        : const Color(0xFF00C8FA),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Time period selector (only show for general tab)
                  if (_selectedRecommendationTab == 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: DropdownButton<String>(
                        value: _selectedPeriod,
                        dropdownColor: const Color(0xFF1A252F),
                        style: const TextStyle(color: Color(0xFF00C8FA)),
                        underline: Container(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedPeriod = newValue;
                            });
                          }
                        },
                        items: _timePeriods
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value.capitalize()),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(
                minHeight: 200,
                maxHeight: 400,
              ),
              child: _selectedRecommendationTab == 0
                  ? _buildGeneralRecommendations()
                  : _buildCustomPredictionRecommendations(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralRecommendations() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _trafficRecommendationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: Color(0xFF00C8FA)),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading recommendations',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        } else if (snapshot.hasData) {
          return _buildTrafficRecommendations(snapshot.data!);
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildCustomPredictionRecommendations() {
    if (_customPredictionRecommendations != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with gradient background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF00C8FA).withOpacity(0.15),
                    const Color(0xFF0091CC).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00C8FA).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C8FA).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.psychology,
                          color: Color(0xFF00C8FA),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Personalized Recommendations',
                          style: TextStyle(
                            color: Color(0xFF00C8FA),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedDateTime != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF293949).withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule,
                            color: Color(0xFF00C8FA),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatCustomDateTime(_selectedDateTime!),
                            style: const TextStyle(
                              color: Color(0xFF00C8FA),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Enhanced recommendations list
            _buildEnhancedCustomRecommendationsList(
                _customPredictionRecommendations!),
          ],
        ),
      );
    } else if (_isLoadingCustomRecommendations) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF293949).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const CircularProgressIndicator(
                  color: Color(0xFF00C8FA),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Analyzing traffic patterns...',
                style: TextStyle(
                  color: Color(0xFF00C8FA),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Generating personalized recommendations',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF293949).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00C8FA).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: const Color(0xFF00C8FA).withOpacity(0.7),
                      size: 56,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ready for Smart Insights',
                      style: TextStyle(
                        color: Color(0xFF00C8FA),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Make a custom prediction to unlock personalized traffic recommendations tailored to your specific date and time',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
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
          SizedBox(height: isPortrait ? 12 : 16),
          if (recommendationText.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF293949).withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.withOpacity(0.8),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No $_selectedPeriod recommendations available at the moment.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            _buildEnhancedRecommendationText(recommendationText),
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
      ..color = Colors.grey.withOpacity(0.3) // Thin grey grid lines
      ..strokeWidth = 0.5; // Thinner grid lines

    // Draw grid lines
    const gridLines = 5;
    const leftMargin = 20.0; // Add margin for edge labels
    const rightMargin = 20.0; // Add margin for edge labels
    final chartWidth = size.width - leftMargin - rightMargin;
    final stepX = chartWidth /
        (data.length - 1); // Define stepX once for both grids and points

    // Draw horizontal grid lines
    for (int i = 0; i <= gridLines; i++) {
      final y =
          (size.height - 40) * i / gridLines + 20; // Leave space for labels
      canvas.drawLine(
        Offset(leftMargin, y),
        Offset(size.width - rightMargin, y),
        gridPaint,
      );
    }

    // Draw vertical grid lines
    for (int i = 0; i < data.length; i++) {
      final x = leftMargin + (i * stepX);
      canvas.drawLine(
        Offset(x, 20),
        Offset(x, size.height - 20),
        gridPaint,
      );
    }

    // Calculate points
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final yhat = data[i]['yhat']?.toDouble() ?? 0.0;
      final normalizedY = (yhat - minYhat) / (maxYhat - minYhat);
      final x = leftMargin + (i * stepX);
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
      ..color = Colors.grey.withOpacity(0.3) // Thin grey grid lines
      ..strokeWidth = 0.5; // Thinner grid lines

    // Calculate min/max for scaling
    final values = forecastData.map((e) => e['value'] as double).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;
    final paddedMax = maxValue + range * 0.1;
    final paddedMin = (minValue - range * 0.1).clamp(0.0, double.infinity);

    // Draw grid lines
    const gridLines = 5;
    const leftMargin = 20.0; // Add margin for edge labels
    const rightMargin = 20.0; // Add margin for edge labels
    final chartWidth = size.width - leftMargin - rightMargin;
    final stepX = chartWidth / (forecastData.length - 1);

    // Draw horizontal grid lines
    for (int i = 0; i <= gridLines; i++) {
      final y = (size.height - 40) * i / gridLines + 20;
      canvas.drawLine(Offset(leftMargin, y),
          Offset(size.width - rightMargin, y), gridPaint);
    }

    // Draw vertical grid lines
    for (int i = 0; i < forecastData.length; i++) {
      final x = leftMargin + (i * stepX);
      canvas.drawLine(
        Offset(x, 20),
        Offset(x, size.height - 20),
        gridPaint,
      );
    }

    // Calculate points
    final points = <Offset>[];
    for (int i = 0; i < forecastData.length; i++) {
      final value = forecastData[i]['value'] as double;
      final normalizedY = (value - paddedMin) / (paddedMax - paddedMin);
      final x = leftMargin + (i * stepX);
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
