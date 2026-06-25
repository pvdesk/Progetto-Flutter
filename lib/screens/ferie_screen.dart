import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/ferie_service.dart';
import 'richiesta_ferie_screen.dart';

class FerieScreen extends StatefulWidget {
  @override
  _FerieScreenState createState() => _FerieScreenState();
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
        final TextEditingController otpController = TextEditingController();
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text('Firma Elettronica (OTP)'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mark_email_read, size: 50, color: Colors.blue),
                  SizedBox(height: 16),
                  Text(
                    'Inserisci il codice OTP di 6 cifre ricevuto via email per confermare e firmare la richiesta.',
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '000000',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: Text('Annulla'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (otpController.text.length != 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Inserisci 6 cifre valide.')),
                            );
                            return;
                          }
                          setModalState(() => isSubmitting = true);
                          try {
                            await _ferieService.verificaOtp(id, otpController.text);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Richiesta firmata con successo!')),
                            );
                            _loadStorico();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                            setModalState(() => isSubmitting = false);
                          }
                        },
                  child: isSubmitting
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Verifica e Firma'),
                ),
              ],
            );
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
              : _richieste.isEmpty
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
                                )).toList(),
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
