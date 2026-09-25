abstract final class GoongConfig {
  // Chỉ dùng tạm khi phát triển. Trước khi commit hoặc phát hành ứng dụng,
  // hãy xóa defaultValue và truyền key bằng --dart-define.
  static const apiKey = String.fromEnvironment(
    'GOONG_API_KEY',
    defaultValue: 'zikAbjHPrg8r4EJqpP7QPBZspe9jU2LGpqiJODjr',
  );
  static const maptilesKey = String.fromEnvironment(
    'GOONG_MAPTILES_KEY',
    defaultValue: 'J0MJNrkNPUqwRY7jyVCPDKJ9Y37OVKMzcnpqBvXv',
  );

  static bool get hasApiKey => apiKey.trim().isNotEmpty;
  static bool get hasMaptilesKey => maptilesKey.trim().isNotEmpty;

  static String get mapStyleUrl =>
      'https://tiles.goong.io/assets/goong_map_highlight.json'
      '?api_key=$maptilesKey';
}
