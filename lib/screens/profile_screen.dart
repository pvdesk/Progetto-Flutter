import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../providers/auth_provider.dart';
import '../utils/web_utils.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().fetchPrivacyInfo();
    });
  }

  String _parseHtmlToText(String html) {
    String text = html;
    
    // Convert headers & paragraphs
    text = text.replaceAll(RegExp(r'</?(h1|h2|h3)>'), '\n\n');
    text = text.replaceAll(RegExp(r'</?p>'), '\n');
    text = text.replaceAll(RegExp(r'</?strong>'), '');
    text = text.replaceAll(RegExp(r'<br\s*/?>'), '\n');
    text = text.replaceAll(RegExp(r'<li>'), '• ');
    text = text.replaceAll(RegExp(r'</li>'), '\n');
    text = text.replaceAll(RegExp(r'</?ul>'), '\n');
    
    // Strip other HTML tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Decode HTML entities
    text = text.replaceAll('&agrave;', 'à');
    text = text.replaceAll('&eacute;', 'é');
    text = text.replaceAll('&egrave;', 'è');
    text = text.replaceAll('&igrave;', 'ì');
    text = text.replaceAll('&ograve;', 'ò');
    text = text.replaceAll('&ugrave;', 'ù');
    text = text.replaceAll('&apos;', "'");
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&nbsp;', ' ');
    
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }

  void _showPrivacyInfoDialog(BuildContext context, AuthProvider authProvider) {
    final textToDisplay = authProvider.privacyText != null
        ? _parseHtmlToText(authProvider.privacyText!)
        : 'Caricamento informativa...';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Informativa sulla Privacy',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.5,
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                child: Text(
                  textToDisplay,
                  style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Chiudi', style: TextStyle(color: Color(0xFFFF8C61))),
            ),
          ],
        );
      },
    );
  }

  void _downloadSignedPrivacy(BuildContext context, AuthProvider authProvider) async {
    final docId = authProvider.privacyDocId;
    if (docId == null) return;

    final apiService = authProvider.apiService;
    final downloadUrl = '${apiService.baseUrl}api/mobile/documenti/$docId/download';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Scaricamento in corso del documento firmato...'),
        backgroundColor: Theme.of(context).primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      if (kIsWeb) {
        openUrlInNewTab(downloadUrl);
      } else {
        final response = await apiService.dio.get(
          'api/mobile/documenti/$docId/download',
          options: Options(responseType: ResponseType.bytes),
        );

        if (!context.mounted) return;

        if (response.statusCode == 200) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: const Text('Download Completato', style: TextStyle(color: Colors.white)),
              content: const Text(
                'Il file del consenso privacy firmato è stato scaricato con successo nella memoria interna.',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossibile scaricare il file. Riprova.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'Profilo',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.account_circle_rounded,
                    size: 100,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${user.nome} ${user.cognome}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.email,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Sezione Privacy e Consensi
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Privacy e GDPR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.description_outlined, color: Color(0xFFFF8C61)),
                          title: const Text('Informativa sulla Privacy', style: TextStyle(color: Colors.white, fontSize: 14)),
                          subtitle: const Text('Leggi l\'informativa sul trattamento dati', style: TextStyle(color: Colors.white54, fontSize: 11)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white30),
                          onTap: () => _showPrivacyInfoDialog(context, authProvider),
                        ),
                        if (authProvider.privacyDocId != null) ...[
                          const Divider(color: Colors.white12, height: 16),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.assignment_turned_in_outlined, color: Colors.tealAccent),
                            title: const Text('Privacy Firmata (PDF)', style: TextStyle(color: Colors.white, fontSize: 14)),
                            subtitle: const Text('Scarica copia dell\'informativa firmata', style: TextStyle(color: Colors.white54, fontSize: 11)),
                            trailing: const Icon(Icons.download_rounded, color: Colors.white30),
                            onTap: () => _downloadSignedPrivacy(context, authProvider),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  // Bottone di Logout
                  OutlinedButton.icon(
                    onPressed: () async {
                      await authProvider.logout();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    label: const Text(
                      'Esci dall\'App',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Bottone di Eliminazione Account
                  ElevatedButton.icon(
                    onPressed: () => _confirmDelete(context, authProvider),
                    icon: const Icon(Icons.delete_forever_rounded, color: Colors.white),
                    label: const Text(
                      'Elimina Account',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _confirmDelete(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Conferma Eliminazione',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Sei sicuro di voler eliminare il tuo account dell\'App Chat? Questa azione disabiliterà il tuo accesso all\'app e cancellerà le tue chat.\n\nIl tuo profilo dipendente e le tue presenze rimarranno comunque intatti nel gestionale centrale.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );

                final success = await authProvider.deleteAccount();

                if (context.mounted) {
                  Navigator.of(context).pop(); // Chiudi loading
                  
                  if (success) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(authProvider.errorMessage ?? 'Errore durante l\'eliminazione.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Elimina', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
