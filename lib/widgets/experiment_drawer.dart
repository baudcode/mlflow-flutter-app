import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/experiment.dart';
import '../providers/experiment_provider.dart';
import '../providers/metric_provider.dart';
import '../providers/run_provider.dart';

class ExperimentDrawer extends StatelessWidget {
  const ExperimentDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final experimentProvider = Provider.of<ExperimentProvider>(context);
    final runProvider = Provider.of<RunProvider>(context, listen: false);
    final metricProvider = Provider.of<MetricProvider>(context, listen: false);
    
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: const Text(
              'Experiments',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Loading indicator
          if (experimentProvider.isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
            
          // Experiments list
          Expanded(
            child: ListView.builder(
              itemCount: experimentProvider.experiments.length,
              itemBuilder: (context, index) {
                final experiment = experimentProvider.experiments[index];
                final isSelected = experimentProvider.selectedExperiment?.experimentId == experiment.experimentId;
                
                return ExperimentListTile(
                  experiment: experiment,
                  isSelected: isSelected,
                  onTap: () {
                    experimentProvider.selectExperiment(experiment);
                    metricProvider.clearFavs();
                    runProvider.clearSelection();
                    runProvider.setMultiSelectionModeActive(false);
                    runProvider.refreshRuns(experiment.experimentId);
                  },
                  onFavoriteToggle: () {
                    experimentProvider.toggleFavorite(experiment);
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

class ExperimentListTile extends StatelessWidget {
  final Experiment experiment;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  
  const ExperimentListTile({
    super.key,
    required this.experiment,
    required this.isSelected,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        experiment.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      leading: IconButton(
        icon: Icon(
          experiment.isFavorite ? Icons.star : Icons.star_border,
          color: experiment.isFavorite ? Colors.amber : null,
        ),
        onPressed: onFavoriteToggle,
      ),
      selected: isSelected,
      onTap: onTap,
      tileColor: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    );
  }
}
