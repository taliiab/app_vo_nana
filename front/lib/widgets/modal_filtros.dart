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

  final Color _corVerdeForte = const Color(0xFF3B5E41);
  final Color _corVerdeSuave = const Color(0xFF75A97D);

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
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: _corVerdeSuave,
            onPrimary: Colors.white,
            onSurface: _corVerdeForte,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: _corVerdeForte),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => isDe ? dataDe = picked : dataAte = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune_rounded, color: _corVerdeForte, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      "Filtrar Pedidos",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _corVerdeForte),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: Colors.grey[600]),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),

          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              children: [
                _buildTituloSecao("Período de Entrega"),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDataCard("De", dataDe, true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDataCard("Até", dataAte, false)),
                  ],
                ),

                const SizedBox(height: 28),

                _buildTituloSecao("Status do Pedido"),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChipFiltro("Pendente", pendente, (v) => setState(() => pendente = v)),
                    _buildChipFiltro("Em Processo", emProcesso, (v) => setState(() => emProcesso = v)),
                    _buildChipFiltro("Entregue", entregue, (v) => setState(() => entregue = v)),
                    _buildChipFiltro("Cancelado", cancelado, (v) => setState(() => cancelado = v)),
                  ],
                ),

                const SizedBox(height: 28),

                _buildTituloSecao("Situação do Pagamento"),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChipFiltro("Aprovado", aprovado, (v) => setState(() => aprovado = v)),
                    _buildChipFiltro("Pendente", pagPendente, (v) => setState(() => pagPendente = v)),
                  ],
                ),

                const SizedBox(height: 44),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        'dataDe': dataDe,
                        'dataAte': dataAte,
                        'statusPedidos': {
                          "Pendente": pendente,
                          "Em Processo de Entrega": emProcesso,
                          "Entregue": entregue,
                          "Cancelado": cancelado
                        },
                        'statusPagamento': {
                          "Aprovado": aprovado,
                          "Pendente": pagPendente
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _corVerdeSuave,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                        "Aplicar Filtros Avançados",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTituloSecao(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: _corVerdeForte.withOpacity(0.8),
          letterSpacing: 0.8
      ),
    );
  }

  Widget _buildDataCard(String prefixo, DateTime date, bool isDe) {
    return InkWell(
      onTap: () => _pickDate(context, isDe),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4F1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prefixo, style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(_formatDate(date), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
            Icon(Icons.calendar_month_outlined, size: 18, color: _corVerdeForte),
          ],
        ),
      ),
    );
  }

  Widget _buildChipFiltro(String texto, bool selecionado, ValueChanged<bool> onSelected) {
    return FilterChip(
      label: Text(texto),
      selected: selecionado,
      onSelected: onSelected,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: selecionado ? FontWeight.bold : FontWeight.w500,
        color: selecionado ? Colors.white : Colors.grey[700],
      ),
      backgroundColor: const Color(0xFFF0F4F1),
      selectedColor: _corVerdeSuave,
      checkmarkColor: Colors.white,
      side: BorderSide.none,
      elevation: 0,
      pressElevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}