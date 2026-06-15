import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _executarLogin() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
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

    try {
      final apiService = ApiService();
      final resultado = await apiService.fazerLogin(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (resultado != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLogged', true);

        if (resultado['nome'] != null) {
          await prefs.setString('nomeUsuario', resultado['nome']);
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        if (mounted) {
          _mostrarMensagemErro('E-mail ou senha incorretos! ❌');
        }
      }
    } catch (e) {
      if (mounted) {
        _mostrarMensagemErro('Não foi possível conectar ao servidor. Verifique o Back-end! 🌐');
      }
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