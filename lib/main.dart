import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

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

  // Current selected time period
  String _selectedPeriod = 'hourly';

  // Available time periods
  final List<String> _timePeriods = ['hourly', 'daily', 'weekly', 'monthly'];

  @override
  void initState() {
    super.initState();
    // Initialize the futures when the widget is created.
    _trafficRecommendationsFuture = _loadTrafficRecommendations();
    _forecastDataFuture = _loadForecastData();
  }

  // Asynchronously loads traffic recommendations from local JSON file.
  Future<Map<String, dynamic>> _loadTrafficRecommendations() async {
    try {
      String jsonString = await rootBundle
          .loadString('assets/daily_end_user_traffic_recommendation.json');
      final data = json.decode(jsonString);
      return data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load traffic recommendations: $e');
    }
  }

  // Asynchronously loads forecast data from local JSON file.
  Future<Map<String, dynamic>> _loadForecastData() async {
    try {
      String jsonString =
          await rootBundle.loadString('assets/daily_forecast.json');
      final data = json.decode(jsonString);
      return data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load forecast data: $e');
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
          return '${date.hour.toString().padLeft(2, '0')}:00';
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
          return 'W${((date.day - 1) ~/ 7) + 1}';
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
        maxItems = 12; // Show 12 hours
        break;
      case 'daily':
        maxItems = 7; // Show 7 days
        break;
      case 'weekly':
        maxItems = 4; // Show 4 weeks
        break;
      case 'monthly':
        maxItems = 6; // Show 6 months
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
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: CustomPaint(
                size: Size(
                    double.infinity,
                    MediaQuery.of(context).orientation == Orientation.landscape
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF192A31), // New background color
      appBar: AppBar(
        title: const Text('C4 Road - Malabon City'),
        backgroundColor: const Color(0xFF192A31), // New app bar background
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: const Color(0xFF00C8FA), // New refresh indicator color
        onRefresh: () async {
          setState(() {
            _trafficRecommendationsFuture = _loadTrafficRecommendations();
            _forecastDataFuture = _loadForecastData();
          });
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
                    Text('Updated: ${DateTime.now().toString().split('.')[0]}',
                        style: const TextStyle(
                            color: Color(0xFFB0BEC5))), // Light Gray
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
              future: _trafficRecommendationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                } else if (snapshot.hasError) {
                  return const SizedBox.shrink();
                } else if (snapshot.hasData) {
                  final data = snapshot.data!;
                  final summaryText = data['summary_reco'] as String? ?? '';

                  if (summaryText.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Traffic Summary',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                                color: const Color(0xFFFFFFFF)), // White text
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 2,
                        color: const Color(0xFF293949), // New card color
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildRecommendationText(summaryText),
                        ),
                      ),
                    ],
                  );
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
