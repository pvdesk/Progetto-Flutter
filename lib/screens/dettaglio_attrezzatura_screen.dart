import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/attrezzature_provider.dart';
import '../models/attrezzatura_model.dart';

class DettaglioAttrezzaturaScreen extends StatefulWidget {
  final String code;

  const DettaglioAttrezzaturaScreen({super.key, required this.code});

  @override
  State<DettaglioAttrezzaturaScreen> createState() => _DettaglioAttrezzaturaScreenState();
}

class _DettaglioAttrezzaturaScreenState extends State<DettaglioAttrezzaturaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttrezzatureProvider>().scanCode(widget.code);
    });
  }

  void _showAddInterventoBottomSheet(BuildContext context, Attrezzatura att) {
    final dataController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final descController = TextEditingController();
    final costoController = TextEditingController();
    File? selectedFile;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Future<void> pickFile() async {
              try {
                final result = await FilePicker.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                );
                if (result != null && result.files.single.path != null) {
                  setModalState(() {
                    selectedFile = File(result.files.single.path!);
                  });
                }
              } catch (e) {
                debugPrint('Errore pick file: $e');
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nuovo Intervento Interno',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 16),
                    TextField(
                      controller: dataController,
                      decoration: const InputDecoration(
                        labelText: 'Data Intervento (YYYY-MM-DD)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.datetime,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descrizione Lavori Svolti',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: costoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Costo Ricambi (€) - Opzionale',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.euro),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // File selection widget
                    InkWell(
                      onTap: pickFile,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[100],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_file, color: Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                selectedFile == null
                                    ? 'Allega foto / rapporto (PDF/Img)'
                                    : selectedFile!.path.split('/').last,
                                style: TextStyle(
                                  color: selectedFile == null ? Colors.black54 : Colors.black87,
                                  fontWeight: selectedFile == null ? FontWeight.normal : FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (selectedFile != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setModalState(() {
                                    selectedFile = null;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFf15a24),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (dataController.text.isEmpty || descController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Data e descrizione sono obbligatorie.')),
                          );
                          return;
                        }

                        final provider = context.read<AttrezzatureProvider>();
                        final double? costVal = double.tryParse(costoController.text);
                        
                        Navigator.pop(ctx); // Chiude il BottomSheet

                        final success = await provider.registraIntervento(
                          code: att.codiceIdentificativo,
                          dataIntervento: dataController.text.trim(),
                          descrizione: descController.text.trim(),
                          costo: costVal,
                          documento: selectedFile,
                        );

                        if (success) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Intervento registrato con successo!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(provider.errorMessage ?? 'Errore nel salvataggio dell\'intervento.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text('Salva Rapporto Intervento', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttrezzatureProvider>();
    final att = provider.scannedAttrezzatura;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dettaglio Attrezzatura'),
        backgroundColor: const Color(0xFFf15a24),
      ),
      body: provider.isLoading && att == null
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFf15a24)),
              ),
            )
          : att == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          provider.errorMessage ?? 'Impossibile caricare l\'attrezzatura.',
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Torna Indietro'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => provider.scanCode(widget.code),
                  color: const Color(0xFFf15a24),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card Dettagli Macchina
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      att.tipoAttrezzatura != null ? att.tipoAttrezzatura!.label : 'Attrezzatura Mappata',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: att.stato == 'attivo' ? Colors.green[100] : Colors.amber[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        att.stato.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: att.stato == 'attivo' ? Colors.green[800] : Colors.amber[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (att.tipoAttrezzatura != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Sezione: ${att.tipoAttrezzatura!.sezione.toUpperCase()}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.bold),
                                  ),
                                ],
                                const Divider(height: 24),
                                _buildDetailRow('EAN-13 Barcode', att.codiceIdentificativo),
                                _buildDetailRow('Marca / Produttore', att.marca ?? 'N/D'),
                                _buildDetailRow('Modello', att.modello ?? 'N/D'),
                                _buildDetailRow('Matricola / Serial', att.matricola ?? 'N/D'),
                                _buildDetailRow('Note / Descrizione', att.descrizione ?? 'Nessuna nota aggiuntiva'),
                                const Divider(height: 24),
                                
                                // Collocazione
                                const Text(
                                  'COLLOCAZIONE',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, color: Color(0xFFf15a24), size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        att.commessaNome != null
                                            ? 'Commessa: ${att.commessaNome}' + (att.puntoServizioNome != null ? '\nLocazione: ${att.puntoServizioNome}' : '')
                                            : att.centroProduttivoNome != null
                                                ? 'Centro Cottura: ${att.centroProduttivoNome}'
                                                : 'Nessuna collocazione (Magazzino / Non allocato)',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Action button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2b303a),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _showAddInterventoBottomSheet(context, att),
                          icon: const Icon(Icons.add_task),
                          label: const Text('Registra Intervento Interno', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),

                        const SizedBox(height: 30),

                        // Storico Interventi
                        Row(
                          children: [
                            const Icon(Icons.history, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Storico Manutenzioni (${att.interventi.length})',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (att.interventi.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Text(
                                'Nessun intervento registrato.',
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: att.interventi.length,
                            itemBuilder: (context, index) {
                              final intv = att.interventi[index];
                              final date = intv.dataIntervento.length >= 10
                                  ? intv.dataIntervento.substring(0, 10).split('-').reversed.join('/')
                                  : intv.dataIntervento;
                              
                              final isInterno = intv.tipoManutenzione == 'interna';
                              final dittaTecnico = isInterno
                                  ? (intv.userName ?? 'Tecnico Interno')
                                  : (intv.dittaNome ?? 'Ditta Esterna');

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            date,
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isInterno ? Colors.blue[50] : Colors.orange[50],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              isInterno ? 'INTERNA' : 'ESTERNA',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: isInterno ? Colors.blue[800] : Colors.orange[800],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        dittaTecnico,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        intv.descrizione,
                                        style: TextStyle(color: Colors.grey[800], fontSize: 13),
                                      ),
                                      if (intv.costo != null && intv.costo! > 0) ...[
                                        const SizedBox(height: 10),
                                        Text(
                                          'Costo: € ${intv.costo!.toStringAsFixed(2)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
