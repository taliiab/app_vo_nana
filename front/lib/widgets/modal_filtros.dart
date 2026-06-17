import 'package:flutter/material.dart';

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