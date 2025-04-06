import 'package:flutter/foundation.dart';

import '../models/run.dart';
import '../services/api_service.dart';

enum RunSortOption {
  createdTimeDesc,
  createdTimeAsc,
  nameAsc,
  nameDesc,
}

class RunProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Run> _runs = [];
  List<Run> get runs => _runs;
  
  Run? _selectedRun;
  Run? get selectedRun => _selectedRun;

  Set<Run> _selectedRuns = new Set<Run>();
  Set<Run> get selectedRuns => _selectedRuns;
  
  String? _nextPageToken;
  String? get nextPageToken => _nextPageToken;

  bool _multiSelectionModeActive = false;
  bool isMultiSelectionModeActive() => _multiSelectionModeActive;

  void setMultiSelectionModeActive(bool active) {
    _multiSelectionModeActive = active;
    notifyListeners();
  }

  void toggleRunSelecton(Run run) {
    if (isSelected(run)) {
      _selectedRuns.removeWhere((x) => x.info.runId == run.info.runId);
    } else {
      _selectedRuns.add(run);
    }
    if (_selectedRuns.isEmpty) {
      _multiSelectionModeActive = false;
    }
    notifyListeners();
  }
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  RunSortOption _sortOption = RunSortOption.createdTimeDesc;
  RunSortOption get sortOption => _sortOption;

  bool isSelected(Run run) {
    return _selectedRuns.any((x) => x.info.runId == run.info.runId);
  }
  
  Future<void> loadRuns(String experimentId, {bool refresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();
    
    try {
      // Clear the runs list before fetching new data
      if (refresh) {
        _runs.clear();
      }
      
      final result = await _apiService.getLatestRuns(
        experimentId,
        pageToken: refresh ? null : _nextPageToken,
      );
      
      final List<Run> loadedRuns = (result['runs'] as List)
          .map((r) => Run.fromJson(r))
          .toList();
      
      // Add runs to the list and deduplicate by runId
      if (refresh) {
        _runs = loadedRuns.toSet().toList();
      } else {
        _runs = [...loadedRuns].toSet().toList();
      }
      
      _nextPageToken = result['next_page_token'];
      
      // Select the first run if none selected and we have runs
      if (_selectedRuns.isEmpty && _runs.isNotEmpty) {
        _selectedRuns.add(_runs.first); // _selectedRun = _runs.first;
      }
      
      sortRuns();
    } catch (e) {
      print('Error loading runs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void selectRun(Run run) {
    // _selectedRun = run;
    selectedRuns.clear();
    selectedRuns.add(run);
    notifyListeners();
  }
  

  void clearSelection() { 
    _selectedRun = null;
    _selectedRuns.clear();
    notifyListeners();
  }
  
  void setSortOption(RunSortOption option) {
    _sortOption = option;
    sortRuns();
  }
  
  void sortRuns() {
    switch (_sortOption) {
      case RunSortOption.createdTimeDesc:
        _runs.sort((a, b) => b.info.startTime.compareTo(a.info.startTime));
        break;
      case RunSortOption.createdTimeAsc:
        _runs.sort((a, b) => a.info.startTime.compareTo(b.info.startTime));
        break;
      case RunSortOption.nameAsc:
        _runs.sort((a, b) => a.info.runName.compareTo(b.info.runName));
        break;
      case RunSortOption.nameDesc:
        _runs.sort((a, b) => b.info.runName.compareTo(a.info.runName));
        break;
    }
    notifyListeners();
  }
  
  Future<void> refreshRuns(String experimentId) async {
    _nextPageToken = null;
    await loadRuns(experimentId, refresh: true);
  }
  
  void clearRuns() {
    _runs.clear();
    _selectedRuns.clear();
    notifyListeners();
  }
}
