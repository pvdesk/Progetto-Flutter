import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.isLoading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF020617)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),
                // Icon & Title
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(
                      Icons.gavel_rounded,
                      size: 40,
                      color: Color(0xFFFF8C61),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Termini di Privacy',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'È richiesta l\'accettazione per accedere alla chat.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Scroller del testo della Privacy (Design Glassmorphic)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(right: 12),
                        child: Text(
                          'Informativa sul Trattamento dei Dati Personali (GDPR)\n\n'
                          '1. Titolare del Trattamento\n'
                          'Il titolare del trattamento dei dati è l\'azienda che gestisce questa istanza di app_gestione.\n\n'
                          '2. Tipologia di dati raccolti\n'
                          'Attraverso la funzionalità di Chat, vengono raccolti e archiviati i messaggi scambiati tra te e i referenti autorizzati, comprese le informazioni su mittente, destinatario, orari di invio/ricezione e stato di lettura.\n\n'
                          '3. Finalità del trattamento\n'
                          'I dati sono trattati esclusivamente per agevolare il coordinamento lavorativo interno, la gestione dei turni, l\'assegnazione delle commesse ed esigenze organizzative aziendali.\n\n'
                          '4. Conservazione dei dati\n'
                          'I messaggi rimarranno memorizzati sui server aziendali in conformità con le policy di conservazione interne e saranno accessibili solo al personale appositamente autorizzato.\n\n'
                          '5. Diritti dell\'interessato\n'
                          'In conformità con il Regolamento UE 2016/679 (GDPR), hai il diritto in qualsiasi momento di richiedere l\'accesso ai tuoi dati, la rettifica, la cancellazione o la limitazione del trattamento rivolgendoti all\'amministrazione.\n\n'
                          'Accettando i presenti termini, acconsenti espressamente al trattamento dei dati relativi all\'utilizzo della chat aziendale.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Pulsanti
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final success = await authProvider.acceptPrivacy();
                          if (!success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(authProvider.errorMessage ?? 'Errore durante l\'accettazione'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'ACCETTA E PROCEDI',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1),
                        ),
                ),
                const SizedBox(height: 12),
                
                OutlinedButton(
                  onPressed: isLoading ? null : () => authProvider.logout(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Annulla e Disconnetti'),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
