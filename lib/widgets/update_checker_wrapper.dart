import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/api_service.dart';

class UpdateCheckerWrapper extends StatefulWidget {
  final Widget child;
  const UpdateCheckerWrapper({super.key, required this.child});

  @override
  State<UpdateCheckerWrapper> createState() => _UpdateCheckerWrapperState();
}

class _UpdateCheckerWrapperState extends State<UpdateCheckerWrapper> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  int _compareVersion(String v1, String v2) {
    List<int> parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (int i = 0; i < 3; i++) {
      int p1 = parts1.length > i ? parts1[i] : 0;
      int p2 = parts2.length > i ? parts2[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Ignora errori di apertura link
    }
  }

  Future<void> _checkForUpdates() async {
    if (_checked) return;
    _checked = true;

    final apiService = context.read<ApiService>();
    final updateData = await apiService.checkAppUpdate();

    if (updateData == null || updateData['success'] != true) return;

    final latestVersion = updateData['latest_version'] as String? ?? '1.0.0';
    final minVersion = updateData['min_version'] as String? ?? '1.0.0';
    final downloadPageUrl = updateData['download_page_url'] as String? ?? '';
    final playStoreUrl = updateData['play_store_url'] as String? ?? '';
    final appStoreUrl = updateData['app_store_url'] as String? ?? '';

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    final hasUpdate = _compareVersion(currentVersion, latestVersion) < 0;
    final isMandatory = _compareVersion(currentVersion, minVersion) < 0;

    if (!hasUpdate) return;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (BuildContext context) {
        final bool showAndroidPlay = !kIsWeb && Platform.isAndroid && playStoreUrl.isNotEmpty && playStoreUrl != '#';
        // Disabilitiamo il download diretto dell'APK via intent per evitare i blocchi del DownloadManager Android.
        // Reindirizziamo sempre alla pagina web (che apre Chrome) per un'esperienza più stabile.
        final bool showAndroidApk = false;
        final bool showIOSStore = !kIsWeb && Platform.isIOS && appStoreUrl.isNotEmpty && appStoreUrl != '#';
        final bool isIOS = !kIsWeb && Platform.isIOS;

        return PopScope(
          canPop: !isMandatory,
          child: AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(
                  isMandatory ? Icons.warning_amber_rounded : Icons.system_update_rounded,
                  color: const Color(0xFFFF6B35),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isMandatory ? 'Aggiornamento Obbligatorio' : 'Aggiornamento Disponibile',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'È disponibile una nuova versione dell\'app (v$latestVersion). La tua versione attuale è la v$currentVersion.',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Text(
                  isMandatory
                      ? 'Per continuare a utilizzare l\'applicazione è necessario effettuare l\'aggiornamento.'
                      : 'Ti consigliamo di aggiornare l\'applicazione per beneficiare delle ultime funzionalità e correzioni.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.end,
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            actions: [
              if (!isMandatory)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Più tardi',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ),
              


              if (showAndroidPlay)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _launchUrl(playStoreUrl),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Play Store'),
                ),

              if (showIOSStore)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _launchUrl(appStoreUrl),
                  icon: const Icon(Icons.apple_rounded, size: 18),
                  label: const Text('App Store'),
                ),

              // Bottone di fallback se siamo su web o non ci sono URL specifici
              if (kIsWeb || (!isIOS && !showAndroidApk && !showAndroidPlay && !showIOSStore))
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _launchUrl(downloadPageUrl.isNotEmpty ? downloadPageUrl : apiService.baseUrl),
                  icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                  label: const Text('Pagina di Download'),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
