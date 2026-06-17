import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class BancoHelper {
  static final BancoHelper _instancia = BancoHelper._internal();
  factory BancoHelper() => _instancia;
  BancoHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return await openDatabase('vonana_usuarios_web.db', version: 1, onCreate: _onCreate);
    }

    String caminhoBanco = join(await getDatabasesPath(), 'vonana_usuarios.db');
    return await openDatabase(
      caminhoBanco,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE,
        password TEXT
      )
    ''');
  }

  String _criptografarSenha(String senha) {
    final bytes = utf8.encode(senha);
    return sha256.convert(bytes).toString();
  }

  Future<int> cadastrarUsuario(String email, String password) async {
    final db = await database;
    String senhaProtegida = _criptografarSenha(password);

    try {
      return await db.insert(
        'usuarios',
        {'email': email.trim().toLowerCase(), 'password': senhaProtegida},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print("Erro ao salvar no SQLite: $e");
      return -1;
    }
  }

  Future<bool> verificarLogin(String email, String password) async {
    final db = await database;
    String senhaProtegida = _criptografarSenha(password);

    final List<Map<String, dynamic>> resultado = await db.query(
      'usuarios',
      where: 'email = ? AND password = ?',
      whereArgs: [email.trim().toLowerCase(), senhaProtegida],
    );
    return resultado.isNotEmpty;
  }
}