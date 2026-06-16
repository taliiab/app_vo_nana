import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/banco_helper.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _esconderSenha = true;

  final BancoHelper _dbHelper = BancoHelper();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _executarLogin() async {
    final String email = _emailController.text.trim();
    final String senha = _passwordController.text;

    if (email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos! ⚠️'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final apiService = ApiService();
      final resultado = await apiService.fazerLogin(email, senha);

      if (resultado != null) {
        await _dbHelper.cadastrarUsuario(email, senha);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLogged', true);

        if (resultado['nome'] != null) {
          await prefs.setString('nomeUsuario', resultado['nome']);
        }

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
                (Route<dynamic> route) => false,
          );
        }
        return;
      } else {
        print("Servidor retornou nulo. Verificando credenciais locais no SQLite...");

        bool autenticadoLocal = await _dbHelper.verificarLogin(email, senha);

        if (autenticadoLocal) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLogged', true);

          if (prefs.getString('nomeUsuario') == null) {
            await prefs.setString('nomeUsuario', email.split('@')[0]);
          }

          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Modo offline ativo!'),
              backgroundColor: Colors.blueAccent,
            ),
          );

          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (Route<dynamic> route) => false,
            );
          }
          return;
        } else {
          if (mounted) {
            _mostrarMensagemErro('E-mail ou senha incorretos! ❌');
          }
        }
      }
    } catch (e) {
      print("Erro capturado no catch da tela: $e");
      _mostrarMensagemErro('Ocorreu um erro inesperado no sistema.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _mostrarMensagemErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 140,
                child: Image.asset(
                  'assets/images/vo_nana.jpg',
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Vó Naná',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF75A97D),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Ovos frescos de galinhas livres 🥚🐔',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF75A97D)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFF75A97D), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: _esconderSenha,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF75A97D)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _esconderSenha ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: const Color(0xFF75A97D),
                    ),
                    onPressed: () {
                      setState(() {
                        _esconderSenha = !_esconderSenha;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFF75A97D), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: 250,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _executarLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF75A97D),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF75A97D).withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Entrar',
                    style: TextStyle(fontSize: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}