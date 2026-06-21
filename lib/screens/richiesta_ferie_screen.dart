import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/ferie_service.dart';

class RichiestaFerieScreen extends StatefulWidget {
  final FerieService ferieService;

  const RichiestaFerieScreen({super.key, required this.ferieService});

  @override
  State<RichiestaFerieScreen> createState() => _RichiestaFerieScreenState();
}

class _RichiestaFerieScreenState extends State<RichiestaFerieScreen> {
  static const _arancione = Color(0xFFFF8C42);

  final List<Map<String, DateTime>> _periodi = [];
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  late DateTime _meseVisualizzato;
  DateTime? _start;
  DateTime? _end;

  static const _mesiIt = [
    'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
    'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
  ];
  static const _giorniIt = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _meseVisualizzato = DateTime(now.year, now.month, 1);
  }

  DateTime get _oggi {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime get _ultimoGiornoSelezionabile => _oggi.add(const Duration(days: 365 * 2));

  void _cambiaMese(int delta) {
    setState(() {
      _meseVisualizzato = DateTime(_meseVisualizzato.year, _meseVisualizzato.month + delta, 1);
    });
  }

  bool _selezionabile(DateTime g) =>
      !g.isBefore(_oggi) && !g.isAfter(_ultimoGiornoSelezionabile);

  void _tapGiorno(DateTime g) {
    if (!_selezionabile(g)) return;
    setState(() {
      if (_start == null || (_start != null && _end != null)) {
        _start = g;
        _end = null;
      } else if (g.isBefore(_start!)) {
        _start = g;
      } else {
        _end = g;
      }
    });
  }

  bool _inRange(DateTime g) {
    if (_start == null) return false;
    final s = _start!;
    final e = _end ?? _start!;
    return !g.isBefore(s) && !g.isAfter(e);
  }

  bool _isEstremo(DateTime g) =>
      (_start != null && _isSameDay(g, _start!)) || (_end != null && _isSameDay(g, _end!));

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _aggiungiPeriodoCorrente() {
    if (_start == null) return;
    final s = _start!;
    final e = _end ?? _start!;
    setState(() {
      _periodi.add({'inizio': s, 'fine': e});
      _start = null;
      _end = null;
    });
  }

  void _removePeriod(int index) => setState(() => _periodi.removeAt(index));

  void _submit() async {
    if (_periodi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aggiungi almeno un periodo di ferie.')),
      );
      return;
    }

    final format = DateFormat('yyyy-MM-dd');
    final formattedPeriodi = _periodi
        .map((p) => {'inizio': format.format(p['inizio']!), 'fine': format.format(p['fine']!)})
        .toList();

    setState(() => _isSubmitting = true);

    try {
      final res = await widget.ferieService.richiediFerie(formattedPeriodi, _noteController.text);
      if (!mounted) return;
      if (res['debug_otp'] != null) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Codice OTP (debug)'),
            content: Text('Il tuo codice OTP di prova è: ${res['debug_otp']}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context, true);
                },
                child: const Text('OK'),
              )
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Richiesta inviata. Controlla la tua email per l\'OTP.')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuova Richiesta Ferie')),
      body: SafeArea(
        bottom: true,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _calendario(),
            const SizedBox(height: 12),
            _barraSelezione(),
            const SizedBox(height: 16),
            if (_periodi.isNotEmpty) ...[
              const Text('Periodi aggiunti', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              ..._periodi.asMap().entries.map((entry) {
                final p = entry.value;
                final df = DateFormat('dd/MM/yyyy');
                final giorni = p['fine']!.difference(p['inizio']!).inDays + 1;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.event_available, color: _arancione),
                    title: Text('${df.format(p['inizio']!)} → ${df.format(p['fine']!)}'),
                    subtitle: Text('$giorni giorn${giorni == 1 ? 'o' : 'i'}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _removePeriod(entry.key),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note (opzionale)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: (_isSubmitting || _periodi.isEmpty) ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(_isSubmitting ? 'Invio...' : 'Invia richiesta', style: const TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _arancione,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _barraSelezione() {
    final df = DateFormat('dd/MM/yyyy');
    String testo;
    if (_start == null) {
      testo = 'Tocca un giorno per iniziare, poi un altro per la fine.';
    } else if (_end == null) {
      testo = 'Inizio: ${df.format(_start!)} — tocca il giorno di fine.';
    } else {
      testo = 'Periodo: ${df.format(_start!)} → ${df.format(_end!)}';
    }
    return Row(
      children: [
        Expanded(child: Text(testo, style: const TextStyle(fontWeight: FontWeight.w500))),
        ElevatedButton.icon(
          onPressed: _start == null ? null : _aggiungiPeriodoCorrente,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Aggiungi'),
          style: ElevatedButton.styleFrom(backgroundColor: _arancione, foregroundColor: Colors.white),
        ),
      ],
    );
  }

  Widget _calendario() {
    final primo = DateTime(_meseVisualizzato.year, _meseVisualizzato.month, 1);
    final giorniNelMese = DateTime(_meseVisualizzato.year, _meseVisualizzato.month + 1, 0).day;
    final offset = (primo.weekday - 1) % 7; // lun=0

    final celle = <Widget>[];
    for (int i = 0; i < offset; i++) {
      celle.add(const SizedBox());
    }
    for (int d = 1; d <= giorniNelMese; d++) {
      final g = DateTime(_meseVisualizzato.year, _meseVisualizzato.month, d);
      final selezionabile = _selezionabile(g);
      final estremo = _isEstremo(g);
      final inRange = _inRange(g);

      Color? bg;
      Color fg = Colors.white;
      if (estremo) {
        bg = _arancione;
      } else if (inRange) {
        bg = _arancione.withValues(alpha: 0.25);
        fg = Colors.white;
      } else if (!selezionabile) {
        fg = Colors.white24;
      } else {
        fg = Colors.white;
      }

      celle.add(GestureDetector(
        onTap: selezionabile ? () => _tapGiorno(g) : null,
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text('$d', style: TextStyle(color: fg, fontWeight: estremo ? FontWeight.bold : FontWeight.normal)),
        ),
      ));
    }

    return Card(
      color: const Color(0xFF1E293B),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: () => _cambiaMese(-1), icon: const Icon(Icons.chevron_left, color: Colors.white)),
                Text('${_mesiIt[_meseVisualizzato.month - 1]} ${_meseVisualizzato.year}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(onPressed: () => _cambiaMese(1), icon: const Icon(Icons.chevron_right, color: Colors.white)),
              ],
            ),
            Row(
              children: _giorniIt
                  .map((g) => Expanded(
                        child: Center(child: Text(g, style: const TextStyle(color: Colors.white54, fontSize: 12))),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 4),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1,
              children: celle,
            ),
          ],
        ),
      ),
    );
  }
}
