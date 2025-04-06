class Experiment {
  final String experimentId;
  final String name;
  final String artifactLocation;
  final String lifecycleStage;
  // final int lastUpdateTime;
  // final int creationTime;
  bool isFavorite;

  Experiment({
    required this.experimentId,
    required this.name,
    required this.artifactLocation,
    required this.lifecycleStage,
    // required this.lastUpdateTime,
    // required this.creationTime,
    this.isFavorite = false,
  });

  factory Experiment.fromJson(Map<String, dynamic> json) {
    return Experiment(
      experimentId: json['experiment_id'],
      name: json['name'],
      artifactLocation: json['artifact_location'],
      lifecycleStage: json['lifecycle_stage'], // active, 
      // lastUpdateTime: json['last_update_time'],
      // creationTime: json['creation_time'],
    );
    // contains tags as well
  }

  Map<String, dynamic> toJson() {
    return {
      'experiment_id': experimentId,
      'name': name,
      'artifact_location': artifactLocation,
      'lifecycle_stage': lifecycleStage,
      // 'last_update_time': lastUpdateTime,
      // 'creation_time': creationTime,
      'is_favorite': isFavorite,
    };
  }
}
