import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../providers/metric_provider.dart';

class MetricFullscreenChart extends StatelessWidget {
  final String metricKey;
  final MetricData metricData;
  final List<Color> chartColors;

  const MetricFullscreenChart({
    super.key,
    required this.metricKey,
    required this.metricData,
    required this.chartColors,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(metricKey),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildChart(context),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
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
        if (metric.value < minValue) {
          minValue = metric.value;
        }
        if (metric.value > maxValue) {
          maxValue = metric.value;
        }
      }
    }

    // Add some padding to the min/max values
    final yPadding = (maxValue - minValue) * 0.1;
    minValue = minValue - yPadding;
    maxValue = maxValue + yPadding;

    // Prepare line chart data
    final lineBarsData = <LineChartBarData>[];
    int colorIndex = 0;

    metricData.runMetrics.forEach((runId, metrics) {
      if (metrics.isEmpty) return;

      final color = chartColors[colorIndex % chartColors.length];
      colorIndex++;

      final spots = metrics.map((metric) {
        return FlSpot(metric.step.toDouble(), metric.value);
      }).toList();

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
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.barIndex;
                final runId = metricData.runMetrics.keys.elementAt(index);
                final runName = metricData.runNames[runId] ?? 'Unknown';

                return LineTooltipItem(
                  '$runName\nStep: ${spot.x.toInt()}\nValue: ${spot.y.toStringAsFixed(6)}',
                  TextStyle(
                    color: chartColors[index % chartColors.length],
                    fontWeight: FontWeight.bold,
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
    );
  }
}
