import 'package:flutter/widgets.dart'; // Add this import
import 'package:shared_preferences/shared_preferences.dart';

import '../models/run.dart';
import '../services/api_service.dart';

class MetricData {
  final String key;
  final Map<String, List<Metric>> runMetrics;
  final Map<String, String> runNames;
  bool isFavorite;

  MetricData({
    required this.key,
    required this.runMetrics,
    required this.runNames,
    this.isFavorite = false,
  });
}

class MetricProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final Map<String, MetricData> _metricsCache = {};
  final Map<String, Map<String, List<Metric>>> _metricsCachePerRunId = {};
  List<String> _visibleMetricKeys = [];
  Set<String> _favoriteMetrics = {};
  List<String> _allMetricKeys = [];

  // bool hasData (String metricKey) {
  //   return _metricsCache.containsKey(metricKey);
  // }

  bool runHasData(String metricKey, String runId) {
    // print("contains key: ${_metricsCachePerRunId.containsKey(runId)}");
    if (_metricsCachePerRunId.containsKey(runId)) {
      // print(
      //     "contains key: ${_metricsCachePerRunId[runId]!.containsKey(metricKey)}");
      return _metricsCachePerRunId[runId]!.containsKey(metricKey);
    }
    return false;
  }

  bool anyRunHasMetric(String metricKey) {
    return _metricsCachePerRunId.values
        .any((runMetrics) => runMetrics.containsKey(metricKey));
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<String> get allMetricKeys => _allMetricKeys;
  Set<String> get favoriteMetrics => _favoriteMetrics;

  // Dict[String, MetricData] get metricsCache => _metricsCache;

  List<String> getSortedMetricKeys() {
    // Return favorites first, then the rest alphabetically
    final favorites =
        _allMetricKeys.where((key) => _favoriteMetrics.contains(key)).toList();
    final others =
        _allMetricKeys.where((key) => !_favoriteMetrics.contains(key)).toList();

    favorites.sort();
    others.sort();

    return [...favorites, ...others];
  }

  void setVisibleMetricKeys(List<String> keys) {
    _visibleMetricKeys = keys;
  }

  Future<void> loadAllMetricKeys(List<Run> runs) async {
    final Set<String> keys = {};

    for (final run in runs) {
      for (final metric in run.metrics) {
        keys.add(metric.key);
      }
    }

    _allMetricKeys = keys.toList()..sort();
    // await _loadFavoriteMetrics();
    notifyListeners();
  }

  List<double> sanitizeMetrics(List<double> metrics) {
    return metrics.map((value) {
      if (value.isNaN || value.isInfinite) {
        return 0.0; // Replace invalid metric values with a default
      }
      return value;
    }).toList();
  }

  Future<MetricData?> getMetricData(
      String metricKey, Iterable<Run> runs) async {
    // if (_metricsCache.containsKey(metricKey)) {
    //   var metricData = _metricsCache[metricKey];
    //   final runIds = runs.map((run) => run.info.runId).toList();
    //   final runNames = {
    //     for (var run in runs)
    //       run.info.runId: run.info.runName
    //   };
    //   final runMetrics = <String, List<Metric>>{};
    //   for (var runId in runIds) {
    //     if (metricData!.runMetrics.containsKey(runId)) {
    //       runMetrics[runId] = metricData!.runMetrics[runId] ?? [];
    //     } else {
    //       runMetrics[runId] = [];
    //     }
    //   }

    //   return MetricData(
    //     key: metricKey,
    //     runMetrics: runMetrics,
    //     runNames: runNames,
    //     isFavorite: _favoriteMetrics.contains(metricKey),
    //   );
    // }


    try {
      final runIds = runs.map((run) => run.info.runId).toList();
      final runNames = {for (var run in runs) run.info.runId: run.info.runName};

      // fetch only missing runIds where metricData key is not found
      final missingRunIds = runIds
          .where((runId) =>
              !_metricsCachePerRunId.containsKey(runId) ||
              !_metricsCachePerRunId[runId]!.containsKey(metricKey))
          .toList();
      print("missing run ids: ${missingRunIds}");

      // Group metrics by run_id
      final Map<String, List<Metric>> runMetrics = {};

      if (missingRunIds.isNotEmpty) {

        final result =
            await _apiService.getBulkMetrics(missingRunIds, metricKey, 100);

        final metrics =
            (result['metrics'] as List).map((m) => Metric.fromJson(m)).toList();

        // Sanitize metric values
        for (final metric in metrics) {
          metric.value = sanitizeMetrics([metric.value]).first;
        }

        for (final metric in metrics) {
          if (metric.runId != null) {
            if (!runMetrics.containsKey(metric.runId)) {
              runMetrics[metric.runId!] = [];
            }
            runMetrics[metric.runId]!.add(metric);
          }
        }

        // Sort each run's metrics by step
        for (final runId in runMetrics.keys) {
          runMetrics[runId]!.sort((a, b) => a.step.compareTo(b.step));
        }
      }

      // Combine cache and fetched run metrics to the final run metrics
      for (final runId in runIds) {
        if (_metricsCachePerRunId.containsKey(runId)) {
          final existingMetrics = _metricsCachePerRunId[runId]!;
          print("found existing metrics for runId: $runId");

          if (existingMetrics.containsKey(metricKey)) {
            runMetrics[runId] = existingMetrics[metricKey] ?? [];
            print(
                "Adding run metrics from cache for runId: $runId: ${runMetrics[runId]!.length}");
          }
        }
      }

      print("Run metrics contain keys ${runMetrics.keys}");

      final metricData = MetricData(
        key: metricKey,
        runMetrics: runMetrics,
        runNames: runNames,
        isFavorite: _favoriteMetrics.contains(metricKey),
      );

      // Cache missingRunIds
      for (final runId in missingRunIds) {
        _metricsCachePerRunId.putIfAbsent(runId, () => {});
        _metricsCachePerRunId[runId]![metricKey] = runMetrics[runId] ?? [];
      }

      _metricsCache[metricKey] = metricData;
      // WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
      return metricData;
    } catch (e) {
      print("returning nulllllll");
      print('Error loading metric $metricKey: $e');
      return null;
    } finally {
      _isLoading = false;
      print("finally called");
      // WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    }
  }

  Future<void> _loadFavoriteMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    _favoriteMetrics = (prefs.getStringList('favorite_metrics') ?? []).toSet();
  }

  Future<void> toggleFavoriteMetric(String metricKey) async {
    final prefs = await SharedPreferences.getInstance();

    if (_favoriteMetrics.contains(metricKey)) {
      _favoriteMetrics.remove(metricKey);
    } else {
      _favoriteMetrics.add(metricKey);
    }

    await prefs.setStringList('favorite_metrics', _favoriteMetrics.toList());

    if (_metricsCache.containsKey(metricKey)) {
      _metricsCache[metricKey]!.isFavorite =
          _favoriteMetrics.contains(metricKey);
    }

    notifyListeners();
  }

  void clearCache() {
    _metricsCache.clear();
    // _metricsCachePerRunId.clear();
    notifyListeners();
  }

  void clearFavs() {
    _favoriteMetrics.clear();
    notifyListeners();
  }

  Future<void> refreshAllMetrics(List<Run> runs) async {
    _metricsCache.clear(); // Clear the cache
    notifyListeners(); // Notify listeners about the cache clear
    await loadAllMetricKeys(runs); // Reload all metric keys
  }

  Future<void> refreshFavoriteMetrics(List<Run> runs) async {
    final favoriteKeys = _favoriteMetrics.toList();
    for (final metricKey in favoriteKeys) {
      _metricsCache.remove(metricKey); // Clear cache for favorite metrics
    }
    notifyListeners(); // Notify listeners about the cache clear
    for (final metricKey in favoriteKeys) {
      await getMetricData(metricKey, runs); // Reload favorite metrics
    }
  }
}
