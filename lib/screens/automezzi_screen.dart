import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/automezzi_provider.dart';
import '../models/automezzo_model.dart';

class AutomezziScreen extends StatefulWidget {
  const AutomezziScreen({super.key});

  @override
  State<AutomezziScreen> createState() => _AutomezziScreenState();
}

class _AutomezziScreenState extends State<AutomezziScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AutomezziProvider>().fetchAutomezzi();
    });
  }

  void _showInterventoModal(BuildContext context, Automezzo auto) {
    final dataController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final descController = TextEditingController();
    final costoController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16, right: 16, top: 16
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Registra Intervento - ${auto.targa ?? 'N/D'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: dataController,
                decoration: const InputDecoration(labelText: 'Data Intervento (YYYY-MM-DD)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Descrizione Lavori', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: costoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Costo (€)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () async {
                    if (dataController.text.isEmpty || descController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compila data e descrizione')));
                      return;
                    }
                    double? costo = double.tryParse(costoController.text);
                    final success = await context.read<AutomezziProvider>().registerIntervento(
                      auto.id, dataController.text, descController.text, costo
                    );
                    Navigator.pop(ctx);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Intervento registrato con successo!')));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Errore durante il salvataggio')));
                    }
                  },
                  child: const Text('Salva Intervento'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }
    );
  }

  void _showUpdateScadenzeModal(BuildContext context, Automezzo auto) {
    final assController = TextEditingController(text: auto.scadenzaAssicurazione?.substring(0, 10));
    final revController = TextEditingController(text: auto.scadenzaRevisione?.substring(0, 10));
    final tagController = TextEditingController(text: auto.dataTagliando?.substring(0, 10));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16, right: 16, top: 16
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Aggiorna Scadenze - ${auto.targa ?? 'N/D'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: assController,
                decoration: const InputDecoration(labelText: 'Scadenza Assicurazione (YYYY-MM-DD)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: revController,
                decoration: const InputDecoration(labelText: 'Scadenza Revisione (YYYY-MM-DD)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tagController,
                decoration: const InputDecoration(labelText: 'Data Tagliando (YYYY-MM-DD)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () async {
                    final success = await context.read<AutomezziProvider>().updateScadenze(
                      auto.id, {
                        'scadenza_assicurazione': assController.text.isNotEmpty ? assController.text : null,
                        'scadenza_revisione': revController.text.isNotEmpty ? revController.text : null,
                        'data_tagliando': tagController.text.isNotEmpty ? tagController.text : null,
                      }
                    );
                    Navigator.pop(ctx);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scadenze aggiornate!')));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Errore durante l\'aggiornamento')));
                    }
                  },
                  child: const Text('Aggiorna'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }
    );
  }

  Color _getBadgeColor(String? dateStr) {
    if (dateStr == null) return Colors.grey;
    try {
      final date = DateTime.parse(dateStr);
      final days = date.difference(DateTime.now()).inDays;
      if (days < 0) return Colors.red;
      if (days <= 30) return Colors.orange;
      return Colors.green;
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AutomezziProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Automezzi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.fetchAutomezzi(),
          )
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
              ? Center(child: Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: provider.automezzi.length,
                  itemBuilder: (context, index) {
                    final auto = provider.automezzi[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blueAccent),
                                  ),
                                  child: Text(
                                    auto.targa ?? 'N/D',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueAccent),
                                  ),
                                ),
                                Text('${auto.marca ?? ''} ${auto.modello ?? ''}'.trim(), style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (auto.assegnazioneText != null && auto.assegnazioneText!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text(auto.assegnazioneText!, style: const TextStyle(fontSize: 13, color: Colors.black87))),
                                  ],
                                ),
                              ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildScadenzaBadge('Assicurazione', auto.scadenzaAssicurazione),
                                ),
                                Expanded(
                                  child: _buildScadenzaBadge('Revisione', auto.scadenzaRevisione),
                                ),
                                Expanded(
                                  child: _buildScadenzaBadge('Tagliando', auto.dataTagliando),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showUpdateScadenzeModal(context, auto),
                                    icon: const Icon(Icons.edit_calendar, size: 18),
                                    label: const Text('Aggiorna'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showInterventoModal(context, auto),
                                    icon: const Icon(Icons.build, size: 18),
                                    label: const Text('Intervento'),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildScadenzaBadge(String label, String? dateStr) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getBadgeColor(dateStr),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            dateStr != null ? dateStr.substring(0, 10) : 'N/D',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }
}
