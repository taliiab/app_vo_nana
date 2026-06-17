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
            const SnackBar(content: Text("Configurações salvas! 🐔"), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao salvar: $e"), backgroundColor: Colors.red),
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
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF75A97D).withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: qtdEntregaGratis,
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
        items: List.generate(15, (index) {
          String valor = (index + 1).toString().padLeft(2, '0');
          return DropdownMenuItem(value: valor, child: Text(valor));
        }).toList(),
        onChanged: (novoValor) {
          setState(() => qtdEntregaGratis = novoValor!);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF75A97D)));
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF9ABF9E).withOpacity(0.6),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                ConfigItem(
                  label: "Valor da Dúzia/Extra (R\$):",
                  trailing: ConfigInputBox(
                    controller: _controllerExtra,
                    onChanged: (val) => _formatarMoeda(val, _controllerExtra),
                  ),
                ),
                ConfigItem(
                  label: "Valor do Jumbo (R\$):",
                  trailing: ConfigInputBox(
                    controller: _controllerJumbo,
                    onChanged: (val) => _formatarMoeda(val, _controllerJumbo),
                  ),
                ),
                const Divider(color: Colors.white, height: 30),
                ConfigItem(
                  label: "Valor do Frete Padrão:",
                  trailing: ConfigInputBox(
                    controller: _controllerFrete,
                    onChanged: (val) => _formatarMoeda(val, _controllerFrete),
                  ),
                ),
                ConfigItem(
                  label: "Quantidade para Frete Grátis:",
                  trailing: _buildDropdown(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _salvarDadosNoBanco,
                icon: const Icon(Icons.save_outlined),
                label: const Text("Salvar e Aplicar Tudo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF75A97D),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  elevation: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}