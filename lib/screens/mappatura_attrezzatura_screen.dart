import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attrezzature_provider.dart';
import '../models/tipo_attrezzatura_model.dart';
import 'dettaglio_attrezzatura_screen.dart';

class MappaturaAttrezzaturaScreen extends StatefulWidget {
  final String code;

  const MappaturaAttrezzaturaScreen({super.key, required this.code});

  @override
  State<MappaturaAttrezzaturaScreen> createState() => _MappaturaAttrezzaturaScreenState();
}

class _MappaturaAttrezzaturaScreenState extends State<MappaturaAttrezzaturaScreen> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedTipoId;
  final _marcaController = TextEditingController();
  final _modelloController = TextEditingController();
  final _matricolaController = TextEditingController();
  final _descrizioneController = TextEditingController();

  String _destinazione = 'nessuna'; // nessuna, commessa, centro_cottura
  int? _selectedCommessaId;
  int? _selectedPuntoId;
  int? _selectedCentroId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttrezzatureProvider>().fetchMappaturaLists();
    });
  }

  @override
  void dispose() {
    _marcaController.dispose();
    _modelloController.dispose();
    _matricolaController.dispose();
    _descrizioneController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AttrezzatureProvider>();

    final Map<String, dynamic> data = {
      'tipo_attrezzatura_id': _selectedTipoId,
      'marca': _marcaController.text.trim(),
      'modello': _modelloController.text.trim(),
      'matricola': _matricolaController.text.trim(),
      'descrizione': _descrizioneController.text.trim(),
      'destinazione': _destinazione,
      'stato': 'attivo', // una volta mappata, diventa attiva
    };

    if (_destinazione == 'commessa') {
      data['commessa_id'] = _selectedCommessaId;
      data['punto_servizio_id'] = _selectedPuntoId;
    } else if (_destinazione == 'centro_cottura') {
      data['centro_produttivo_id'] = _selectedCentroId;
    }

    final success = await provider.mappa(widget.code, data);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attrezzatura mappata con successo!'),
          backgroundColor: Colors.green,
        ),
      );
      // Naviga alla scheda di dettaglio sostituendo la schermata corrente
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DettaglioAttrezzaturaScreen(code: widget.code),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Errore nel salvataggio della mappatura.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttrezzatureProvider>();

    // Filtra i punti di servizio in base alla commessa selezionata
    final List filteredPunti = _selectedCommessaId == null
        ? []
        : provider.puntiServizio.where((p) => p['commessa_id'] == _selectedCommessaId).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mappa Nuova Attrezzatura'),
        backgroundColor: const Color(0xFFf15a24),
      ),
      body: provider.isLoading && provider.tipi.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFf15a24)),
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Code banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.qr_code, color: Colors.black54),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CODICE IDENTIFICATIVO EAN-13',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                              Text(
                                widget.code,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tipo attrezzatura dropdown
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Tipologia Macchinario *',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _selectedTipoId,
                      items: provider.tipi.map((TipoAttrezzatura t) {
                        return DropdownMenuItem<int>(
                          value: t.id,
                          child: Text('[${t.sezione.toUpperCase()}] ${t.label}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedTipoId = val;
                        });
                      },
                      validator: (value) => value == null ? 'Seleziona una tipologia' : null,
                    ),
                    const SizedBox(height: 16),

                    // Dati tecnici
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _marcaController,
                            decoration: const InputDecoration(
                              labelText: 'Marca',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _modelloController,
                            decoration: const InputDecoration(
                              labelText: 'Modello',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _matricolaController,
                      decoration: const InputDecoration(
                        labelText: 'Matricola / Serial Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descrizioneController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Note aggiuntive / Descrizione',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Destinazione/Posizione
                    const Text(
                      'Collocazione Attrezzatura',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Destinazione Principale',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _destinazione,
                      items: const [
                        DropdownMenuItem(value: 'nessuna', child: Text('Nessuna (Magazzino)')),
                        DropdownMenuItem(value: 'commessa', child: Text('Commessa / Punto Servizio')),
                        DropdownMenuItem(value: 'centro_cottura', child: Text('Centro Cottura')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _destinazione = val ?? 'nessuna';
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    if (_destinazione == 'commessa') ...[
                      // Commesse dropdown
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Seleziona Commessa *',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _selectedCommessaId,
                        items: provider.commesse.map((c) {
                          return DropdownMenuItem<int>(
                            value: c['id'],
                            child: Text('${c['codice']} - ${c['titolo'] ?? c['nome']}'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCommessaId = val;
                            _selectedPuntoId = null; // reset punto al cambio commessa
                          });
                        },
                        validator: (value) => _destinazione == 'commessa' && value == null ? 'Seleziona una commessa' : null,
                      ),
                      const SizedBox(height: 16),

                      // Punti servizio dropdown
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Punto Servizio (Cucina/Mensa)',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _selectedPuntoId,
                        items: filteredPunti.map((p) {
                          return DropdownMenuItem<int>(
                            value: p['id'],
                            child: Text(p['nome'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedPuntoId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_destinazione == 'centro_cottura') ...[
                      // Centri Cottura dropdown
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Seleziona Centro Cottura *',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _selectedCentroId,
                        items: provider.centriCottura.map((cc) {
                          return DropdownMenuItem<int>(
                            value: cc['id'],
                            child: Text(cc['nome'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCentroId = val;
                          });
                        },
                        validator: (value) => _destinazione == 'centro_cottura' && value == null ? 'Seleziona un centro cottura' : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 20),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFf15a24),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: provider.isLoading ? null : _submitForm,
                      child: provider.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Mappa Attrezzatura',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
