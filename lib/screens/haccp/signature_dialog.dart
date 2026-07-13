import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class SignatureDialog extends StatefulWidget {
  const SignatureDialog({super.key});

  @override
  State<SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<SignatureDialog> {
  late SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _conferma() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Per favore, apponi la tua firma.')),
      );
      return;
    }

    final Uint8List? data = await _controller.toPngBytes();
    if (!mounted) return;
    if (data != null) {
      final base64Image = base64Encode(data);
      final deviceInfo = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
      Navigator.of(context).pop({
        'firma': base64Image,
        'device': deviceInfo,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Errore durante il salvataggio della firma.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Dialog(
      // Margini ridotti → il riquadro usa quasi tutta la larghezza dello schermo,
      // restando comunque dentro i bordi (rettangolo largo, non quadrato).
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Intestazione ──
            Row(
              children: [
                Icon(Icons.draw_outlined, color: primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Apponi la tua firma',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text('Firma nel riquadro usando il dito o un pennino capacitivo.',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
            const SizedBox(height: 14),

            // ── Riquadro firma rettangolare (responsive) ──
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                // Rettangolo orizzontale: altezza ~42% della larghezza, tra 150 e 210px.
                final h = (w * 0.42).clamp(150.0, 210.0);
                return Container(
                  height: h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        // Riga di base "firma qui" + segnaposto, nascosti quando si firma.
                        ListenableBuilder(
                          listenable: _controller,
                          builder: (context, _) {
                            if (_controller.isNotEmpty) return const SizedBox.shrink();
                            return Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text('Firma qui',
                                        style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text('✕', style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
                                        const SizedBox(width: 6),
                                        Expanded(child: Container(height: 1, color: Colors.grey.shade300)),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        Signature(
                          controller: _controller,
                          backgroundColor: Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _controller.clear(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Pulisci'),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
              ),
            ),
            const Divider(height: 12),

            // ── Azioni ──
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annulla'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _conferma,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Conferma firma'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
