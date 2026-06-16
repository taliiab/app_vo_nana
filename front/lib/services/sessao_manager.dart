import 'package:shared_preferences/shared_preferences.dart';

class SessaoManager {
  static const String _chaveLogado = "LOGADO";
  static const String _chaveUsuario = "USERNAME_ATUAL";

  static Future<void> salvarSessao(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chaveLogado, true);
    await prefs.setString(_chaveUsuario, username);
  }

  static Future<void> encerrarSessao() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chaveLogado, false);
    await prefs.remove(_chaveUsuario);
  }

  static Future<bool> estaLogado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_chaveLogado) ?? false;
  }
}