import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'pagina_pedidos.dart';
import 'pagina_configuracoes.dart';
import 'pagina_cadastro.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indiceAtual = 0;

  final List<Widget> _paginas = [
    const PaginaPedidos(),
    const PaginaCadastro(),
    const PaginaConfiguracoes(),
  ];

  final Color _corFundoMentaSuave = const Color(0xFFF1F4F1);
  final Color _corVerdePrincipal = const Color(0xFF27422C);
  final Color _corTerracotaDestaque = const Color(0xFFBC6C45);
  final Color _corCardLimpo = const Color(0xFFFAFAFA);
  final Color _corBordaSutil = const Color(0xFFDBE2DB);

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

    final Color corIcone = selecionado ? _corVerdePrincipal : _corVerdePrincipal.withOpacity(0.4);
    final Color corTexto = selecionado ? _corVerdePrincipal : _corVerdePrincipal.withOpacity(0.5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: InkWell(
        onTap: () => setState(() => _indiceAtual = indice),
        splashColor: _corVerdePrincipal.withOpacity(0.05),
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selecionado ? const Color(0xFFDFEDE1) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: selecionado ? Border.all(color: _corVerdePrincipal.withOpacity(0.15), width: 1) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icone,
                color: corIcone,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: corTexto,
                  fontSize: 11,
                  fontWeight: selecionado ? FontWeight.w900 : FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _corFundoMentaSuave,

      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _indiceAtual = 1),
        backgroundColor: _corVerdePrincipal,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: _corFundoMentaSuave,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            children: [
              Text(
                "🥚 Vó Naná",
                style: TextStyle(
                  color: _corVerdePrincipal,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _corTerracotaDestaque.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Ovos Caipiras 🐔",
                  style: TextStyle(
                    color: _corTerracotaDestaque,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFCDD2), width: 1),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFC62828), size: 18),
              tooltip: 'Sair do Sistema',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: _corCardLimpo,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    title: Row(
                      children: [
                        Icon(Icons.meeting_room_rounded, color: _corTerracotaDestaque),
                        const SizedBox(width: 8),
                        Text('Fazer Logout?', style: TextStyle(fontWeight: FontWeight.w900, color: _corVerdePrincipal)),
                      ],
                    ),
                    content: const Text(
                      'Você será desconectado e voltará para a tela de acesso.',
                      style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Voltar', style: TextStyle(color: _corVerdePrincipal.withOpacity(0.7), fontWeight: FontWeight.bold)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _executarLogout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Sair', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _indiceAtual,
        children: _paginas,
      ),

      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        height: 85,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _corCardLimpo,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _corBordaSutil, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: _corVerdePrincipal.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: _buildNavItem(Icons.egg_rounded, "Pedidos", 0),
              ),
              const SizedBox(width: 80),
              Expanded(
                child: _buildNavItem(Icons.storefront_rounded, "Configurar", 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}