import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Private app files, partitioned by authenticated user and quote ID.
/// Never stored in the shared gallery or external storage.
class NativeDraftStore {
  NativeDraftStore({this.directory});
  final String? directory;
  Future<File> _file(String key, String extension) async {
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(key)) {
      throw ArgumentError('Invalid draft key');
    }
    final root = directory != null
        ? Directory(directory!)
        : await getApplicationSupportDirectory();
    final draftDirectory = await Directory('${root.path}/native_drafts')
        .create(recursive: true);
    return File('${draftDirectory.path}/$key.$extension');
  }

  Future<Map<String, dynamic>?> read(String key) async {
    final file = await _file(key, 'json');
    if (!await file.exists()) return null;
    return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  }

  Future<void> write(String key, Map<String, dynamic> data) async {
    final file = await _file(key, 'json');
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode(data), flush: true);
    await temp.rename(file.path);
  }

  Future<void> delete(String key) async {
    for (final ext in ['json', 'jpg', 'json.tmp', 'jpg.tmp']) {
      final file = await _file(key, ext);
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> savePhoto(String key, Uint8List bytes) async {
    if (bytes.length > 10 * 1024 * 1024) {
      throw const FormatException('La foto supera los 10 MB.');
    }
    final file = await _file(key, 'jpg');
    final temp = File('${file.path}.tmp');
    await temp.writeAsBytes(bytes, flush: true);
    await temp.rename(file.path);
  }

  Future<Uint8List?> photo(String key) async {
    final file = await _file(key, 'jpg');
    return await file.exists() ? file.readAsBytes() : null;
  }
}
