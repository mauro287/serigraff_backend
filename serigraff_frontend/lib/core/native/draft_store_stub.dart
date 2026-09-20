import 'dart:typed_data';

class NativeDraftStore {
  NativeDraftStore({String? directory});
  Future<Map<String, dynamic>?> read(String key) async => null;
  Future<void> write(String key, Map<String, dynamic> data) async =>
      throw UnsupportedError('Solo móvil');
  Future<void> delete(String key) async {}
  Future<void> savePhoto(String key, Uint8List bytes) async =>
      throw UnsupportedError('Solo móvil');
  Future<Uint8List?> photo(String key) async => null;
}
