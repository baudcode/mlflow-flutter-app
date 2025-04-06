import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/experiment.dart';
import '../models/run.dart';
import '../services/api_service.dart';

class ExperimentProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Experiment> _experiments = [];
  List<Experiment> get experiments => _experiments;
  
  Experiment? _selectedExperiment;
  Experiment? get selectedExperiment => _selectedExperiment;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  Future<void> loadExperiments() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final list = await _apiService.getExperiments();
      final prefs = await SharedPreferences.getInstance();
      final favoriteIds = prefs.getStringList('favorite_experiments') ?? [];
      
      // Apply favorites
      for (var exp in list) {
        exp.isFavorite = favoriteIds.contains(exp.experimentId);
      }
      
      // Sort with favorites on top
      list.sort((a, b) {
        if (a.isFavorite && !b.isFavorite) return -1;
        if (!a.isFavorite && b.isFavorite) return 1;
        return a.name.compareTo(b.name);
      });
      
      _experiments = list;
      
      // Select the first experiment if none selected
      if (_selectedExperiment == null && list.isNotEmpty) {
        _selectedExperiment = list.first;
      }
    } catch (e) {
      print('Error loading experiments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void selectExperiment(Experiment experiment) {
    _selectedExperiment = experiment;
    notifyListeners();
  }
  
  Future<void> toggleFavorite(Experiment experiment) async {
    experiment.isFavorite = !experiment.isFavorite;
    
    // Update preferences
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList('favorite_experiments') ?? [];
    
    if (experiment.isFavorite) {
      favoriteIds.add(experiment.experimentId);
    } else {
      favoriteIds.remove(experiment.experimentId);
    }
    
    await prefs.setStringList('favorite_experiments', favoriteIds);
    
    // Resort the list
    _experiments.sort((a, b) {
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      return a.name.compareTo(b.name);
    });
    
    notifyListeners();
  }
}
