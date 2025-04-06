import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mlflow_app/widgets/run_details.dart';
import 'package:provider/provider.dart';

import '../models/run.dart';
import '../providers/experiment_provider.dart';
import '../providers/run_provider.dart';

class RunListTab extends StatefulWidget {
  const RunListTab({super.key});

  @override
  State<RunListTab> createState() => _RunListTabState();
}

class _RunListTabState extends State<RunListTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Load runs when experiment is selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final experiment = Provider.of<ExperimentProvider>(context, listen: false)
          .selectedExperiment;
      if (experiment != null) {
        Provider.of<RunProvider>(context, listen: false)
            .loadRuns(experiment.experimentId);
      }
    });

    // Setup scroll controller for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final experiment = Provider.of<ExperimentProvider>(context, listen: false)
          .selectedExperiment;
      final runProvider = Provider.of<RunProvider>(context, listen: false);

      if (experiment != null &&
          !runProvider.isLoading &&
          runProvider.nextPageToken != null) {
        runProvider.loadRuns(experiment.experimentId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final experimentProvider = Provider.of<ExperimentProvider>(context);
    final runProvider = Provider.of<RunProvider>(context);

    // If no experiment is selected
    if (experimentProvider.selectedExperiment == null) {
      return const Center(
        child: Text('No experiment selected'),
      );
    }

    return Column(
      children: [
        // Sort options
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Sort by: '),
              DropdownButton<RunSortOption>(
                value: runProvider.sortOption,
                onChanged: (RunSortOption? value) {
                  if (value != null) {
                    runProvider.setSortOption(value);
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: RunSortOption.createdTimeDesc,
                    child: Text('Newest First'),
                  ),
                  DropdownMenuItem(
                    value: RunSortOption.createdTimeAsc,
                    child: Text('Oldest First'),
                  ),
                  DropdownMenuItem(
                    value: RunSortOption.nameAsc,
                    child: Text('Name (A-Z)'),
                  ),
                  DropdownMenuItem(
                    value: RunSortOption.nameDesc,
                    child: Text('Name (Z-A)'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Runs list and details
        Expanded(
          child: Row(
            children: [
              // Run list
              Expanded(
                flex: 2,
                child: runProvider.isLoading && runProvider.runs.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : runProvider.runs.isEmpty
                        ? const Center(child: Text('No runs found'))
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: runProvider.runs.length +
                                (runProvider.isLoading ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == runProvider.runs.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final run = runProvider.runs[index];
                              final isSelected = runProvider.isSelected(run);

                              return RunListItem(
                                run: run,
                                isSelected: isSelected,
                                onTap: () {
                                  if (runProvider.isMultiSelectionModeActive()) {
                                    runProvider.toggleRunSelecton(run);
                                  } else {
                                    runProvider.selectRun(run);
                                  }
                                },
                                onLongPress: () {
                                  runProvider.selectRun(run);
                                  runProvider.setMultiSelectionModeActive(true);
                                }
                              );
                            },
                          ),
              ),

              
            ]..addAll((runProvider.selectedRuns.length == 1) ? [
              // Run details
              Expanded(
                flex: 2,
                child: RunDetails(run: runProvider.selectedRuns.first)
              ),
            ]: []),
          ),
        ),
      ],
    );
  }
}

class RunListItem extends StatelessWidget {
  final Run run;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const RunListItem({
    super.key,
    required this.run,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final startTime = DateTime.fromMillisecondsSinceEpoch(run.info.startTime);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: ListTile(
        title: Text(
          run.info.runName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          'Started: ${dateFormat.format(startTime)}',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: run.info.status == 'FINISHED'
                ? Colors.green.withOpacity(0.2)
                : run.info.status == 'RUNNING'
                    ? Colors.blue.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Text(
            run.info.status,
            style: TextStyle(
              fontSize: 12,
              color: run.info.status == 'FINISHED'
                  ? Colors.green
                  : run.info.status == 'RUNNING'
                      ? Colors.blue
                      : Colors.grey,
            ),
          ),
        ),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
