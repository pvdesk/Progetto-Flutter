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
    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('Apponi la tua firma')),
          Tooltip(
            message: 'Firma all\'interno del riquadro bianco.\nUsa il dito o un pennino capacitivo.',
            child: Icon(Icons.help_outline, color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Signature(
            controller: _controller,
            backgroundColor: Colors.white,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _controller.clear(),
          child: const Text('Pulisci'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _conferma,
          child: const Text('Conferma Firma'),
        ),
      ],
    );
  }
}
