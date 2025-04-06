import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:mlflow_app/models/run.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/metric_provider.dart';
import '../providers/run_provider.dart';
import 'metric_fullscreen_chart.dart'; // Import the fullscreen chart screen

class MetricsTab extends StatefulWidget {
  const MetricsTab({super.key});

  @override
  State<MetricsTab> createState() => _MetricsTabState();
}

class _MetricsTabState extends State<MetricsTab> {
  final List<Color> _chartColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.cyan,
    Colors.amber,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
  ];

  bool _showFavoritesOnly = true;
  // List<String> _selectedMetrics = []; // Track selected metrics

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final runProvider = Provider.of<RunProvider>(context, listen: false);
      final metricProvider = Provider.of<MetricProvider>(context, listen: false);
      await loadNewMetricData(runProvider, metricProvider);

      runProvider.addListener(() async {
        await loadNewMetricData(runProvider, metricProvider);
      });

    });
  }

  loadNewMetricData(RunProvider runProvider, MetricProvider metricProvider) async {
    if (runProvider.runs.isNotEmpty) {
        await metricProvider.loadAllMetricKeys(runProvider.runs);
        final _selectedMetricKeys = metricProvider.favoriteMetrics;
        for (final metricKey in _selectedMetricKeys) {
          await metricProvider.getMetricData(metricKey, runProvider.runs);
        }
      }
  }

  @override
  Widget build(BuildContext context) {
    final runProvider = Provider.of<RunProvider>(context);
    final metricProvider = Provider.of<MetricProvider>(context);

    if (runProvider.runs.isEmpty) {
      return const Center(
        child: Text('No runs available to show metrics'),
      );
    }

    if (metricProvider.allMetricKeys.isEmpty) {
      print("all metric keys empty");
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final allMetricKeys = metricProvider.allMetricKeys;
    final _selectedMetricKeys = metricProvider.favoriteMetrics;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Metrics'),
        actions: [
          // IconButton(
          //   icon: Icon(
          //     _showFavoritesOnly ? Icons.star : Icons.star_border,
          //     color: _showFavoritesOnly ? Colors.amber : null,
          //   ),
          //   onPressed: () {

          //     // setState(() {
          //     //   _showFavoritesOnly = !_showFavoritesOnly;
          //     // });
          //   },
          // ),
          // IconButton(
          //   icon: const Icon(Icons.settings),
          //   onPressed: () {
          //     Navigator.of(context).pushNamed('/settings');
          //   },
          // ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              if (_showFavoritesOnly) {
                await metricProvider.refreshFavoriteMetrics(runProvider.runs);
              } else {
                await metricProvider.refreshAllMetrics(runProvider.runs);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Metric selection chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: allMetricKeys.map((metricKey) {
                final isSelected = metricProvider.favoriteMetrics.contains(metricKey);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: FilterChip(
                    label: Text(metricKey),
                    selected: isSelected,
                    onSelected: (selected) async {
                      setState(() {
                        if (selected) {
                          metricProvider.toggleFavoriteMetric(metricKey);
                        } else {
                          metricProvider.toggleFavoriteMetric(metricKey);
                        }
                      });

                      // if (selected) {
                      //   await metricProvider.getMetricData(metricKey, runProvider.runs);
                      // }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8.0),

          // Metric charts grid
          Expanded(
            child: _selectedMetricKeys.isEmpty
                ? const Center(child: Text('No metrics selected'))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // Determine crossAxisCount based on screen width
                      final crossAxisCount = (constraints.maxWidth / 600).toInt() + 1;

                      return MasonryGridView.count(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                        itemCount: _selectedMetricKeys.length,
                        itemBuilder: (context, index) {
                          final metricKey = _selectedMetricKeys.elementAt(index);

                          return MetricChart(
                            metricKey: metricKey,
                            chartColors: _chartColors,
                            onToggleFavorite: () async {
                              await metricProvider.toggleFavoriteMetric(metricKey);
                            },
                            isFavorite: metricProvider.favoriteMetrics.contains(metricKey),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class MetricChart extends StatelessWidget {
  final String metricKey;
  final List<Color> chartColors;
  final VoidCallback onToggleFavorite;
  final bool isFavorite;

  const MetricChart({
    super.key,
    required this.metricKey,
    required this.chartColors,
    required this.onToggleFavorite,
    required this.isFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final metricProvider = Provider.of<MetricProvider>(context);
    final runProvider = Provider.of<RunProvider>(context);

    print("Multi selection mode active: ${runProvider.isMultiSelectionModeActive()}");
    Iterable<Run> runs = (runProvider.isMultiSelectionModeActive()) ? runProvider.selectedRuns : runProvider.runs;
    print("Selected Runs: : ${runProvider.selectedRuns.map((e) => e.info.runName).toList()}");

    return FutureBuilder<MetricData?>(
      future: metricProvider.getMetricData(metricKey, runs),
      builder: (context, snapshot) {
        print("FutureBuilder Metrics: ${snapshot.connectionState}");
        if (snapshot.connectionState == ConnectionState.done) {
          print("FutureBuilder Metrics: ${snapshot.data!.runNames}");
          print("FutureBuilder Metrics: ${snapshot.data!.runMetrics.keys}");
        }
        return GestureDetector(
          onTap: () {
            if (snapshot.hasData && snapshot.data != null) {
              // final runId = runProvider.selectedRun!.info.runId;
              // if (!snapshot.data!.runMetrics.containsKey(runId) || snapshot.data!.runMetrics[runId]!.isEmpty) {
              //   ScaffoldMessenger.of(context).showSnackBar(
              //     const SnackBar(content: Text('No data available for this metric')),
              //   );
              //   return;
              // }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => MetricFullscreenChart(
                    metricKey: metricKey,
                    metricData: snapshot.data!,
                    chartColors: chartColors,
                  ),
                ),
              );
            }
          },
          child: Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chart header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          metricKey,
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1, // Limit to one line
                          overflow: TextOverflow.ellipsis, // Truncate with ellipsis
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.star : Icons.star_border,
                          color: isFavorite ? Colors.amber : null,
                        ),
                        onPressed: onToggleFavorite,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8.0),

                  // Chart area
                  if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting)
                    _buildLoadingPlaceholder(context)
                  else if (snapshot.data == null || snapshot.data!.runMetrics.isEmpty)
                    const SizedBox(
                      height: 200,
                      child: Center(child: Text('No data available')),
                    )
                  else
                    SizedBox(
                      height: 250,
                      child: _buildChart(context, snapshot.data!),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingPlaceholder(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceVariant,
      highlightColor: Theme.of(context).colorScheme.surface,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context, MetricData metricData) {
    // Find the maximum step value to set proper x-axis range
    int maxStep = 0;
    for (final runMetrics in metricData.runMetrics.values) {
      if (runMetrics.isNotEmpty) {
        final lastStep = runMetrics.last.step;
        if (lastStep > maxStep) {
          maxStep = lastStep;
        }
      }
    }

    // Find min and max values for better y-axis scaling
    double minValue = double.infinity;
    double maxValue = double.negativeInfinity;

    for (final runMetrics in metricData.runMetrics.values) {
      for (final metric in runMetrics) {
        final sanitizedValue = metric.value.isNaN || metric.value.isInfinite ? 0.0 : metric.value;
        if (sanitizedValue < minValue) {
          minValue = sanitizedValue;
        }
        if (sanitizedValue > maxValue) {
          maxValue = sanitizedValue;
        }
      }
    }

    // Add some padding to the min/max values
    if (minValue == double.infinity || maxValue == double.negativeInfinity) {
      // Fallback for empty or invalid data
      minValue = 0.0;
      maxValue = 1.0;
    } else {
      final yPadding = (maxValue - minValue) * 0.1;
      minValue -= yPadding;
      maxValue += yPadding;
    }

    // Prepare line chart data
    final lineBarsData = <LineChartBarData>[];
    int colorIndex = 0;

    metricData.runMetrics.forEach((runId, metrics) {
      if (metrics.isEmpty) return;

      final color = chartColors[colorIndex % chartColors.length];
      colorIndex++;

      final spots = metrics.map((metric) {
        final sanitizedValue = metric.value.isNaN || metric.value.isInfinite ? 0.0 : metric.value;
        return FlSpot(metric.step.toDouble(), sanitizedValue);
      }).toList();

      // Debugging log for spots
      print('Run ID: $runId, Spots: ${spots.length}');

      lineBarsData.add(
        LineChartBarData(
          spots: spots,
          isCurved: false,
          color: color,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );
    });

    // Build the chart
    return Column(
      children: [
        Expanded(
          child: LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  fitInsideVertically: true,
                  tooltipBgColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  getTooltipItems: (List<LineBarSpot> touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.barIndex;
                      final runId = metricData.runMetrics.keys.elementAt(index);
                      final runName = metricData.runNames[runId] ?? 'Unknown';

                      return LineTooltipItem(
                        '${spot.y.toStringAsFixed(6)}',
                        TextStyle(
                          color: chartColors[index % chartColors.length],
                          fontWeight: FontWeight.w400,
                          fontSize: 12
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                drawHorizontalLine: true,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Theme.of(context).dividerColor,
                    strokeWidth: 0.8,
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: Theme.of(context).dividerColor,
                    strokeWidth: 0.8,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 55,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          value.toStringAsFixed(2),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
              minX: 0,
              maxX: maxStep.toDouble(),
              minY: minValue,
              maxY: maxValue,
              lineBarsData: lineBarsData,
            ),
          ),
        ),

        // Legend
        const SizedBox(height: 8.0),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: metricData.runMetrics.keys.map((runId) {
              final index = metricData.runMetrics.keys.toList().indexOf(runId);
              final color = chartColors[index % chartColors.length];
              final name = metricData.runNames[runId] ?? 'Unknown';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: color,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      name,
                      style: const TextStyle(fontSize: 12.0),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
