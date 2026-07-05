import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import '../providers/ddt_provider.dart';
import '../services/ddt_service.dart';
import '../services/api_service.dart';
import 'pdf_viewer_screen.dart';

class DdtDetailScreen extends StatefulWidget {
  final int ddtId;

  const DdtDetailScreen({super.key, required this.ddtId});

  @override
  State<DdtDetailScreen> createState() => _DdtDetailScreenState();
}

class _DdtDetailScreenState extends State<DdtDetailScreen> {
  bool _isDownloadingPdf = false;
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.white,
    exportBackgroundColor: Colors.transparent,
  );
  
  String _selectedRole = 'autista';
  final TextEditingController _nomeController = TextEditingController();
  bool _isSigning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DdtProvider>().fetchDdtDetail(widget.ddtId);
    });
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _viewPdf() async {
    final provider = context.read<DdtProvider>();
    if (provider.selectedDdt == null) return;

    setState(() {
      _isDownloadingPdf = true;
    });

    try {
      final apiService = context.read<ApiService>();
      final file = await DdtService(apiService).downloadDdtPdf(widget.ddtId, provider.selectedDdt!.numero);
      
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(
            file: file,
            title: 'DDT ${provider.selectedDdt!.numero}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingPdf = false;
        });
      }
    }
  }

  Future<void> _changeStato(String nuovoStato) async {
    try {
      await context.read<DdtProvider>().updateStato(widget.ddtId, nuovoStato);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stato aggiornato')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _submitFirma() async {
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La firma è vuota.')));
      return;
    }

    setState(() {
      _isSigning = true;
    });

    try {
      final signatureBytes = await _signatureController.toPngBytes();
      if (signatureBytes == null) {
        throw Exception('Errore nella generazione dell\'immagine della firma.');
      }
      final base64Signature = base64Encode(signatureBytes);

      await context.read<DdtProvider>().inviaFirma(
        widget.ddtId,
        _selectedRole,
        base64Signature,
        _nomeController.text.isNotEmpty ? _nomeController.text : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Firma salvata con successo.')));
      _signatureController.clear();
      _nomeController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isSigning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dettaglio DDT'),
      ),
      body: Consumer<DdtProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingDetail) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.detailErrorMessage != null) {
            return Center(child: Text(provider.detailErrorMessage!, style: const TextStyle(color: Colors.red)));
          }

          final ddt = provider.selectedDdt;
          if (ddt == null) {
            return const Center(child: Text('Nessun dettaglio disponibile.'));
          }

          return SafeArea(
            bottom: true,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Numero: ${ddt.numero}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('Data: ${ddt.data ?? "-"}'),
                            Text('Stato: ${ddt.stato}'),
                            if (ddt.origine != null) Text('Origine: ${ddt.origine}'),
                            if (ddt.destinatario != null) Text('Destinatario: ${ddt.destinatario}'),
                            if (ddt.indirizzo != null) Text('Indirizzo: ${ddt.indirizzo}'),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                if (ddt.stato == 'emesso')
                                  ElevatedButton(
                                    onPressed: () => _changeStato('in_transito'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                    child: const Text('Inizia Trasporto'),
                                  ),
                                if (ddt.stato == 'in_transito')
                                  ElevatedButton(
                                    onPressed: () => _changeStato('consegnato'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    child: const Text('Segna Consegnato'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isDownloadingPdf ? null : _viewPdf,
                                icon: _isDownloadingPdf
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.picture_as_pdf),
                                label: const Text('Visualizza PDF'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Righe DDT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ...ddt.righe.map((riga) => ListTile(
                      title: Text(riga.descrizione ?? riga.codice ?? '-'),
                      trailing: Text('${riga.quantita ?? ""} ${riga.um ?? ""}'),
                    )),
                    const SizedBox(height: 16),
                    const Text('Firme acquisite', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (ddt.firme.isEmpty) const Text('Nessuna firma acquisita.'),
                    ...ddt.firme.map((firma) => ListTile(
                      leading: const Icon(Icons.verified),
                      title: Text('Ruolo: ${firma.ruolo}'),
                      subtitle: Text('Nome: ${firma.nome ?? "-"}\nData: ${firma.firmatoAt ?? "-"}'),
                    )),
                    const SizedBox(height: 24),
                    
                    // Modulo Firma
                    const Text('Acquisisci Firma a monitor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      items: const [
                        DropdownMenuItem(value: 'autista', child: Text('Autista')),
                        DropdownMenuItem(value: 'ricevente', child: Text('Ricevente')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRole = val);
                      },
                      decoration: const InputDecoration(labelText: 'Ruolo firmatario', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nomeController,
                      decoration: const InputDecoration(labelText: 'Nome firmatario (opzionale)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                      child: Signature(
                        controller: _signatureController,
                        height: 200,
                        backgroundColor: Colors.black12,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _signatureController.clear(),
                          child: const Text('Pulisci'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSigning ? null : _submitFirma,
                        child: _isSigning
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Salva Firma'),
                      ),
                    ),
                    const SizedBox(height: 40), // Spazio aggiuntivo in fondo per non sovrapporsi ai comandi di sistema
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
