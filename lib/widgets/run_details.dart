import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/run.dart';

class RunDetails extends StatelessWidget {
  final Run run;
  
  const RunDetails({super.key, required this.run});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final startTime = DateTime.fromMillisecondsSinceEpoch(run.info.startTime);
    final endTime = run.info.endTime != null
        ? DateTime.fromMillisecondsSinceEpoch(run.info.endTime!)
        : null;
    
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1.0,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      run.info.runName,
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: run.info.status == 'FINISHED'
                          ? Colors.green.withOpacity(0.2)
                          : run.info.status == 'RUNNING'
                              ? Colors.blue.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Text(
                      run.info.status,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: run.info.status == 'FINISHED'
                            ? Colors.green
                            : run.info.status == 'RUNNING'
                                ? Colors.blue
                                : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16.0),
            
            // Info section
            Text(
              'Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            _buildInfoItem(context, 'Run ID', run.info.runId),
            _buildInfoItem(context, 'Started At', dateFormat.format(startTime)),
            if (endTime != null)
              _buildInfoItem(context, 'Ended At', dateFormat.format(endTime)),
            if (endTime != null)
              _buildInfoItem(
                context, 
                'Duration', 
                _formatDuration(endTime.difference(startTime))
              ),
            
            const SizedBox(height: 16.0),
            
            // Metrics section
            Text(
              'Metrics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            run.metrics.isEmpty
                ? const Text('No metrics available')
                : Expanded(
                    child: ListView.builder(
                      itemCount: run.metrics.length,
                      itemBuilder: (context, index) {
                        final metric = run.metrics[index];
                        return _buildMetricItem(context, metric);
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.0,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetricItem(BuildContext context, Metric metric) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    metric.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.w300,
                    ),
                    maxLines: 1, // Limit to one line
                    overflow: TextOverflow.ellipsis, // Truncate with ellipsis
                  ),
                ),
                Text(
                  'Step: ${metric.step}',
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4.0),
            Text(
              metric.value.toStringAsFixed(8),
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds';
    } else {
      return '$twoDigitMinutes:$twoDigitSeconds';
    }
  }
}
