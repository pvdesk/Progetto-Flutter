import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signature/signature.dart';

/// Dialog di firma HACCP: firma OLOGRAFA (signature pad) oppure OTP.
/// Ritorna una mappa:
///  - olografa: modalita=olografa, firma=base64 PNG, device=info
///  - otp:      modalita=otp, otp=codice
class SignatureDialog extends StatefulWidget {
  /// Callback che richiede un OTP al backend. Se null, la modalità OTP è nascosta.
  final Future<Map<String, dynamic>> Function()? onRichiediOtp;

  const SignatureDialog({super.key, this.onRichiediOtp});

  @override
  State<SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<SignatureDialog> {
  late SignatureController _controller;
  String _modalita = 'olografa'; // 'olografa' | 'otp'
  final TextEditingController _otpController = TextEditingController();
  bool _otpInviato = false;
  bool _otpLoading = false;

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
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _inviaOtp() async {
    if (widget.onRichiediOtp == null) return;
    setState(() => _otpLoading = true);
    final res = await widget.onRichiediOtp!();
    if (!mounted) return;
    setState(() {
      _otpLoading = false;
      _otpInviato = res['success'] == true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message'] ?? (res['success'] == true ? 'OTP inviato.' : 'Errore invio OTP.')),
        backgroundColor: res['success'] == true ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _conferma() async {
    if (_modalita == 'otp') {
      final code = _otpController.text.trim();
      if (code.length < 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inserisci il codice OTP ricevuto.')),
        );
        return;
      }
      Navigator.of(context).pop({'modalita': 'otp', 'otp': code});
      return;
    }

    // olografa
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
      Navigator.of(context).pop({'modalita': 'olografa', 'firma': base64Image, 'device': deviceInfo});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Errore durante il salvataggio della firma.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final bool otpDisponibile = widget.onRichiediOtp != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.verified_user_outlined, color: primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Firma verifica HACCP',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Selettore modalità
            if (otpDisponibile)
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'olografa', label: Text('Olografa'), icon: Icon(Icons.draw_outlined, size: 18)),
                  ButtonSegment(value: 'otp', label: Text('OTP'), icon: Icon(Icons.password, size: 18)),
                ],
                selected: {_modalita},
                onSelectionChanged: (s) => setState(() => _modalita = s.first),
              ),
            if (otpDisponibile) const SizedBox(height: 12),

            if (_modalita == 'olografa') ..._buildOlografa() else ..._buildOtp(),

            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annulla')),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _conferma,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Conferma'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOlografa() {
    return [
      Text('Firma nel riquadro usando il dito o un pennino capacitivo.',
          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = (w * 0.42).clamp(150.0, 210.0);
          return Container(
            height: h,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Signature(controller: _controller, backgroundColor: Colors.transparent),
            ),
          );
        },
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => _controller.clear(),
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Pulisci'),
        ),
      ),
    ];
  }

  List<Widget> _buildOtp() {
    return [
      Text('Ricevi un codice OTP sulla tua app (chat/notifica) e inseriscilo qui per firmare.',
          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: _otpLoading ? null : _inviaOtp,
        icon: _otpLoading
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.send, size: 18),
        label: Text(_otpInviato ? 'Reinvia OTP' : 'Invia OTP'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '',
          hintText: '------',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    ];
  }
}
