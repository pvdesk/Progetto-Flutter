import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/ferie_service.dart';
import '../widgets/responsive_card_grid.dart';
import 'richiesta_ferie_screen.dart';
import 'haccp/signature_dialog.dart';

class FerieScreen extends StatefulWidget {
  const FerieScreen({super.key});

  @override
  State<FerieScreen> createState() => _FerieScreenState();
}

class _FerieScreenState extends State<FerieScreen> with WidgetsBindingObserver {
  late FerieService _ferieService;
  List<dynamic> _richieste = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isArchivio = false;

  @override
  void initState() {
    super.initState();
    final apiService = Provider.of<ApiService>(context, listen: false);
    _ferieService = FerieService(apiService);
    // Ricarica quando l'app torna in primo piano: così le richieste eliminate dal
    // gestionale spariscono anche qui senza dover riavviare l'app.
    WidgetsBinding.instance.addObserver(this);
    _loadStorico();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _loadStorico();
    }
  }

  Future<void> _loadStorico() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final data = await _ferieService.fetchStoricoFerie(archivio: _isArchivio);
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

  void _mostraSceltaFirma(int id) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.password),
                title: Text('Firma con OTP'),
                onTap: () {
                  Navigator.pop(context);
                  _apriFirmaOtp(id);
                },
              ),
              ListTile(
                leading: Icon(Icons.draw),
                title: Text('Firma olografa (su schermo)'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await showDialog(
                    context: context,
                    builder: (_) => const SignatureDialog(),
                  );
                  if (result != null && result is Map) {
                    _firmaOlografa(id, result['firma'], result['device']);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _firmaOlografa(int id, String base64Signature, String deviceInfo) async {
    setState(() => _isLoading = true);
    try {
      await _ferieService.verificaOtp(id, signatureBase64: base64Signature, deviceInfo: deviceInfo);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Richiesta firmata con successo!')),
      );
      _loadStorico();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _eliminaRichiesta(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Richiesta'),
        content: const Text('Sei sicuro di voler eliminare questa richiesta? L\'azione è irreversibile.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _ferieService.deleteRichiesta(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Richiesta eliminata')),
      );
      _loadStorico();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
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
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Attive'),
                  icon: Icon(Icons.list),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text('Archivio'),
                  icon: Icon(Icons.archive),
                ),
              ],
              selected: {_isArchivio},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  _isArchivio = newSelection.first;
                });
                _loadStorico();
              },
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red)))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: _richieste.isEmpty
                        ? Center(child: Text('Nessuna richiesta ferie passata.'))
                        : ResponsiveCardGrid(
                            minColWidth: 520,
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
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () => _mostraSceltaFirma(id),
                                                icon: Icon(Icons.edit),
                                                label: Text('Firma Richiesta'),
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              onPressed: () => _eliminaRichiesta(id),
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              tooltip: 'Elimina richiesta',
                                            ),
                                          ],
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
      await widget.ferieService.verificaOtp(widget.richiestaId, otp: _otpController.text);
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
