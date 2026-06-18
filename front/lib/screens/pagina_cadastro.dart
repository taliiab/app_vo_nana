import 'dart:math' as java_math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';

class PaginaCadastro extends StatefulWidget {
  const PaginaCadastro({super.key});

  @override
  State<PaginaCadastro> createState() => _PaginaCadastroState();
}

class _PaginaCadastroState extends State<PaginaCadastro> {
  int _etapaAtual = 0;
  bool _carregandoEnvio = false;
  bool _carregandoProdutos = true;
  String? _erroConexao;

  final String _baseUrl = 'http://200.18.74.27:8082';

  final Color _corVerdePrincipal = const Color(0xFF27422C);
  final Color _corTerracotaDestaque = const Color(0xFFBC6C45);
  final Color _corCardLimpo = const Color(0xFFFAFAFA);
  final Color _corBordaSutil = const Color(0xFFDBE2DB);

  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();

  List<dynamic> _produtosDoBanco = [];
  Map<String, dynamic>? _produtoSelecionadoObj;
  double _precoProdutoSelecionado = 0.0;
  final _quantidadeController = TextEditingController(text: "1");

  String _metodoPagamento = "Dinheiro";
  final List<String> _formasPagamento = ["Dinheiro", "PIX", "Crédito", "Débito"];

  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cepController = TextEditingController();
  final _complementoController = TextEditingController();
  DateTime? _dataEntregaSelecionada;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buscarProdutosDoBanco();
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _quantidadeController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cepController.dispose();
    _complementoController.dispose();
    super.dispose();
  }

  Future<void> _buscarProdutosDoBanco() async {
    setState(() {
      _carregandoProdutos = true;
      _erroConexao = null;
    });

    try {
      final url = Uri.parse('$_baseUrl/produtos');

      final response = await http.get(url).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          print("Tempo limite esgotado.");
          throw Exception("Tempo limite esgotado.");
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> dados = jsonDecode(response.body);
        setState(() {
          _produtosDoBanco = dados.where((p) => p["ativo"] == null || p["ativo"] == true).toList();

          if (_produtosDoBanco.isNotEmpty) {
            _produtoSelecionadoObj = _produtosDoBanco[0];
            _precoProdutoSelecionado = double.tryParse(_produtoSelecionadoObj!["preco"].toString()) ?? 0.0;
          } else {
            _erroConexao = "Nenhum produto ativo encontrado no banco.";
          }
          _carregandoProdutos = false;
        });
      } else {
        setState(() {
          _erroConexao = "Erro no servidor (Status: ${response.statusCode})";
          _carregandoProdutos = false;
        });
      }
    } catch (e) {
      print("Capturado no bloco catch: $e");
      setState(() {
        _erroConexao = "Conexão recusada ou timeout.";
        _carregandoProdutos = false;
      });
    }
  }

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? escolhida = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: _corVerdePrincipal, onPrimary: Colors.white, onSurface: _corVerdePrincipal),
          ),
          child: child!,
        );
      },
    );
    if (escolhida != null) setState(() => _dataEntregaSelecionada = escolhida);
  }

  bool _validarEtapaAtual() {
    if (_etapaAtual == 0) {
      if (_nomeController.text.trim().isEmpty) {
        _notificar("Por favor, preencha o Nome Completo do cliente.");
        return false;
      }
      if (_telefoneController.text.trim().isEmpty) {
        _notificar("Por favor, preencha o WhatsApp do cliente.");
        return false;
      }
    }

    if (_etapaAtual == 1) {
      if (_produtoSelecionadoObj == null || _produtoSelecionadoObj!["id"] == null) {
        _notificar("Selecione um produto válido da lista.");
        return false;
      }
      final int? qtd = int.tryParse(_quantidadeController.text);
      if (qtd == null || qtd <= 0) {
        _notificar("Insira uma quantidade válida maior que zero.");
        return false;
      }
    }

    if (_etapaAtual == 2) {
      if (_dataEntregaSelecionada == null) {
        _notificar("Por favor, selecione a Data de Entrega.");
        return false;
      }
      if (_ruaController.text.trim().isEmpty) {
        _notificar("Por favor, preencha o campo Rua / Avenida.");
        return false;
      }
      if (_numeroController.text.trim().isEmpty) {
        _notificar("Por favor, preencha o Número da residência.");
        return false;
      }
      if (_bairroController.text.trim().isEmpty) {
        _notificar("Por favor, preencha o Bairro.");
        return false;
      }
      if (_cepController.text.trim().isEmpty) {
        _notificar("Por favor, preencha o CEP.");
        return false;
      }
    }

    return true;
  }

  Future<void> _finalizarESalvarPedido() async {

    if (!_validarEtapaAtual()) return;

    setState(() => _carregandoEnvio = true);

    if (_dataEntregaSelecionada == null) {
      _notificar('Por favor, selecione uma data para a entrega.');
      return;
    }

    if (_nomeController.text.trim().isEmpty || _telefoneController.text.trim().isEmpty) {
      _notificar('Por favor, preencha o nome e o WhatsApp do cliente.');
      return;
    }

    if (_produtoSelecionadoObj == null) {
      _notificar('Por favor, selecione um produto válido.');
      return;
    }

    if (_produtoSelecionadoObj!["id"] == null) {
      _notificar('Erro: o produto não está disponível.');
      return;
    }

    print("Enviando pedido para o banco.");
    setState(() => _carregandoEnvio = true);

    final url = Uri.parse('$_baseUrl/pedidos/cadastrar');
    final int quantidade = int.tryParse(_quantidadeController.text) ?? 1;
    final double subtotal = _precoProdutoSelecionado * quantidade;
    final String idWhatsapp = _telefoneController.text.replaceAll(RegExp(r'[^\d]'), '');

    final int semente = DateTime.now().microsecondsSinceEpoch;
    final javaRandom = java_math.Random(semente);
    final String idPedidoRandom = (semente % 90000000 + 10000000).toString();

    final int idProduto = int.tryParse(_produtoSelecionadoObj!["id"].toString()) ?? 0;

    final Map<String, dynamic> dadosPedido = {
      "id_pedido": idPedidoRandom,
      "subtotal": subtotal,
      "total": subtotal,
      "metodo_pagamento": _metodoPagamento,
      "data_entrega": "${_dataEntregaSelecionada!.year}-${_dataEntregaSelecionada!.month.toString().padLeft(2, '0')}-${_dataEntregaSelecionada!.day.toString().padLeft(2, '0')}",
      "cliente": {
        "id_whatsapp": idWhatsapp,
        "nome": _nomeController.text.trim()
      },
      "endereco": {
        "rua": _ruaController.text.trim(),
        "numero": _numeroController.text.trim(),
        "bairro": _bairroController.text.trim(),
        "cep": _cepController.text.trim(),
        "complemento": _complementoController.text.trim(),
      },
      "itens": [
        {
          "id_produto": idProduto,
          "quantidade": quantidade,
          "preco_unitario": _precoProdutoSelecionado,
          "valor_item": subtotal,
        }
      ]
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(dadosPedido),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        _notificar('🥚 Pedido enviado com sucesso!', sucesso: true);
        _limparFormulario();
      } else {
        Map<String, dynamic> erroResposta = {};
        try {
          erroResposta = jsonDecode(response.body);
        } catch (_) {}
        _notificar(erroResposta["mensagem"] ?? 'Erro ao salvar o pedido no banco (Status: ${response.statusCode}).');
      }
    } catch (e) {
      print("❌ Erro no envio HTTP: $e");
      _notificar('Falha na comunicação com o servidor.');
    } finally {
      setState(() => _carregandoEnvio = false);
    }
  }

  void _avancar() {
    if (_validarEtapaAtual()) {
      if (_etapaAtual < 2) {
        setState(() => _etapaAtual++);
      } else {
        _finalizarESalvarPedido();
      }
    }
  }

  void _voltar() => setState(() => {if (_etapaAtual > 0) _etapaAtual--});

  void _notificar(String mensagem, {bool sucesso = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: sucesso ? _corVerdePrincipal : const Color(0xFFD32F2F),
        content: Text(mensagem, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _limparFormulario() {
    setState(() {
      _etapaAtual = 0;
      _nomeController.clear();
      _telefoneController.clear();
      _quantidadeController.text = "1";
      _ruaController.clear();
      _numeroController.clear();
      _bairroController.clear();
      _cepController.clear();
      _complementoController.clear();
      _dataEntregaSelecionada = null;
      _metodoPagamento = "Dinheiro";
      _produtoSelecionadoObj = null;
    });
    _buscarProdutosDoBanco();
  }

  Widget _buildField(String label, IconData icone, TextEditingController controller, {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _corVerdePrincipal.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600),
          prefixIcon: Icon(icone, color: _corVerdePrincipal, size: 20),
          filled: true,
          fillColor: _corCardLimpo,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _corBordaSutil)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _corVerdePrincipal, width: 1.5)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool exibirCarregando = _carregandoEnvio || (_carregandoProdutos && _erroConexao == null);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFDFE7DF),
        elevation: 0,
        title: Text(
          'Nova Venda',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: _corVerdePrincipal,
            letterSpacing: -0.5,
          ),
        ),
        iconTheme: IconThemeData(color: _corVerdePrincipal),
      ),
      body: SafeArea(
        child: exibirCarregando
            ? Center(child: CircularProgressIndicator(color: _corVerdePrincipal))
            : Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStepIndicator(0, "Cliente", Icons.person_outline_rounded),
                  Icon(Icons.chevron_right_rounded, size: 16, color: _corVerdePrincipal.withOpacity(0.2)),
                  _buildStepIndicator(1, "Pedido", Icons.shopping_basket_outlined),
                  Icon(Icons.chevron_right_rounded, size: 16, color: _corVerdePrincipal.withOpacity(0.2)),
                  _buildStepIndicator(2, "Entrega", Icons.local_shipping_outlined),
                ],
              ),
            ),

            Expanded(
              child: _erroConexao != null
                  ? _buildTelaErroConexao()
                  : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildConteudoDaEtapaAtual(),
              ),
            ),

            if (_erroConexao == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 24.0),
                child: Row(
                  children: [
                    if (_etapaAtual > 0)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _voltar,
                          icon: const Icon(Icons.west_rounded, size: 18),
                          label: const Text("Voltar", style: TextStyle(fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _corVerdePrincipal,
                            side: BorderSide(color: _corVerdePrincipal.withOpacity(0.3)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    if (_etapaAtual > 0) const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _avancar,
                        icon: Icon(
                          _etapaAtual == 2
                              ? Icons.check_circle_outline_rounded
                              : Icons.east_rounded,
                          size: 18,
                        ),
                        label: Text(
                            _etapaAtual == 2 ? "Confirmar" : "Avançar",
                            style: const TextStyle(fontWeight: FontWeight.bold)
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _corVerdePrincipal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String label, IconData icone) {
    bool ativo = _etapaAtual == stepIndex;
    bool concluido = _etapaAtual > stepIndex;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ativo ? _corVerdePrincipal : concluido ? _corTerracotaDestaque.withOpacity(0.2) : _corBordaSutil.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(icone, size: 18, color: ativo ? Colors.white : concluido ? _corTerracotaDestaque : _corVerdePrincipal.withOpacity(0.4)),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: ativo ? FontWeight.w900 : FontWeight.w600, color: ativo ? _corVerdePrincipal : _corVerdePrincipal.withOpacity(0.5))),
      ],
    );
  }

  Widget _buildTelaErroConexao() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 60, color: Color(0xFFD32F2F)),
            const SizedBox(height: 16),
            Text("Falha de Sincronização", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _corVerdePrincipal)),
            const SizedBox(height: 10),
            Text(_erroConexao!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _buscarProdutosDoBanco,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text("Tentar Novamente"),
              style: ElevatedButton.styleFrom(backgroundColor: _corVerdePrincipal, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConteudoDaEtapaAtual() {
    switch (_etapaAtual) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Informações do Cliente", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _corVerdePrincipal)),
            const SizedBox(height: 12),
            _buildField("Nome Completo", Icons.person_outline_rounded, _nomeController),
            _buildField("WhatsApp", Icons.phone_iphone_rounded, _telefoneController, type: TextInputType.phone),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Informações do Pedido", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _corVerdePrincipal)),
            const SizedBox(height: 12),
            _produtosDoBanco.isEmpty
                ? const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Sincronizando produtos ativos com a base local...", style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
            )
                : DropdownButtonFormField<dynamic>(
              value: _produtoSelecionadoObj,
              decoration: InputDecoration(
                labelText: "Tabela Dinâmica de Produtos",
                filled: true,
                fillColor: _corCardLimpo,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _corBordaSutil)),
              ),
              items: _produtosDoBanco.map<DropdownMenuItem<dynamic>>((prod) {
                final double preco = double.tryParse(prod["preco"].toString()) ?? 0.0;
                final String nome = prod["nome"] ?? 'Sem Nome';
                final bool possuiId = prod["id"] != null;
                final String labelExibicao = possuiId ? "$nome - R\$ ${preco.toStringAsFixed(2)}" : "⚠️ $nome (Sem ID na API) - R\$ ${preco.toStringAsFixed(2)}";

                return DropdownMenuItem<dynamic>(
                  value: prod,
                  child: Text(labelExibicao, style: TextStyle(color: possuiId ? Colors.black87 : Colors.orange.shade900)),
                );
              }).toList(),
              onChanged: (valor) {
                setState(() {
                  _produtoSelecionadoObj = valor;
                  _precoProdutoSelecionado = double.tryParse(valor["preco"].toString()) ?? 0.0;
                });
              },
            ),
            const SizedBox(height: 10),
            _buildField("Quantidade de caixas/dúzias", Icons.tag_rounded, _quantidadeController, type: TextInputType.number),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _metodoPagamento,
              decoration: InputDecoration(
                labelText: "Forma de Pagamento",
                filled: true,
                fillColor: _corCardLimpo,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _corBordaSutil)),
              ),
              items: _formasPagamento.map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              onChanged: (valor) => setState(() => _metodoPagamento = valor ?? "Dinheiro"),
            )
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Informações da entrega", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _corVerdePrincipal)),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _selecionarData(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: _corCardLimpo,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _dataEntregaSelecionada != null ? _corVerdePrincipal : _corBordaSutil, width: _dataEntregaSelecionada != null ? 1.5 : 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, color: _corVerdePrincipal),
                    const SizedBox(width: 12),
                    Text(
                      _dataEntregaSelecionada == null
                          ? "Escolha a Data de Entrega"
                          : "Entrega Agendada: ${_dataEntregaSelecionada!.day.toString().padLeft(2, '0')}/${_dataEntregaSelecionada!.month.toString().padLeft(2, '0')}/${_dataEntregaSelecionada!.year}",
                      style: TextStyle(color: _dataEntregaSelecionada == null ? _corVerdePrincipal.withOpacity(0.7) : _corVerdePrincipal, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildField("Rua / Avenida", Icons.map_outlined, _ruaController),
            Row(
              children: [
                Expanded(child: _buildField("Número", Icons.numbers_rounded, _numeroController)),
                const SizedBox(width: 10),
                Expanded(child: _buildField("Bairro", Icons.location_city_rounded, _bairroController)),
              ],
            ),
            _buildField("CEP", Icons.pin_drop_outlined, _cepController, type: TextInputType.number),
            _buildField("Complemento / Ponto de Referência", Icons.info_outline_rounded, _complementoController),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}