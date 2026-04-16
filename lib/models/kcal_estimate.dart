class KcalEstimate {
  final int kcalMin;
  final int kcalMax;
  final int kcalRecommend;
  final String explanation;

  const KcalEstimate({
    required this.kcalMin,
    required this.kcalMax,
    required this.kcalRecommend,
    required this.explanation,
  });

  factory KcalEstimate.fromMap(Map<String, dynamic> map) {
    return KcalEstimate(
      kcalMin: (map['kcalMin'] as num).toInt(),
      kcalMax: (map['kcalMax'] as num).toInt(),
      kcalRecommend: (map['kcalRecommend'] as num).toInt(),
      explanation: map['explanation'] as String,
    );
  }
}
