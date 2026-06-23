import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../model/game_state.dart';

class SaveService {
  static final _fileName = 'game_save.json';

  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<void> saveGame(GameState state) async {
    final file = await _getFile();
    final jsonString = jsonEncode(state.toJson());
    await file.writeAsString(jsonString);
  }

  static Future<GameState> loadGame() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return GameState();
      final jsonString = await file.readAsString();
      return GameState.fromJson(jsonDecode(jsonString));
    } catch (e) {
      return GameState();
    }
  }

  static Future<void> resetGame() async {
    final file = await _getFile();
    if (await file.exists()) await file.delete();
  }
}
