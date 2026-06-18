import 'package:flutter/material.dart';

class CardPedido extends StatelessWidget {
  final String idCliente;
  final String status;
  final String duzias;
  final String forma;
  final String valor;
  final String entrega;
  final String total;
  final VoidCallback onTap;
  final String tipoProduto;

  const CardPedido({
    super.key,
    required this.idCliente,
    required this.status,
    required this.duzias,
    required this.forma,
    required this.valor,
    required this.entrega,
    required this.total,
    required this.onTap,
    required this.tipoProduto,
  });

  static const Color _corVerdePrincipal = Color(0xFF27422C);
  static const Color _corTerracota = Color(0xFFBC6C45);
  static const Color _corOuroGema = Color(0xFFCE8615);
  static const Color _corCardLimpo = Color(0xFFFAFAFA);
  static const Color _corMentaInterno = Color(0xFFE9EFEA);
  static const Color _corBordaSutil = Color(0xFFDBE2DB);

  Color _obterCorTextoStatus() {
    switch (status) {
      case "Entregue": return const Color(0xFF2E6930);
      case "Cancelado": return const Color(0xFFC62828);
      case "Em Processo de Entrega": return const Color(0xFF1565C0);
      default: return _corTerracota;
    }
  }

  Color _obterCorFundoStatus() {
    switch (status) {
      case "Entregue": return const Color(0xFFE8F5E9);
      case "Cancelado": return const Color(0xFFFFEBEE);
      case "Em Processo de Entrega": return const Color(0xFFE3F2FD);
      default: return const Color(0xFFFDF2EC);
    }
  }

  String _formatarQuantidade(String valor) {
    final numero = double.tryParse(valor.replaceAll(',', '.').trim());
    if (numero == null) return valor;
    if (numero == numero.roundToDouble()) {
      return numero.round().toString();
    }
    return numero.toString();
  }

  @override
  Widget build(BuildContext context) {
    final Color corTextoStatus = _obterCorTextoStatus();
    final Color corFundoStatus = _obterCorFundoStatus();
    final String qtdFormatada = _formatarQuantidade(duzias);

    String sufixoProduto = "";
    final String produtoLower = tipoProduto.toLowerCase();

    if (produtoLower.contains("extra")) {
      sufixoProduto = " (extra)";
    } else if (produtoLower.contains("jumbo")) {
      sufixoProduto = " (jumbo)";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _corCardLimpo,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _corBordaSutil, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _corVerdePrincipal.withOpacity(0.02),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          splashColor: _corVerdePrincipal.withOpacity(0.05),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.egg_rounded, color: _corOuroGema, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          "Pedido #$idCliente",
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _corVerdePrincipal, letterSpacing: -0.3),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: corFundoStatus, borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(color: corTextoStatus, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.4),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _corMentaInterno.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.layers_rounded, size: 16, color: _corVerdePrincipal.withOpacity(0.6)),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("QUANTIDADE", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _corTerracota.withOpacity(0.8), letterSpacing: 0.4)),
                                const SizedBox(height: 2),
                                Text("$qtdFormatada un.🔖$sufixoProduto", style: const TextStyle(fontWeight: FontWeight.w800, color: _corVerdePrincipal, fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 32, color: _corBordaSutil),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.credit_card_rounded, size: 16, color: _corVerdePrincipal.withOpacity(0.6)),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("PAGAMENTO", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _corTerracota.withOpacity(0.8), letterSpacing: 0.4)),
                                const SizedBox(height: 1),
                                Text(forma, style: const TextStyle(fontWeight: FontWeight.w800, color: _corVerdePrincipal, fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Subtotal: R\$ $valor", style: TextStyle(color: _corVerdePrincipal.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w700)),
                        Text("Frete: R\$ $entrega", style: TextStyle(color: _corVerdePrincipal.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("TOTAL GERAL", style: TextStyle(color: _corTerracota, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.4)),
                        Text("R\$ $total", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _corVerdePrincipal, letterSpacing: -0.4)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}