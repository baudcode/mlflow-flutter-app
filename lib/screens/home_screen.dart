import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/experiment_provider.dart';
import '../providers/metric_provider.dart';
import '../providers/run_provider.dart';
import '../widgets/experiment_drawer.dart';
import '../widgets/metrics_tab.dart';
import '../widgets/run_list_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isDrawerOpen = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load experiments when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExperimentProvider>(context, listen: false).loadExperiments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshData() {
    final experimentProvider = Provider.of<ExperimentProvider>(context, listen: false);
    final runProvider = Provider.of<RunProvider>(context, listen: false);
    final metricProvider = Provider.of<MetricProvider>(context, listen: false);
    
    experimentProvider.loadExperiments();
    
    if (experimentProvider.selectedExperiment != null) {
      runProvider.refreshRuns(experimentProvider.selectedExperiment!.experimentId);
      metricProvider.clearCache();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing data...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final experiment = Provider.of<ExperimentProvider>(context).selectedExperiment;
    
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(experiment?.name ?? 'MLFlow Explorer'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            setState(() {
              _isDrawerOpen = !_isDrawerOpen;
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),   
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Runs'),
            Tab(text: 'Metrics'),
          ],
        ),
      ),
      body: Row(
        children: [
          // Side drawer
          if (_isDrawerOpen)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 250,
              child: const ExperimentDrawer(),
            ),
          
          // Main content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                RunListTab(),
                MetricsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
