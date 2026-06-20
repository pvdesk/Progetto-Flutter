import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../utils/web_utils.dart';

import '../providers/document_provider.dart';
import '../providers/config_provider.dart';
import '../models/document_model.dart';
import '../services/api_service.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentProvider>().fetchDocuments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
  }

  Color _getTypeColor(String type) {
    switch (type) {
      // Documenti ricevuti dall'azienda
      case 'busta_paga':
        return const Color(0xFF00D2FF);
      case 'contratto':
        return const Color(0xFFC084FC);
      case 'comunicazione_interna':
        return const Color(0xFFFFB000);
      // Documenti inviati dal dipendente
      case 'certificato_malattia':
        return const Color(0xFFFF4B72); // rosso/rosa — salute
      case 'certificato_infortunio':
        return const Color(0xFFFF8C61); // arancio — infortunio
      case 'stato_famiglia':
        return const Color(0xFF34D399); // verde — famiglia
      case 'certificato_residenza':
        return const Color(0xFF60A5FA); // blu — residenza
      case 'carta_identita':
        return const Color(0xFF818CF8); // indaco — identità
      case 'attestato_alimentarista':
        return const Color(0xFFFBBF24); // ambra — alimentarista
      case 'richiesta_assegni_familiari':
        return const Color(0xFF2DD4BF); // teal — assegni
      case 'certificato_medico': // legacy
        return const Color(0xFFFF4B72);
      default:
        return const Color(0xFF94A3B8); // grigio — altro
    }
  }

  void _downloadDocument(BuildContext context, DocumentModel doc) async {
    final apiService = context.read<ApiService>();
    final downloadUrl = '${apiService.baseUrl}api/mobile/documenti/${doc.id}/download';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scaricamento in corso: ${doc.nomeFile}...'),
        backgroundColor: Theme.of(context).primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      if (kIsWeb) {
        // Su Web, apriamo semplicemente il link di download in una nuova scheda
        openUrlInNewTab(downloadUrl);
        
        // Se è un documento ricevuto, segnamo come letto localmente poiché il download fa scattare la lettura sul server
        if (doc.isCompanySent && !doc.isRead) {
          Future.delayed(const Duration(seconds: 2), () {
            context.read<DocumentProvider>().markAsRead(doc.id);
          });
        }
      } else {
        // Su Mobile, eseguiamo la chiamata di download
        final response = await apiService.dio.get(
          'api/mobile/documenti/${doc.id}/download',
          options: Options(responseType: ResponseType.bytes),
        );

        if (response.statusCode == 200) {
          // Segnamo come letto se è dell'azienda
          if (doc.isCompanySent && !doc.isRead) {
            context.read<DocumentProvider>().markAsRead(doc.id);
          }
          
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF1E293B),
                title: const Text('Download Completato', style: TextStyle(color: Colors.white)),
                content: Text(
                  'Il file "${doc.nomeFile}" è stato scaricato con successo nella memoria interna.',
                  style: const TextStyle(color: Colors.white70),
                ),
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossibile scaricare il file. Riprova.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showUploadDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const UploadDocumentBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final documentProvider = context.watch<DocumentProvider>();
    final configProvider = context.watch<ConfigProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: configProvider.internalLogoUrl != null
            ? Image.network(
                configProvider.internalLogoUrl!,
                height: 36,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/icon/logo_orizzontale.png',
                  height: 36,
                  fit: BoxFit.contain,
                ),
              )
            : Image.asset(
                'assets/icon/logo_orizzontale.png',
                height: 36,
                fit: BoxFit.contain,
              ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => documentProvider.fetchDocuments(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF8C61),
          unselectedLabelColor: Colors.white70,
          indicatorColor: Theme.of(context).primaryColor,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.download_rounded, size: 18),
                  const SizedBox(width: 8),
                  const Text('Ricevuti'),
                  if (documentProvider.unreadDocumentsCount > 0) ...[
                    const SizedBox(width: 6),
                    Badge(
                      label: Text(documentProvider.unreadDocumentsCount.toString()),
                      backgroundColor: Colors.redAccent,
                    ),
                  ],
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Inviati'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab Documenti Ricevuti
          _buildDocumentList(context, documentProvider.receivedDocuments, isReceived: true),

          // Tab Documenti Inviati
          _buildDocumentList(context, documentProvider.sentDocuments, isReceived: false),
        ],
      ),
      floatingActionButton: ValueListenableBuilder<double>(
        valueListenable: _tabController.animation!,
        builder: (context, value, child) {
          // Mostra il FAB solo se siamo nella seconda scheda (Inviati)
          final isSecondTab = value >= 0.5;
          return AnimatedScale(
            scale: isSecondTab ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: FloatingActionButton(
              backgroundColor: Theme.of(context).primaryColor,
              onPressed: () => _showUploadDialog(context),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocumentList(BuildContext context, List<DocumentModel> docs, {required bool isReceived}) {
    final documentProvider = context.watch<DocumentProvider>();

    if (documentProvider.isLoading && docs.isEmpty) {
      return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
    }

    if (docs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isReceived ? Icons.folder_open_rounded : Icons.cloud_upload_outlined,
                color: Colors.white.withValues(alpha: 0.15),
                size: 80,
              ),
              const SizedBox(height: 16),
              Text(
                isReceived 
                  ? 'Nessun documento ricevuto dall\'azienda.' 
                  : 'Nessun documento inviato all\'azienda.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isReceived
                  ? 'I documenti caricati dall\'amministrazione compariranno qui.'
                  : 'Puoi caricare certificati medici o altri file cliccando il tasto + in basso.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: Theme.of(context).primaryColor,
      onRefresh: () => documentProvider.fetchDocuments(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final doc = docs[index];
          final typeColor = _getTypeColor(doc.tipo);

          return Card(
            color: const Color(0xFF1E293B),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isReceived && !doc.isRead
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.05),
                width: isReceived && !doc.isRead ? 1.5 : 1,
              ),
            ),
            elevation: isReceived && !doc.isRead ? 4 : 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tipo di documento Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: typeColor.withValues(alpha: 0.4), width: 0.8),
                        ),
                        child: Text(
                          doc.tipoEtichetta,
                          style: TextStyle(color: typeColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Spacer(),
                      // Data
                      Text(
                        _formatDate(doc.createdAt),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Titolo
                  Text(
                    doc.titolo,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (doc.descrizione.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      doc.descrizione,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 14),
                  // Info File
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.insert_drive_file_outlined, color: Colors.white54, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            doc.nomeFile,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          doc.formattedSize,
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Azioni specifiche per il documento
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Se è ricevuto ed è da leggere, mostriamo il tasto presa visione
                      if (isReceived && !doc.isRead) ...[
                        OutlinedButton.icon(
                          onPressed: () => documentProvider.markAsRead(doc.id),
                          icon: const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFFFF8C61)),
                          label: const Text('Presa Visione', style: TextStyle(fontSize: 12, color: Color(0xFFFF8C61))),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFF8C61)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ] else if (isReceived && doc.isRead) ...[
                        // Badge "Presa Visione" effettuata
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.tealAccent, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Presa visione il ${DateFormat('dd/MM HH:mm').format(doc.presaVisioneAt!.toLocal())}',
                              style: const TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const Spacer(),
                      ],
                      // Tasto scarica
                      ElevatedButton.icon(
                        onPressed: () => _downloadDocument(context, doc),
                        icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white),
                        label: const Text('Scarica', style: TextStyle(fontSize: 12, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class UploadDocumentBottomSheet extends StatefulWidget {
  const UploadDocumentBottomSheet({super.key});

  @override
  State<UploadDocumentBottomSheet> createState() => _UploadDocumentBottomSheetState();
}

class _UploadDocumentBottomSheetState extends State<UploadDocumentBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedType = 'certificato_malattia';
  
  PlatformFile? _selectedFile;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: true, // Necessario per Flutter Web e comodo per i byte
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          // Precompila il titolo con il nome file senza estensione se vuoto
          if (_titleController.text.isEmpty) {
            final rawName = _selectedFile!.name;
            final dotIndex = rawName.lastIndexOf('.');
            _titleController.text = dotIndex != -1 ? rawName.substring(0, dotIndex) : rawName;
          }
        });
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossibile selezionare il file.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona un file da caricare.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final bytes = _selectedFile!.bytes;
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore nella lettura del file (dati vuoti).'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = context.read<DocumentProvider>();
    final success = await provider.uploadDocument(
      title: _titleController.text.trim(),
      type: _selectedType,
      bytes: bytes,
      filename: _selectedFile!.name,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documento inviato all\'azienda con successo!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Errore nel caricamento del documento.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Spazio aggiuntivo per la tastiera su mobile
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: 20.0 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Invia Documento all\'Azienda',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 20),
              const SizedBox(height: 8),

              // Titolo
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Titolo Documento',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.04),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Inserisci un titolo' : null,
              ),
              const SizedBox(height: 16),

              // Categoria / Tipo
              DropdownButtonFormField<String>(
                value: _selectedType,
                style: const TextStyle(color: Colors.white),
                dropdownColor: const Color(0xFF1E293B),
                decoration: InputDecoration(
                  labelText: 'Tipo di Documento',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.04),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'certificato_malattia',
                    child: Text('Certificato di Malattia'),
                  ),
                  DropdownMenuItem(
                    value: 'certificato_infortunio',
                    child: Text('Certificato Infortunio'),
                  ),
                  DropdownMenuItem(
                    value: 'stato_famiglia',
                    child: Text('Stato di Famiglia'),
                  ),
                  DropdownMenuItem(
                    value: 'certificato_residenza',
                    child: Text('Certificato Residenza'),
                  ),
                  DropdownMenuItem(
                    value: 'carta_identita',
                    child: Text("Carta d'Identità"),
                  ),
                  DropdownMenuItem(
                    value: 'attestato_alimentarista',
                    child: Text('Attestato Alimentarista'),
                  ),
                  DropdownMenuItem(
                    value: 'richiesta_assegni_familiari',
                    child: Text('Richiesta Assegni Familiari'),
                  ),
                  DropdownMenuItem(
                    value: 'altro',
                    child: Text('Altro'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedType = val);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Note/Descrizione
              TextFormField(
                controller: _descController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Note aggiuntive (Opzionale)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.04),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // File Picker Area
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedFile != null ? Theme.of(context).primaryColor : Colors.white24,
                      style: BorderStyle.solid,
                      width: _selectedFile != null ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFile != null ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
                        color: _selectedFile != null ? Colors.greenAccent : const Color(0xFFFF8C61),
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _selectedFile != null ? _selectedFile!.name : 'Seleziona un file (PDF, Immagine)',
                        style: TextStyle(
                          color: _selectedFile != null ? Colors.white : Colors.white70,
                          fontSize: 14,
                          fontWeight: _selectedFile != null ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_selectedFile != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Dimensione: ${( _selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ] else ...[
                        const SizedBox(height: 4),
                        const Text(
                          'Premi per esplorare i file',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tasti Azione
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text('Annulla', style: TextStyle(color: Color(0xFFFF8C61))),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Invia Documento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
