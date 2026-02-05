class Page {
  int? cid;
  int? page;
  int? duration;

  Page({
    this.cid,
    this.page,
    this.duration,
  });

  factory Page.fromJson(Map<String, dynamic> json) => Page(
    cid: json['cid'] as int?,
    page: json['page'] as int?,
    duration: json['duration'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'cid': cid,
    'page': page,
    'duration': duration,
  };
}
