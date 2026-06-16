import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/sessao_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool logado = await SessaoManager.estaLogado();

  runApp(MyApp(telaInicial: logado ? const HomeScreen() : const LoginScreen()));
}

class MyApp extends StatelessWidget {
  final Widget telaInicial;
  const MyApp({super.key, required this.telaInicial});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vó Naná',
      theme: ThemeData(
        primaryColor: const Color(0xFF75A97D),
      ),
      home: telaInicial,
    );
  }
}