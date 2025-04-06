class RunInfo {
  final String runId;
  final String runUuid;
  final String runName;
  final String experimentId;
  final String status;
  final int startTime;
  final int? endTime;

  RunInfo({
    required this.runId,
    required this.runUuid,
    required this.runName,
    required this.experimentId,
    required this.status,
    required this.startTime,
    this.endTime,
  });

  factory RunInfo.fromJson(Map<String, dynamic> json) {
    return RunInfo(
      runId: json['run_id'],
      runUuid: json['run_uuid'],
      runName: json['run_name'] ?? 'Unnamed Run',
      experimentId: json['experiment_id'],
      status: json['status'],
      startTime: json['start_time'],
      endTime: json['end_time'],
    );
  }
}

class Metric {
  final String key;
  double value;
  final int timestamp;
  final int step;
  final String? runId;

  Metric({
    required this.key,
    required this.value,
    required this.timestamp,
    required this.step,
    this.runId,
  });

  factory Metric.fromJson(Map<String, dynamic> json) {
    return Metric(
      key: json['key'],
      value: json['value'] is int ? (json['value'] as int).toDouble() : json['value'],
      timestamp: json['timestamp'],
      step: json['step'],
      runId: json['run_id'],
    );
  }
}

class Parameter {
  final String key;
  final String value;

  Parameter({
    required this.key,
    required this.value,
  });

  factory Parameter.fromJson(Map<String, dynamic> json) {
    return Parameter(
      key: json['key'],
      value: json['value'],
    );
  }
}

class Tag {
  final String key;
  final String value;

  Tag({
    required this.key,
    required this.value,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      key: json['key'],
      value: json['value'],
    );
  }
}

class Run {
  final RunInfo info;
  final List<Metric> metrics;
  final List<Parameter> params;
  final List<Tag> tags;

  Run({
    required this.info,
    required this.metrics,
    required this.params,
    required this.tags,
  });

  factory Run.fromJson(Map<String, dynamic> json) {
    final info = RunInfo.fromJson(json['info']);
    
    final dataMetrics = (json['data']['metrics'] as List?)
        ?.map((m) => Metric.fromJson(m))
        .toList() ?? [];
    
    final params = (json['data']['params'] as List?)
        ?.map((p) => Parameter.fromJson(p))
        .toList() ?? [];
    
    final tags = (json['tags'] as List?)
        ?.map((t) => Tag.fromJson(t))
        .toList() ?? [];

    return Run(
      info: info,
      metrics: dataMetrics,
      params: params,
      tags: tags,
    );
  }
}
