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
import '../widgets/card_pedido.dart';   // <--- Certifique-se de que este import existe
import '../widgets/modal_filtros.dart'; // <--- Certifique-se de que este import existe

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

  // 1ª ALTERAÇÃO: O método _abrirDetalhesPedido real com bottom sheet e botões de ação
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

  // Método auxiliar para estilizar as linhas do modal de detalhes
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

  // Método para disparar as atualizações individuais de status das requisições do modal
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
          SnackBar(content: Text("Aviso: $mensagemErro"), backgroundColor: Colors.orange[800]),
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

  // 2ª ALTERAÇÃO: Vinculando o ModalFiltros importado no showModalBottomSheet
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
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Nenhum pedido para exportar! 🥚")),
                          );
                        }
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
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Nenhum pedido para imprimir! 🥚")),
                          );
                        }
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

                    // 3ª ALTERAÇÃO: Chamando o widget CardPedido customizado com seus parâmetros estilizados
                    return CardPedido(
                      idCliente: p['id']?.toString() ?? "Sem ID",
                      status: p['status_entrega']?.toString() ?? "Pendente",
                      duzias: p['quantidade']?.toString() ?? "0",
                      forma: p['metodo_pagamento']?.toString() ?? "Pix",
                      valor: p['subtotal']?.toString() ?? "0,00",
                      entrega: p['custo_frete']?.toString() ?? "0,00",
                      total: p['total']?.toString() ?? "0,00",
                      onTap: () => _abrirDetalhesPedido(context, p),
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
}