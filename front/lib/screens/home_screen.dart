import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';

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
  final Dio _dio = ApiService().dio;

  DateTime _dataDe = DateTime.now();
  DateTime _dataAte = DateTime.now();
  Map<String, bool> _statusPedidos = {"Pendente": true, "Em Processo de Entrega": true, "Entregue": false, "Cancelado": false};
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
    try {
      List<String> statusFiltro = [];
      _statusPedidos.forEach((key, value) { if (value) statusFiltro.add(key); });

      List<String> pagFiltro = [];
      _statusPagamento.forEach((key, value) { if (value) pagFiltro.add(key); });

      String dataDeFormatada = "${_dataDe.year}-${_dataDe.month.toString().padLeft(2,'0')}-${_dataDe.day.toString().padLeft(2,'0')}";
      String dataAteFormatada = "${_dataAte.year}-${_dataAte.month.toString().padLeft(2,'0')}-${_dataAte.day.toString().padLeft(2,'0')}";

      final response = await _dio.get('/pedidos', queryParameters: {
        'dataDe': dataDeFormatada,
        'dataAte': dataAteFormatada,
        'status': statusFiltro.join(','),
        'pagamento': pagFiltro.join(','),
      });

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      print("Erro ao buscar pedidos no back: $e");
      throw Exception("Não foi possível carregar os pedidos.");
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
                ...pedidos.map((p) {
                  final comp = p['complemento']?.toString().trim() ?? '';
                  final temComplemento = comp.isNotEmpty;

                  return [
                    p['nome']?.toString() ?? '',
                    "${p['rua'] ?? ''}, ${p['numero'] ?? ''}${temComplemento ? ' ($comp)' : ''}",
                    p['bairro']?.toString() ?? ''
                  ];
                }),
              ],
            );
          },
        ),
      );

      if (kIsWeb) {
        await Printing.sharePdf(
          bytes: await pdf.save(),
          filename: 'rota_circuito_vo_nana.pdf',
        );
      } else {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/rota_circuito_vo_nana.pdf');
        await file.writeAsBytes(await pdf.save());

        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/pdf')],
          text: 'Lista de Entregas - Vó Naná',
        );
      }

      final List<String> idsParaAtualizar = pedidos
          .where((p) => p['status_entrega'] == 'Pendente')
          .map((p) => p['id'].toString())
          .toList();

      if (idsParaAtualizar.isNotEmpty) {
        final response = await _dio.post(
          'http://localhost:8081/pedidos/atualizar-status-entrega',
          data: idsParaAtualizar,
          options: Options(
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Pedidos atualizados para 'Em Processo de Entrega'! 🐔"),
              backgroundColor: Colors.green,
            ),
          );

          if (mounted) {
            setState(() {});
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("PDF gerado! Nenhum pedido pendente para atualizar.")),
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao gerar PDF ou atualizar status: $e"),
          backgroundColor: Colors.red,
        ),
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
                    children: [Center(child: Text("Erro ao carregar do servidor: ${snapshot.error}"))],
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
                    return InkWell(
                      onTap: () => _abrirDetalhesPedido(context, p),
                      borderRadius: BorderRadius.circular(12),
                      child: _buildCardPedido(
                          p['id']?.toString() ?? "Sem ID",
                          p['status_entrega']?.toString() ?? "Pendente",
                          p['quantidade']?.toString() ?? "0",
                          p['metodo_pagamento']?.toString() ?? "Pix",
                          p['subtotal']?.toString() ?? "0,00",
                          p['custo_frete']?.toString() ?? "0,00",
                          p['total']?.toString() ?? "0,00"
                      ),
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

  void _abrirDetalhesPedido(BuildContext context, Map<String, dynamic> pedido) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final String statusEntrega = pedido['status_entrega'] ?? 'Pendente';
        final String statusPagamento = pedido['status_pagamento'] ?? 'Pendente';

        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Pedido #${pedido['id']}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  children: [
                    _buildTextDetalhe("Cliente", pedido['nome'] ?? "N/A"),
                    _buildTextDetalhe("Telefone/WhatsApp", pedido['id_cliente'] ?? "N/A"),
                    _buildTextDetalhe("Endereço", "${pedido['rua'] ?? ''}, ${pedido['numero'] ?? ''} ${pedido['complemento'] != null && pedido['complemento'].toString().trim().isNotEmpty ? '(${pedido['complemento']})' : ''}"),
                    _buildTextDetalhe("Bairro", pedido['bairro'] ?? "N/A"),
                    _buildTextDetalhe("Quantidade (Dúzias)", pedido['quantidade']?.toString() ?? "0"),
                    _buildTextDetalhe("Método de Pagamento", pedido['metodo_pagamento'] ?? "N/A"),
                    _buildTextDetalhe("Status da Entrega", statusEntrega, isStatus: true),
                    _buildTextDetalhe("Status do Pagamento", statusPagamento, isStatus: true),
                    const Divider(),
                    _buildTextDetalhe("Subtotal", "R\$ ${pedido['subtotal']}"),
                    _buildTextDetalhe("Frete", "R\$ ${pedido['custo_frete']}"),
                    _buildTextDetalhe("Total Geral", "R\$ ${pedido['total']}", isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  if (statusEntrega == 'Pendente')
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _atualizarStatusUnico(pedido['id'].toString(), '/pedidos/cancelar', "Pedido Cancelado!"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white),
                        child: const Text("Cancelar pedido", style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  if (statusEntrega == 'Pendente' && statusEntrega != 'Cancelado' && statusPagamento != 'Aprovado') const SizedBox(width: 8),

                  if (statusEntrega != 'Cancelado' && statusPagamento != 'Aprovado')
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _atualizarStatusUnico(pedido['id'].toString(), '/pedidos/confirmar-pagamento', "Pagamento Confirmado!"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], foregroundColor: Colors.white),
                        child: const Text("Marcar como pago", style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  if (statusEntrega != 'Cancelado' && statusEntrega != 'Entregue' && (statusEntrega != 'Cancelado' && statusPagamento != 'Aprovado')) const SizedBox(width: 8),

                  if (statusEntrega != 'Cancelado' && statusEntrega != 'Entregue')
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _atualizarStatusUnico(pedido['id'].toString(), '/pedidos/confirmar-entrega', "Entrega Confirmada! 🎉"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
                        child: const Text("Marcar como entregue", style: TextStyle(fontSize: 12)),
                      ),
                    ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextDetalhe(String label, String valor, {bool isBold = false, bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$label:", style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
          Text(valor, style: TextStyle(
              fontWeight: (isBold || isStatus) ? FontWeight.bold : FontWeight.normal,
              color: isStatus ? (valor == "Entregue" || valor == "Aprovado" ? Colors.green[800] : Colors.orange[900]) : Colors.black
          )),
        ],
      ),
    );
  }

  Future<void> _atualizarStatusUnico(String idPedido, String endpoint, String mensagemSucesso) async {
    try {
      final response = await _dio.post(endpoint, queryParameters: {'id': idPedido});

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(mensagemSucesso), backgroundColor: Colors.green),
          );
          setState(() {});
        }
      }
    } on DioException catch (e) {
      String mensagemErro = "Erro ao executar ação.";

      if (e.response != null && e.response?.data != null) {
        if (e.response?.data is Map && e.response?.data['mensagem'] != null) {
          mensagemErro = e.response?.data['mensagem'];
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Aviso: $mensagemErro"),
            backgroundColor: Colors.orange[800],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro inesperado: $e"), backgroundColor: Colors.red),
        );
      }
    }
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
  late bool emProcesso;
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
    emProcesso = widget.statusPedidosIniciais['Em Processo de Entrega'] ?? true;
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
                  _buildCheck("Em Processo de Entrega", emProcesso, (v) => setState(() => emProcesso = v!)),
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
                      'statusPedidos': {"Pendente": pendente, "Em Processo de Entrega": emProcesso, "Entregue": entregue, "Cancelado": cancelado},
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
      print("Erro ao carregar configurações do back: $e");
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Configurações salvas e sincronizadas na API! 🐔"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao salvar no servidor: $e"), backgroundColor: Colors.red),
      );
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