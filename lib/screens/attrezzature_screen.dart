import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/attrezzature_provider.dart';
import 'mappatura_attrezzatura_screen.dart';
import 'dettaglio_attrezzatura_screen.dart';

class AttrezzatureScreen extends StatefulWidget {
  final bool showAppBar;
  const AttrezzatureScreen({super.key, this.showAppBar = true});

  @override
  State<AttrezzatureScreen> createState() => _AttrezzatureScreenState();
}

class _AttrezzatureScreenState extends State<AttrezzatureScreen> {
  final TextEditingController _codeController = TextEditingController();


  void _handleCodeSubmitted(String code) async {
    if (code.trim().isEmpty) return;

    final provider = context.read<AttrezzatureProvider>();
    final result = await provider.scanCode(code.trim());

    if (result != null) {
      if (!mounted) return;
      if (result.stato == 'non_mappato') {
        // Naviga a mappatura
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MappaturaAttrezzaturaScreen(code: result.codiceIdentificativo),
          ),
        );
      } else {
        // Naviga a dettaglio
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DettaglioAttrezzaturaScreen(code: result.codiceIdentificativo),
          ),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Errore scansione.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startCameraScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Inquadra Codice Attrezzatura'),
            backgroundColor: const Color(0xFFf15a24),
          ),
          body: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  Navigator.pop(context);
                  _handleCodeSubmitted(code);
                }
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttrezzatureProvider>();

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Manutenzione Attrezzature'),
              backgroundColor: const Color(0xFFf15a24),
              actions: [
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _startCameraScanner,
                )
              ],
            )
          : null,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.kitchen_outlined,
                        size: 64,
                        color: Color(0xFFf15a24),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Ristorazione & Cucine',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Inquadra il QR Code o il codice a barre EAN-13 incollato sull\'attrezzatura per mappare la sua posizione o registrare una manutenzione.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFf15a24),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        onPressed: _startCameraScanner,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text(
                          'Scansiona con Fotocamera',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Manual input section
              const Text(
                'Oppure inserisci il codice a mano',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Es. 2000000000015',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2b303a),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _handleCodeSubmitted(_codeController.text),
                    child: const Text('Cerca'),
                  ),
                ],
              ),

              if (provider.isLoading) ...[
                const SizedBox(height: 40),
                const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFf15a24)),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
