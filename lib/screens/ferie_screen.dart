import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/ferie_service.dart';
import 'richiesta_ferie_screen.dart';

class FerieScreen extends StatefulWidget {
  const FerieScreen({super.key});

  @override
  State<FerieScreen> createState() => _FerieScreenState();
}

class _FerieScreenState extends State<FerieScreen> {
  late FerieService _ferieService;
  List<dynamic> _richieste = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    final apiService = Provider.of<ApiService>(context, listen: false);
    _ferieService = FerieService(apiService);
    _loadStorico();
  }

  Future<void> _loadStorico() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final data = await _ferieService.fetchStoricoFerie();
      setState(() {
        _richieste = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _apriFirmaOtp(int id) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _OtpDialog(
          richiestaId: id,
          ferieService: _ferieService,
          onSuccess: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Richiesta firmata con successo!')),
            );
            _loadStorico();
          },
        );
      },
    );
  }

  String _formatDateString(dynamic dateValue) {
    if (dateValue == null) return '';
    final String dateStr = dateValue.toString();
    try {
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null) {
        return DateFormat('dd/MM/yyyy').format(parsed);
      }
    } catch (_) {}
    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ferie e Permessi'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadStorico,
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red)))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: _richieste.isEmpty
                        ? Center(child: Text('Nessuna richiesta ferie passata.'))
                        : ListView.builder(
                            itemCount: _richieste.length,
                            itemBuilder: (context, index) {
                              final req = _richieste[index];
                              final stato = req['stato'];
                              final id = req['id'];
                              final dateStr = req['data_richiesta']; // es. 2026-06-20
                              final formattedDate = _formatDateString(dateStr);
                              
                              Color statoColor = Colors.grey;
                              String statoText = stato;
                              
                              if (stato == 'in_attesa_otp') {
                                statoColor = Colors.orange;
                                statoText = 'Da firmare (OTP)';
                              } else if (stato == 'in_attesa') {
                                statoColor = Colors.red; // in attesa di conferma → rosso
                                statoText = 'In attesa di approvazione';
                              } else if (stato == 'approvata') {
                                statoColor = Colors.green; // approvata → verde
                                statoText = 'Approvata';
                              } else if (stato == 'rifiutata') {
                                statoColor = Colors.blueGrey; // rifiutata → grigio (distinta dal rosso 'in attesa')
                                statoText = 'Rifiutata';
                              }

                              List periodi = req['periodi'] ?? [];
                              
                              return Card(
                                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Richiesta del $formattedDate',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Chip(
                                            label: Text(statoText, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                            backgroundColor: statoColor,
                                            padding: EdgeInsets.zero,
                                          ),
                                        ],
                                      ),
                                      Divider(),
                                      ...periodi.map((p) => Container(
                                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: statoColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border(left: BorderSide(color: statoColor, width: 4)),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.date_range, size: 16, color: statoColor),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '${_formatDateString(p['data_inizio'])} → ${_formatDateString(p['data_fine'])}',
                                                style: const TextStyle(fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),),
                                      if (stato == 'in_attesa_otp') ...[
                                        SizedBox(height: 16),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () => _apriFirmaOtp(id),
                                            icon: Icon(Icons.edit),
                                            label: Text('Firma con OTP'),
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                          ),
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RichiestaFerieScreen(ferieService: _ferieService)),
          );
          if (result == true) {
            _loadStorico();
          }
        },
        icon: Icon(Icons.add),
        label: Text('Nuova Richiesta'),
      ),
    );
  }
}

class _OtpDialog extends StatefulWidget {
  final int richiestaId;
  final FerieService ferieService;
  final VoidCallback onSuccess;

  const _OtpDialog({
    required this.richiestaId,
    required this.ferieService,
    required this.onSuccess,
  });

  @override
  State<_OtpDialog> createState() => _OtpDialogState();
}

class _OtpDialogState extends State<_OtpDialog> {
  final TextEditingController _otpController = TextEditingController();
  bool _isSubmitting = false;
  bool _isResending = false;
  int _countdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    setState(() {
      _canResend = false;
      _countdown = 60;
    });
    _tick();
  }

  void _tick() {
    if (!mounted) return;
    if (_countdown > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() {
          _countdown--;
        });
        _tick();
      });
    } else {
      setState(() {
        _canResend = true;
      });
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isResending = true;
    });
    try {
      await widget.ferieService.resendOtp(widget.richiestaId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nuovo codice OTP inviato con successo!')),
      );
      _startCountdown();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci 6 cifre valide.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await widget.ferieService.verificaOtp(widget.richiestaId, _otpController.text);
      if (!mounted) return;
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Firma Elettronica (OTP)'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mark_email_read, size: 50, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Inserisci il codice OTP di 6 cifre ricevuto via email per confermare e firmare la richiesta.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '000000',
              ),
            ),
            const SizedBox(height: 16),
            if (_isResending)
              const CircularProgressIndicator()
            else if (!_canResend)
              Text(
                'Puoi richiedere un nuovo OTP tra $_countdown secondi',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              )
            else
              TextButton.icon(
                onPressed: _resendOtp,
                icon: const Icon(Icons.refresh),
                label: const Text('Richiedi nuovo OTP'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Verifica e Firma'),
        ),
      ],
    );
  }
}
