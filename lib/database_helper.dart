import 'package:postgres/postgres.dart';

class DatabaseHelper {
  static const String _host = '10.0.2.2';
  static const String _dbName = 'rasa';
  static const String _user = 'postgres';
  static const String _pass = 'admin';

  Future<Connection> abrirConexao() async {
    return await Connection.open(
      Endpoint(
        host: _host,
        port: 5432,
        database: _dbName,
        username: _user,
        password: _pass,
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );
  }
}