import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/haccp_service.dart';
import 'signature_dialog.dart';

class HaccpListScreen extends StatefulWidget {
  const HaccpListScreen({super.key});

  @override
  State<HaccpListScreen> createState() => _HaccpListScreenState();
}

class _HaccpListScreenState extends State<HaccpListScreen> {
  late HaccpService _haccpService;
  List<dynamic> _blocchi = [];
  bool _isLoading = true;

  // Set delle selezioni. La chiave è una stringa composita: "ambito|scope_id|data"
  final Set<String> _selezionati = {};

  @override
  void initState() {
    super.initState();
    final apiService = Provider.of<AuthProvider>(context, listen: false).apiService;
    _haccpService = HaccpService(apiService);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _selezionati.clear();
    });
    final data = await _haccpService.getFirmeDaApporre();
    if (!mounted) return;
    setState(() {
      _blocchi = data;
      _isLoading = false;
    });
  }

  void _toggleSelezione(String key) {
    setState(() {
      if (_selezionati.contains(key)) {
        _selezionati.remove(key);
      } else {
        _selezionati.add(key);
      }
    });
  }

  void _selezionaTutto(List<dynamic> giorni, String ambito, int scopeId) {
    setState(() {
      for (final g in giorni) {
        _selezionati.add('$ambito|$scopeId|$g');
      }
    });
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  /// Etichetta leggibile della frequenza (periodicità della scheda/piano).
  String _labelFrequenza(String p) {
    switch (p) {
      case 'giornaliera':
        return 'Giornaliera';
      case 'due_al_giorno':
        return '2 volte/giorno';
      case 'tre_al_giorno':
        return '3 volte/giorno';
      case 'settimanale':
        return 'Settimanale';
      case 'mensile':
        return 'Mensile';
      case 'ad_evento':
        return 'Ad evento';
      default:
        return p;
    }
  }

  Future<void> _procediFirma() async {
    if (_selezionati.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona almeno un documento da firmare.')),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SignatureDialog(onRichiediOtp: _haccpService.richiediOtp),
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
      });

      // Costruisci l'array di selezioni come richiesto dal backend
      final List<Map<String, dynamic>> selezioneParam = _selezionati.map((s) {
        final parts = s.split('|');
        return {
          'ambito': parts[0],
          'scope_id': int.tryParse(parts[1]) ?? 0,
          'data': parts[2],
        };
      }).toList();

      final modalita = (result['modalita'] as String?) ?? 'olografa';
      final response = await _haccpService.salvaFirma(
        selezioneParam,
        modalita: modalita,
        base64Signature: result['firma'] as String?,
        otp: result['otp'] as String?,
        deviceInfo: (result['device'] as String?) ?? 'Sconosciuto',
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Firma salvata con successo.'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Errore durante il salvataggio.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int get _totaleGiorni => _blocchi.fold<int>(0, (s, b) => s + ((b['giorni'] as List?)?.length ?? 0));

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_rounded, size: 88, color: Colors.green.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          const Text('Tutto firmato!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Nessun documento HACCP da firmare.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  /// Layout responsivo: griglia multi-colonna su tablet, lista su telefono.
  Widget _buildResponsiveBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        // Intestazione riepilogo comune
        final header = Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFf15a24).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFf15a24).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.draw, color: Color(0xFFf15a24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$_totaleGiorni documenti da firmare in ${_blocchi.length} ambiti',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
        );

        if (w >= 800) {
          // Tablet: card a larghezza fissa disposte su più colonne (usa tutto lo schermo).
          final colonne = (w / 460).floor().clamp(2, 4);
          final cardW = (w - 24 - (colonne - 1) * 12) / colonne;
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _blocchi
                        .map((b) => SizedBox(width: cardW, child: _buildBloccoCard(b)))
                        .toList(),
                  ),
                ),
              ],
            ),
          );
        }

        // Telefono: lista a colonna singola.
        return ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            header,
            ..._blocchi.map((b) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: _buildBloccoCard(b),
                )),
          ],
        );
      },
    );
  }

  Widget _buildBloccoCard(dynamic blocco) {
    final label = blocco['label'] ?? 'Ambito sconosciuto';
    final ambito = blocco['ambito'] as String;
    final scopeId = blocco['scope_id'] as int;
    final giorni = blocco['giorni'] as List<dynamic>? ?? [];
    final perFrequenza = blocco['per_frequenza'] as List<dynamic>? ?? [];
    final selezionatiQui = giorni.where((g) => _selezionati.contains('$ambito|$scopeId|$g')).length;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: const Border(),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFf15a24).withValues(alpha: 0.15),
          child: const Icon(Icons.fact_check_outlined, color: Color(0xFFf15a24)),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          selezionatiQui > 0
              ? '$selezionatiQui/${giorni.length} selezionati'
              : '${giorni.length} documenti da firmare',
        ),
        children: [
          if (perFrequenza.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: perFrequenza.map((f) {
                    final periodicita = (f['periodicita'] ?? 'giornaliera').toString();
                    final righe = f['righe'] ?? 0;
                    return Chip(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: const Color(0xFFf15a24).withValues(alpha: 0.10),
                      side: BorderSide(color: const Color(0xFFf15a24).withValues(alpha: 0.3)),
                      label: Text('${_labelFrequenza(periodicita)} · $righe',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFFc44e00))),
                    );
                  }).toList(),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.checklist),
                label: const Text('Seleziona tutti'),
                onPressed: () => _selezionaTutto(giorni, ambito, scopeId),
              ),
            ),
          ),
          ...giorni.map((giorno) {
            final key = '$ambito|$scopeId|$giorno';
            final isSelected = _selezionati.contains(key);
            return CheckboxListTile(
              dense: true,
              title: Text('Schede del ${_formatDate(giorno.toString())}'),
              value: isSelected,
              activeColor: const Color(0xFFf15a24),
              onChanged: (val) => _toggleSelezione(key),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firme HACCP in sospeso'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blocchi.isEmpty
              ? _buildEmptyState()
              : _buildResponsiveBody(),
      floatingActionButton: _selezionati.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isLoading ? null : _procediFirma,
              icon: const Icon(Icons.draw),
              label: Text('Firma ${_selezionati.length} doc.'),
            )
          : null,
    );
  }
}
