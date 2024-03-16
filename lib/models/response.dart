class Output {
  final List<List<num>> locations;
  final List<num> classes;
  final List<num> scores;
  final num numberOfDetections;

  Output({
    required this.locations,
    required this.classes,
    required this.scores,
    required this.numberOfDetections,
  });

  factory Output.fromJson(Map<String, dynamic> json) {
    return Output(
      locations: (json['locations'] as List).map((e) => e as List<num>).toList(),
      classes: (json['classes'] as List).map((e) => e as num).toList(),
      scores: (json['scores'] as List).map((e) => e as num).toList(),
      numberOfDetections: json['numberOfDetections'],
    );
  }
}
