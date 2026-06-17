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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
                      color: status == "Entregue"
                          ? Colors.green[800]
                          : status == "Cancelado"
                          ? Colors.red[800]
                          : Colors.orange[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
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
        ),
      ),
    );
  }
}