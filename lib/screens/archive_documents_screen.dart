import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../utils/web_utils.dart';

import '../providers/document_provider.dart';
import '../models/document_model.dart';
import '../services/api_service.dart';

class ArchiveDocumentsScreen extends StatefulWidget {
  final int initialIndex;
  const ArchiveDocumentsScreen({super.key, this.initialIndex = 0});

  @override
  State<ArchiveDocumentsScreen> createState() => _ArchiveDocumentsScreenState();
}

class _ArchiveDocumentsScreenState extends State<ArchiveDocumentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialIndex);
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
        return const Color(0xFFFF4B72);
      case 'certificato_infortunio':
        return const Color(0xFFFF8C61);
      case 'stato_famiglia':
        return const Color(0xFF34D399);
      case 'certificato_residenza':
        return const Color(0xFF60A5FA);
      case 'carta_identita':
        return const Color(0xFF818CF8);
      case 'attestato_alimentarista':
        return const Color(0xFFFBBF24);
      case 'richiesta_assegni_familiari':
        return const Color(0xFF2DD4BF);
      case 'certificato_medico':
        return const Color(0xFFFF4B72);
      default:
        return const Color(0xFF94A3B8);
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
        openUrlInNewTab(downloadUrl);
        if (doc.isCompanySent && !doc.isRead) {
          final docProvider = context.read<DocumentProvider>();
          Future.delayed(const Duration(seconds: 2), () {
            docProvider.markAsRead(doc.id);
          });
        }
      } else {
        final response = await apiService.dio.get(
          'api/mobile/documenti/${doc.id}/download',
          options: Options(responseType: ResponseType.bytes),
        );

        if (!context.mounted) return;

        if (response.statusCode == 200) {
          if (doc.isCompanySent && !doc.isRead) {
            context.read<DocumentProvider>().markAsRead(doc.id);
          }
          
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
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossibile scaricare il file. Riprova.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final documentProvider = context.watch<DocumentProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Archivio Documenti', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF8C61),
          unselectedLabelColor: Colors.white70,
          indicatorColor: Theme.of(context).primaryColor,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Ricevuti'),
                ],
              ),
            ),
            Tab(
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
          _buildDocumentList(context, documentProvider.archivedReceivedDocuments, isReceived: true),
          _buildDocumentList(context, documentProvider.archivedSentDocuments, isReceived: false),
        ],
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
                isReceived ? Icons.inventory_2_outlined : Icons.folder_zip_outlined,
                color: Colors.white.withValues(alpha: 0.15),
                size: 80,
              ),
              const SizedBox(height: 16),
              Text(
                isReceived 
                  ? 'Nessun documento in Archivio Ricevuti.' 
                  : 'Nessun documento in Archivio Inviati.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isReceived
                  ? 'I documenti ricevuti da più di 4 giorni compariranno qui.'
                  : 'I documenti inviati da più di 4 giorni compariranno qui.',
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
                      Text(
                        _formatDate(doc.createdAt),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
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
