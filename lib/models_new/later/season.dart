class Season {
  int? seasonId;
  String? title;

  Season({
    this.seasonId,
    this.title,
  });

  factory Season.fromJson(Map<String, dynamic> json) => Season(
    seasonId: json['season_id'] as int?,
    title: json['title'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'season_id': seasonId,
    'title': title,
  };
}
