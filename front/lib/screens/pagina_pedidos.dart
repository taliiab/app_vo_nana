import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';
import '../widgets/card_pedido.dart';
import '../widgets/modal_filtros.dart';

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

  void _abrirDetalhesPedido(BuildContext context, Map<String, dynamic> pedido) {
    const Color corVerdePrincipal = Color(0xFF27422C);
    const Color corTerracota = Color(0xFFBC6C45);
    const Color corFundoMentaSuave = Color(0xFFF1F4F1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final String statusEntrega = pedido['status_entrega'] ?? 'Pendente';
        final String statusPagamento = pedido['status_pagamento'] ?? 'Pendente';

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                decoration: const BoxDecoration(
                  color: corFundoMentaSuave,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shopping_basket_rounded, color: corTerracota, size: 16),
                            const SizedBox(width: 6),
                            const Text(
                              "Detalhes do Pedido",
                              style: TextStyle(
                                fontSize: 12,
                                color: corTerracota,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "📦 #${pedido['id']} 📦",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: corVerdePrincipal,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(backgroundColor: Colors.white),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildCategoria("Informações do Cliente", Icons.person_rounded, [
                      _buildTextDetalhe("Cliente", pedido['nome'] ?? "N/A"),
                      _buildTextDetalhe("WhatsApp", pedido['id_cliente'] ?? "N/A"),
                      _buildTextDetalhe("Endereço", "${pedido['rua'] ?? ''}, ${pedido['numero'] ?? ''}"),
                      _buildTextDetalhe("Bairro", pedido['bairro'] ?? "N/A"),
                    ]),
                    _buildCategoria("Status", Icons.track_changes_rounded, [
                      _buildTextDetalhe("Entrega", statusEntrega, isStatus: true),
                      _buildTextDetalhe("Pagamento", statusPagamento, isStatus: true),
                    ]),
                    _buildCategoria("Resumo Financeiro", Icons.payments_rounded, [
                      _buildTextDetalhe("Produto", pedido['nome_produto'] ?? "Padrão"),
                      _buildTextDetalhe("Quantidade", "${pedido['quantidade'] ?? '0'} dúzias/caixas"),
                      const Divider(height: 20),
                      _buildTextDetalhe("Método de Pagamento", pedido['metodo_pagamento'] ?? "Não informado"),
                      _buildTextDetalhe("Subtotal", "R\$ ${pedido['subtotal']}"),
                      _buildTextDetalhe("Frete", "R\$ ${pedido['custo_frete']}"),
                      _buildTextDetalhe("Total Geral", "R\$ ${pedido['total']}", isBold: true),
                    ]),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]
                ),
                child: Row(
                  children: [
                    if (statusEntrega != 'Cancelado') ...[

                      if (statusEntrega == 'Pendente')
                        _buildBotaoAcao("Cancelar", Icons.close_rounded, Colors.red[50]!, Colors.red[800]!,
                                () => _atualizarStatusUnico(pedido['id'].toString(), '/pedidos/cancelar', "Pedido Cancelado!")),

                      if (statusPagamento != 'Aprovado') ...[
                        const SizedBox(width: 8),
                        _buildBotaoAcao("Marcar como pago", Icons.payments_rounded, Colors.blue[50]!, Colors.blue[800]!,
                                () => _atualizarStatusUnico(pedido['id'].toString(), '/pedidos/confirmar-pagamento', "Pagamento Confirmado!"))
                      ],

                      if (statusEntrega != 'Entregue') ...[
                        const SizedBox(width: 8),
                        _buildBotaoAcao("Marcar como entregue", Icons.local_shipping_rounded, Colors.green[50]!, Colors.green[800]!,
                                () => _atualizarStatusUnico(pedido['id'].toString(), '/pedidos/confirmar-entrega', "Entrega Confirmada! 🎉"))
                      ],
                    ] else ...[
                      const Expanded(
                        child: Text(
                          "Este pedido foi cancelado.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }


  Widget _buildCategoria(String titulo, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E5E5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(children: [
            Icon(icon, size: 20, color: const Color(0xFFBC6C45)),
            const SizedBox(width: 8),
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF27422C))),
          ]),
          const Divider(height: 30, color: Color(0xFFF1F4F1), thickness: 2),
          ...children,
        ],
      ),
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

  Widget _buildBotaoAcao(String label, IconData icon, Color bg, Color text, VoidCallback onTap) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: text,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _atualizarStatusUnico(String idPedido, String endpoint, String mensagemSucesso) async {
    try {
      final response = await _dio.post(endpoint, queryParameters: {'id': idPedido});
      if (response.statusCode == 200 && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagemSucesso), backgroundColor: Colors.green));
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
      }
    }
  }

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
      debugPrint("Erro ao buscar pedidos no back: $e");
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
          'http://200.18.74.27:8082/pedidos/atualizar-status-entrega',
          data: idsParaAtualizar,
          options: Options(
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        );

        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Pedidos updated para 'Em Processo de Entrega'! 🐔"),
                backgroundColor: Colors.green,
              ),
            );
            setState(() {});
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("PDF gerado! Nenhum pedido pendente para atualizar.")),
          );
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao gerar PDF ou atualizar status: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color corVerdePrincipal = Color(0xFF27422C);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 16, bottom: 8, left: 16, right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: corVerdePrincipal.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.inventory_2_rounded, color: corVerdePrincipal, size: 20),
              const SizedBox(width: 10),
              const Text(
                "Logística",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: corVerdePrincipal,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  _buildActionChip(Icons.map_rounded, "Rotas", () async {
                    final p = await _buscarPedidosDoBanco();
                    if (p.isNotEmpty) _exportarParaCircuit(p);
                    else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nenhum pedido para exportar! 🥚")));
                  }),
                  const SizedBox(width: 8),
                  _buildActionChip(Icons.picture_as_pdf_rounded, "PDF", () async {
                    final p = await _buscarPedidosDoBanco();
                    if (p.isNotEmpty) _gerarRelatorioPdf(p);
                    else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nenhum pedido para imprimir! 🥚")));
                  }),
                  Container(width: 1, height: 20, color: corVerdePrincipal.withOpacity(0.2), margin: const EdgeInsets.symmetric(horizontal: 6)),
                  InkWell(
                    onTap: () => _abrirFiltros(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: corVerdePrincipal.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.tune_rounded, size: 16, color: corVerdePrincipal),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            color: corVerdePrincipal,
            onRefresh: () async => setState(() {}),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _buscarPedidosDoBanco(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: corVerdePrincipal));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("Nenhum pedido encontrado. 🥚", style: TextStyle(color: corVerdePrincipal.withOpacity(0.5))));
                }

                final pedidos = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: pedidos.length,
                  itemBuilder: (context, index) {
                    final p = pedidos[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CardPedido(
                        idCliente: p['id']?.toString() ?? "Sem ID",
                        status: p['status_entrega']?.toString() ?? "Pendente",
                        duzias: p['quantidade']?.toString() ?? "0",
                        forma: p['metodo_pagamento']?.toString() ?? "Pix",
                        valor: p['subtotal']?.toString() ?? "0,00",
                        entrega: p['custo_frete']?.toString() ?? "0,00",
                        total: p['total']?.toString() ?? "0,00",
                        onTap: () => _abrirDetalhesPedido(context, p),
                        tipoProduto: p['nome_produto']?.toString() ?? "Padrão",
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

  Widget _buildActionChip(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF27422C).withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF27422C)),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF27422C))),
          ],
        ),
      ),
    );
  }
}