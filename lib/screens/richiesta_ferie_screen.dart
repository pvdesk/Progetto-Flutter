import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/ferie_service.dart';

class RichiestaFerieScreen extends StatefulWidget {
  final FerieService ferieService;

  const RichiestaFerieScreen({Key? key, required this.ferieService}) : super(key: key);

  @override
  _RichiestaFerieScreenState createState() => _RichiestaFerieScreenState();
}

class _RichiestaFerieScreenState extends State<RichiestaFerieScreen> {
  final List<Map<String, DateTime>> _periodi = [];
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  void _addPeriod() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _periodi.add({
          'inizio': picked.start,
          'fine': picked.end,
        });
      });
    }
  }

  void _removePeriod(int index) {
    setState(() {
      _periodi.removeAt(index);
    });
  }

  void _submit() async {
    if (_periodi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aggiungi almeno un periodo di ferie.')),
      );
      return;
    }

    final format = DateFormat('yyyy-MM-dd');
    final formattedPeriodi = _periodi.map((p) => {
      'inizio': format.format(p['inizio']!),
      'fine': format.format(p['fine']!),
    }).toList();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final res = await widget.ferieService.richiediFerie(formattedPeriodi, _noteController.text);
      
      // Se c'è un OTP di test/debug (come su web locale) lo mostriamo in un dialog
      if (res['debug_otp'] != null) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('DEBUG OTP'),
            content: Text('Il tuo codice OTP di prova è: ${res['debug_otp']}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context, true); // true = refresh parent
                },
                child: Text('OK'),
              )
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Richiesta inviata. Controlla la tua email per l\'OTP.')),
        );
        Navigator.pop(context, true);
      }

    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nuova Richiesta Ferie'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Seleziona uno o più periodi:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _periodi.length,
                itemBuilder: (context, index) {
                  final p = _periodi[index];
                  final dateFormat = DateFormat('dd/MM/yyyy');
                  return Card(
                    child: ListTile(
                      leading: Icon(Icons.calendar_month, color: Theme.of(context).primaryColor),
                      title: Text('${dateFormat.format(p['inizio']!)} - ${dateFormat.format(p['fine']!)}'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removePeriod(index),
                      ),
                    ),
                  );
                },
              ),
            ),
            OutlinedButton.icon(
              onPressed: _addPeriod,
              icon: Icon(Icons.add),
              label: Text('Aggiungi Periodo'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 24),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Note (Opzionale)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting 
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Invia Richiesta', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
