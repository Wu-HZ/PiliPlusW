// ignore_for_file: constant_identifier_names
enum SearchType {
  // all('综合'),
  // 视频：video
  video('视频'),
  // 直播间及主播：live
  // live,
  // 直播间：live_room
  live_room('直播间'),
  // 主播：live_user
  // live_user,
  // 话题：topic
  // topic,
  // 用户：bili_user
  bili_user('用户'),
  // 专栏：article
  article('专栏'),
  ;
  // 相簿：photo
  // photo

  final String label;
  const SearchType(this.label);
}
