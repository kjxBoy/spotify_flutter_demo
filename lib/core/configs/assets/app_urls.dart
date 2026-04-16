class AppURLs {
  static const String _base =
      'https://spotify-demo-6gp153e810cbb8fc-1331434937.tcloudbaseapp.com';

  static String songCoverUrl(String artist, String title) {
    return '$_base/spotify_photo/${_cleanArtist(artist)}-${_cleanTitle(title)}.jpg';
  }

  static String songMusicUrl(String artist, String title) {
    return '$_base/spotify_music/${_cleanArtist(artist)}-${_cleanTitle(title)}.mp3';
  }

  /// 多艺术家（逗号分隔）只取第一个，并去除空格
  static String _cleanArtist(String s) =>
      s.split(',').first.replaceAll(' ', '');

  static String _cleanTitle(String s) => s.replaceAll(' ', '');
}
