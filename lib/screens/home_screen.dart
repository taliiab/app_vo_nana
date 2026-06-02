import 'package:flutter/material.dart';
import 'package:app_admin/database_helper.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';

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
      ),
      body: _paginas[_indiceAtual],
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

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _indiceAtual == index;
    return GestureDetector(
      onTap: () => setState(() => _indiceAtual = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 35, color: Colors.black),
          Text(
            label,
            style: TextStyle(
              color: Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              decoration: isSelected ? TextDecoration.underline : TextDecoration.none,
              decorationThickness: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class PaginaPedidos extends StatefulWidget {
  const PaginaPedidos({super.key});

  @override
  State<PaginaPedidos> createState() => _PaginaPedidosState();
}

class _PaginaPedidosState extends State<PaginaPedidos> {
  final DatabaseHelper _db = DatabaseHelper();

  DateTime _dataDe = DateTime.now();
  DateTime _dataAte = DateTime.now();
  Map<String, bool> _statusPedidos = {"Pendente": true, "Entregue": false, "Cancelado": false};
  Map<String, bool> _statusPagamento = {"Aprovado": true, "Pendente": true};

  Future<void> _abrirFiltros(BuildContext context) async {
    final resultado = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalFiltros(
        dataDeInicial: _dataDe,
        dataAteInicial: _dataAte,
        statusPedidosIniciais: _statusPedidos,
        statusPagamentoIniciais: _statusPagamento,
      ),
    );

    if (resultado != null) {
      setState(() {
        _dataDe = resultado['dataDe'];
        _dataAte = resultado['dataAte'];
        _statusPedidos = resultado['statusPedidos'];
        _statusPagamento = resultado['statusPagamento'];
      });
    }
  }

  Future<List<Map<String, dynamic>>> _buscarPedidosDoBanco() async {
    final conn = await _db.abrirConexao();
    try {
      List<String> statusFiltro = [];
      _statusPedidos.forEach((key, value) { if (value) statusFiltro.add("'$key'"); });

      List<String> pagFiltro = [];
      _statusPagamento.forEach((key, value) { if (value) pagFiltro.add("'$key'"); });

      if (statusFiltro.isEmpty) statusFiltro.add("'VAZIO'");
      if (pagFiltro.isEmpty) pagFiltro.add("'VAZIO'");

      String dataDeFormatada = "${_dataDe.year}-${_dataDe.month.toString().padLeft(2,'0')}-${_dataDe.day.toString().padLeft(2,'0')} 00:00:00";
      String dataAteFormatada = "${_dataAte.year}-${_dataAte.month.toString().padLeft(2,'0')}-${_dataAte.day.toString().padLeft(2,'0')} 23:59:59";

      final results = await conn.execute(
          '''
        SELECT 
          p.id, 
          p.id_cliente, 
          p.status_entrega, 
          ip.quantidade, 
          pa.metodo_pagamento, 
          pa.status_pagamento, -- ADICIONADO AQUI PARA O PDF FUNCIONAR
          p.subtotal,
          p.custo_frete,
          p.total,
          c.nome,
          e.rua,
          e.numero,
          e.bairro,
          e.complemento,
          e.cep
        FROM pedidos p
        LEFT JOIN itens_pedido ip ON p.id = ip.id_pedido
        LEFT JOIN pagamentos pa ON p.id = pa.id_pedido
        LEFT JOIN clientes c ON p.id_cliente = c.id_whatsapp    
        LEFT JOIN endereco_entrega e ON p.id = e.id_pedido
        WHERE p.data_entrega BETWEEN '$dataDeFormatada' AND '$dataAteFormatada'
          AND p.status_entrega IN (${statusFiltro.join(',')})
          AND pa.status_pagamento IN (${pagFiltro.join(',')})
        ORDER BY p.data_entrega ASC
        '''
      );

      return results.map((row) => row.toColumnMap()).toList();
    } finally {
      await conn.close();
    }
  }

  Future<void> _gerarRelatorioPdf(List<Map<String, dynamic>> pedidos) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          pw.Header(
              level: 0,
              child: pw.Text("Logística de Entregas - Vó Naná",
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))
          ),
          pw.SizedBox(height: 10),

          ...pedidos.map((p) {
            final bool estaPago = p['status_pagamento'] == 'Aprovado';

            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("PEDIDO: #${p['id']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text("TOTAL: R\$ ${p['total']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.SizedBox(height: 4),

                  pw.Text("CLIENTE: ${p['nome'] ?? 'N/A'}"),
                  pw.Text(
                    "ENDEREÇO: ${p['rua']}, ${p['numero']}${p['complemento'] != null && p['complemento'].toString().trim().isNotEmpty ? ' (${p['complemento']})' : ''}",
                  ),
                  pw.Text("BAIRRO: ${p['bairro']}"),

                  pw.SizedBox(height: 4),

                  pw.Row(
                    children: [
                      pw.Text("PAGAMENTO: ", style: pw.TextStyle(fontSize: 10)),
                      pw.Text(
                        estaPago ? "APROVADO" : "PENDENTE",
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: estaPago ? PdfColors.green : PdfColors.red,
                        ),
                      ),
                      pw.Text("  |  MÉTODO: ${p['metodo_pagamento'] ?? 'N/A'}", style: pw.TextStyle(fontSize: 10)),
                    ],
                  ),

                  pw.SizedBox(height: 10),
                  pw.Divider(thickness: 1, color: PdfColors.grey300),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<void> _exportarParaCircuit(List<Map<String, dynamic>> pedidos) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              context: context,
              data: <List<String>>[
                ['Nome', 'Endereco', 'Bairro'],
                ...pedidos.map((p) => [
                  p['nome']?.toString() ?? '',
                  "${p['rua']}, ${p['numero']}",
                  p['bairro']?.toString() ?? ''
                ]),
              ],
            );
          },
        ),
      );

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/rota_circuito_vo_nana.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        text: 'Lista de Entregas - Vó Naná',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao gerar PDF: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF75A97D),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "Logística",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.local_shipping, color: Colors.black),
                    tooltip: "Exportar Rotas",
                    onPressed: () async {
                      final pedidosFiltrados = await _buscarPedidosDoBanco();
                      if (pedidosFiltrados.isNotEmpty) {
                        _exportarParaCircuit(pedidosFiltrados);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Nenhum pedido para exportar! 🥚")),
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.print, color: Colors.black),
                    tooltip: "Imprimir PDF",
                    onPressed: () async {
                      final pedidosFiltrados = await _buscarPedidosDoBanco();
                      if (pedidosFiltrados.isNotEmpty) {
                        _gerarRelatorioPdf(pedidosFiltrados);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Nenhum pedido para imprimir! 🥚")),
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.black),
                    tooltip: "Filtros",
                    onPressed: () => _abrirFiltros(context),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFF75A97D),
            onRefresh: () async {
              setState(() {});
            },
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _buscarPedidosDoBanco(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF75A97D)));
                }
                if (snapshot.hasError) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [Center(child: Text("Erro ao carregar banco: ${snapshot.error}"))],
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [Center(child: Text("Nenhum pedido para as datas selecionadas. 🥚"))],
                  );
                }

                final pedidos = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: pedidos.length,
                  itemBuilder: (context, index) {
                    final p = pedidos[index];
                    return _buildCardPedido(
                        p['id_cliente']?.toString() ?? "Sem número",
                        p['status_entrega']?.toString() ?? "Pendente",
                        p['quantidade']?.toString() ?? "0",
                        p['metodo_pagamento']?.toString() ?? "Pix",
                        p['subtotal']?.toString() ?? "0,00",
                        p['custo_frete']?.toString() ?? "0,00",
                        p['total']?.toString() ?? "0,00"
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardPedido(String idCliente, String status, String duzias, String forma, String valor, String entrega, String total) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF9ABF9E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Número: $idCliente", style: const TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == "Entregue" ? Colors.green[800] : Colors.orange[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(color: Colors.white38),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Dúzias: $duzias"),
              Text("Forma: $forma"),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Valor: R\$ $valor"),
              Text("Entrega: R\$ $entrega"),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total: R\$ $total", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
}

class ModalFiltros extends StatefulWidget {
  final DateTime dataDeInicial;
  final DateTime dataAteInicial;
  final Map<String, bool> statusPedidosIniciais;
  final Map<String, bool> statusPagamentoIniciais;

  const ModalFiltros({
    super.key,
    required this.dataDeInicial,
    required this.dataAteInicial,
    required this.statusPedidosIniciais,
    required this.statusPagamentoIniciais,
  });

  @override
  State<ModalFiltros> createState() => _ModalFiltrosState();
}

class _ModalFiltrosState extends State<ModalFiltros> {
  late DateTime dataDe;
  late DateTime dataAte;
  late bool pendente;
  late bool entregue;
  late bool cancelado;
  late bool aprovado;
  late bool pagPendente;

  @override
  void initState() {
    super.initState();
    dataDe = widget.dataDeInicial;
    dataAte = widget.dataAteInicial;
    pendente = widget.statusPedidosIniciais['Pendente'] ?? true;
    entregue = widget.statusPedidosIniciais['Entregue'] ?? false;
    cancelado = widget.statusPedidosIniciais['Cancelado'] ?? false;
    aprovado = widget.statusPagamentoIniciais['Aprovado'] ?? true;
    pagPendente = widget.statusPagamentoIniciais['Pendente'] ?? true;
  }

  String _formatDate(DateTime date) =>
      "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";

  Future<void> _pickDate(BuildContext context, bool isDe) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDe ? dataDe : dataAte,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF75A97D))),
        child: child!,
      ),
    );
    if (picked != null) setState(() => isDe ? dataDe = picked : dataAte = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF75A97D), borderRadius: BorderRadius.circular(8)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text("Filtros", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Icon(Icons.menu)],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSecao("Data de Entrega:", [
                  _buildDataRow("De:", dataDe, true),
                  _buildDataRow("Até:", dataAte, false),
                ]),
                const SizedBox(height: 16),
                _buildSecao("Pedidos:", [
                  _buildCheck("Pendente", pendente, (v) => setState(() => pendente = v!)),
                  _buildCheck("Entregue", entregue, (v) => setState(() => entregue = v!)),
                  _buildCheck("Cancelado", cancelado, (v) => setState(() => cancelado = v!)),
                ]),
                const SizedBox(height: 16),
                _buildSecao("Pagamento:", [
                  _buildCheck("Aprovado", aprovado, (v) => setState(() => aprovado = v!)),
                  _buildCheck("Pendente", pagPendente, (v) => setState(() => pagPendente = v!)),
                ]),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'dataDe': dataDe,
                      'dataAte': dataAte,
                      'statusPedidos': {"Pendente": pendente, "Entregue": entregue, "Cancelado": cancelado},
                      'statusPagamento': {"Aprovado": aprovado, "Pendente": pagPendente}
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF75A97D),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.all(15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text("Aplicar Filtros", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecao(String title, List<Widget> items) => Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(color: const Color(0xFF9ABF9E).withOpacity(0.4), borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), ...items]),
  );

  Widget _buildDataRow(String label, DateTime date, bool isDe) => Row(
    children: [
      SizedBox(width: 40, child: Text(label)),
      InkWell(
        onTap: () => _pickDate(context, isDe),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFF75A97D).withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
          child: Row(children: [Text(_formatDate(date)), const SizedBox(width: 8), const Icon(Icons.calendar_month, size: 18)]),
        ),
      ),
    ],
  );

  Widget _buildCheck(String t, bool v, Function(bool?) onC) => Row(children: [Checkbox(value: v, onChanged: onC, activeColor: Colors.black), Text(t)]);
}

class PaginaConfiguracoes extends StatefulWidget {
  const PaginaConfiguracoes({super.key});
  @override
  State<PaginaConfiguracoes> createState() => _PaginaConfiguracoesState();
}

class _PaginaConfiguracoesState extends State<PaginaConfiguracoes> {
  final DatabaseHelper _db = DatabaseHelper();
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
    final conn = await _db.abrirConexao();
    try {
      _controllerExtra.text = "0,00";
      _controllerJumbo.text = "0,00";
      _controllerFrete.text = "10,00";

      final prodResults = await conn.execute("SELECT nome, preco FROM produtos");
      for (var row in prodResults) {
        String nome = row[0].toString();
        String preco = row[1].toString().replaceAll('.', ',');
        if (nome == 'Extra' || nome == 'Dúzia') _controllerExtra.text = preco;
        else if (nome == 'Jumbo') _controllerJumbo.text = preco;
      }

      final confResults = await conn.execute("SELECT chave, valor FROM configuracoes");
      for (var row in confResults) {
        String chave = row[0].toString();
        String valor = row[1].toString();
        if (chave == 'qtd_frete_gratis' && valor.isNotEmpty) {
          setState(() => qtdEntregaGratis = valor.padLeft(2, '0'));
        } else if (chave == 'valor_frete_padrao' && valor.isNotEmpty) {
          _controllerFrete.text = valor.replaceAll('.', ',');
        }
      }
    } catch (e) {
    } finally {
      setState(() => _carregando = false);
      await conn.close();
    }
  }

  Future<void> _salvarDadosNoBanco() async {
    String precoExtraDb = _controllerExtra.text.replaceAll(',', '.');
    String precoJumboDb = _controllerJumbo.text.replaceAll(',', '.');
    String valorFreteDb = _controllerFrete.text.replaceAll(',', '.');

    final conn = await _db.abrirConexao();
    try {
      await conn.execute("UPDATE produtos SET preco = $precoExtraDb WHERE nome IN ('Extra', 'Dúzia')");
      await conn.execute("UPDATE produtos SET preco = $precoJumboDb WHERE nome = 'Jumbo'");

      await conn.execute('''
        INSERT INTO configuracoes (chave, valor) VALUES ('qtd_frete_gratis', '$qtdEntregaGratis')
        ON CONFLICT (chave) DO UPDATE SET valor = EXCLUDED.valor
      ''');
      await conn.execute('''
        INSERT INTO configuracoes (chave, valor) VALUES ('valor_frete_padrao', '$valorFreteDb')
        ON CONFLICT (chave) DO UPDATE SET valor = EXCLUDED.valor
      ''');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Configurações salvas e sincronizadas! 🐔"), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao salvar: $e"), backgroundColor: Colors.red),
      );
    } finally {
      await conn.close();
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
                _buildConfigItem(
                  label: "Valor da Dúzia/Extra (R\$):",
                  trailing: _buildInputBox(_controllerExtra),
                ),
                _buildConfigItem(
                  label: "Valor do Jumbo (R\$):",
                  trailing: _buildInputBox(_controllerJumbo),
                ),
                const Divider(color: Colors.white, height: 30),
                _buildConfigItem(
                  label: "Valor do Frete Padrão:",
                  trailing: _buildInputBox(_controllerFrete),
                ),
                _buildConfigItem(
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

  Widget _buildInputBox(TextEditingController controller) {
    return Container(
      width: 110,
      decoration: BoxDecoration(
        color: const Color(0xFF75A97D).withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.end,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        onChanged: (value) => _formatarMoeda(value, controller),
        decoration: const InputDecoration(
          prefixText: "R\$ ",
          prefixStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        ),
      ),
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

  Widget _buildConfigItem({required String label, required Widget trailing}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF9ABF9E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}