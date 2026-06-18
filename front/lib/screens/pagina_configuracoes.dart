import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../widgets/config_item.dart';
import '../widgets/config_input_box.dart';

class PaginaConfiguracoes extends StatefulWidget {
  const PaginaConfiguracoes({super.key});

  @override
  State<PaginaConfiguracoes> createState() => _PaginaConfiguracoesState();
}

class _PaginaConfiguracoesState extends State<PaginaConfiguracoes> {
  final Dio _dio = ApiService().dio;
  bool _carregando = true;
  String qtdEntregaGratis = "05";

  final TextEditingController _controllerExtra = TextEditingController();
  final TextEditingController _controllerJumbo = TextEditingController();
  final TextEditingController _controllerFrete = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarDadosDoBanco();
  }

  Future<void> _carregarDadosDoBanco() async {
    try {
      _controllerExtra.text = "0,00";
      _controllerJumbo.text = "0,00";
      _controllerFrete.text = "10,00";

      final responses = await Future.wait([
        _dio.get('/produtos'),
        _dio.get('/configuracoes'),
      ]);

      final List produtos = responses[0].data;
      for (var prod in produtos) {
        String nome = prod['nome'].toString();
        String preco = prod['preco'].toString().replaceAll('.', ',');
        if (nome == 'Extra' || nome == 'Dúzia') _controllerExtra.text = preco;
        else if (nome == 'Jumbo') _controllerJumbo.text = preco;
      }

      final List configuracoes = responses[1].data;
      for (var conf in configuracoes) {
        String chave = conf['chave'].toString();
        String valor = conf['valor'].toString();
        if (chave == 'qtd_frete_gratis' && valor.isNotEmpty) {
          setState(() => qtdEntregaGratis = valor.padLeft(2, '0'));
        } else if (chave == 'valor_frete_padrao' && valor.isNotEmpty) {
          _controllerFrete.text = valor.replaceAll('.', ',');
        }
      }
    } catch (e) {
      debugPrint("Erro ao carregar configurações: $e");
    } finally {
      setState(() => _carregando = false);
    }
  }

  Future<void> _salvarDadosNoBanco() async {
    String precoExtraDb = _controllerExtra.text.replaceAll(',', '.');
    String precoJumboDb = _controllerJumbo.text.replaceAll(',', '.');
    String valorFreteDb = _controllerFrete.text.replaceAll(',', '.');

    try {
      final response = await _dio.post('/configuracoes/salvar-tudo', data: {
        'preco_extra': double.parse(precoExtraDb),
        'preco_jumbo': double.parse(precoJumboDb),
        'qtd_frete_gratis': qtdEntregaGratis,
        'valor_frete_padrao': double.parse(valorFreteDb),
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Configurações salvas com sucesso! 🐔", style: TextStyle(fontWeight: FontWeight.w600)),
              backgroundColor: const Color(0xFF3B5E41),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao salvar: $e", style: const TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controllerExtra.dispose();
    _controllerJumbo.dispose();
    _controllerFrete.dispose();
    super.dispose();
  }

  void _formatarMoeda(String valor, TextEditingController controller) {
    if (valor.isEmpty) return;
    String apenasNumeros = valor.replaceAll(RegExp(r'[^0-9]'), '');
    if (apenasNumeros.isEmpty) {
      controller.text = "0,00";
      return;
    }
    double valorDouble = double.parse(apenasNumeros) / 100;
    String novoTexto = valorDouble.toStringAsFixed(2).replaceAll('.', ',');
    controller.value = TextEditingValue(
      text: novoTexto,
      selection: TextSelection.collapsed(offset: novoTexto.length),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: qtdEntregaGratis,
          icon: const Icon(Icons.expand_more_rounded, color: Color(0xFF27422C), size: 20),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: List.generate(15, (index) {
            String valor = (index + 1).toString().padLeft(2, '0');
            return DropdownMenuItem(
              value: valor,
              child: Text("$valor dúzias/caixas", style: const TextStyle(fontWeight: FontWeight.bold)),
            );
          }).toList(),
          onChanged: (novoValor) => setState(() => qtdEntregaGratis = novoValor!),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF27422C)));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F1),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 20),
              child: Text(
                  "Configurações",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF27422C))
              ),
            ),

            _buildSecaoTitulo("Valores dos Produtos", Icons.egg_rounded),
            _buildCardContainer([
              ConfigItem(label: "Dúzia / Extra", trailing: ConfigInputBox(controller: _controllerExtra, onChanged: (val) => _formatarMoeda(val, _controllerExtra))),
              const Divider(height: 32, thickness: 1, color: Color(0xFFF1F4F1)),
              ConfigItem(label: "Ovo Tipo Jumbo", trailing: ConfigInputBox(controller: _controllerJumbo, onChanged: (val) => _formatarMoeda(val, _controllerJumbo))),
            ]),

            const SizedBox(height: 24),

            _buildSecaoTitulo("Regras de Logística", Icons.delivery_dining_rounded),
            _buildCardContainer([
              ConfigItem(label: "Taxa de Frete Padrão", trailing: ConfigInputBox(controller: _controllerFrete, onChanged: (val) => _formatarMoeda(val, _controllerFrete))),
              const Divider(height: 32, thickness: 1, color: Color(0xFFF1F4F1)),
              ConfigItem(label: "Mínimo para Frete Grátis", trailing: _buildDropdown()),
            ]),

            const SizedBox(height: 36),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _salvarDadosNoBanco,
                icon: const Icon(Icons.save_rounded, size: 22),
                label: const Text("SALVAR ALTERAÇÕES", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1.2)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27422C),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCardContainer(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF27422C).withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 8)
          )
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSecaoTitulo(String titulo, IconData icone) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Row(
        children: [
          Icon(icone, color: const Color(0xFFBC6C45), size: 20),
          const SizedBox(width: 8),
          Text(
              titulo.toUpperCase(),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF27422C), letterSpacing: 1)
          ),
        ],
      ),
    );
  }
}