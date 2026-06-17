import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'pagina_pedidos.dart';
import 'pagina_configuracoes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indiceAtual = 0;

  final List<Widget> _paginas = [
    const PaginaPedidos(),
    const PaginaConfiguracoes(),
  ];

  Future<void> _executarLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLogged', false);

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  Widget _buildNavItem(IconData icone, String label, int indice) {
    final bool selecionado = _indiceAtual == indice;
    return GestureDetector(
      onTap: () {
        setState(() {
          _indiceAtual = indice;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, color: selecionado ? Colors.white : Colors.white60, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: selecionado ? Colors.white : Colors.white60,
              fontSize: 12,
              fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "🥚 Vó Naná - Ovos de galinhas livres 🐔",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF75A97D),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sair do Sistema',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Fazer Logout? 🚪'),
                  content: const Text('Você será desconectado e voltará para a tela de login.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _executarLogout();
                      },
                      child: const Text('Sair', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _indiceAtual,
        children: _paginas,
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: Color(0xFF75A97D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.egg_outlined, "Pedidos", 0),
            _buildNavItem(Icons.settings_outlined, "Definições", 1),
          ],
        ),
      ),
    );
  }
}