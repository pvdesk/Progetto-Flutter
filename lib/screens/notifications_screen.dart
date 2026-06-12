import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../providers/config_provider.dart';
import '../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchUnread();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showComunicazioneDetail(BuildContext context, ComunicazioneModel comunicazione) {
    final provider = context.read<NotificationProvider>();
    provider.markComunicazioneAsRead(comunicazione.id);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(comunicazione.titolo, style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Da: ${comunicazione.creatoDa ?? 'Sistema'} - ${comunicazione.pubblicataAt ?? ''}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Text(
                comunicazione.testo,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final configProvider = context.watch<ConfigProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: configProvider.internalLogoUrl != null
            ? Image.network(
                configProvider.internalLogoUrl!,
                height: 36,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/icon/logo_orizzontale.png',
                  height: 36,
                  fit: BoxFit.contain,
                ),
              )
            : Image.asset(
                'assets/icon/logo_orizzontale.png',
                height: 36,
                fit: BoxFit.contain,
              ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => notificationProvider.fetchUnread(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF8C61),
          unselectedLabelColor: Colors.white70,
          indicatorColor: Theme.of(context).primaryColor,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.campaign_outlined, size: 18),
                  const SizedBox(width: 8),
                  const Text('Bacheca'),
                  if (notificationProvider.comunicazioni.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Badge(
                      label: Text(notificationProvider.comunicazioni.length.toString()),
                      backgroundColor: Colors.redAccent,
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_note_outlined, size: 18),
                  const SizedBox(width: 8),
                  const Text('Scadenze'),
                  if (notificationProvider.notifiche.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Badge(
                      label: Text(notificationProvider.notifiche.length.toString()),
                      backgroundColor: Colors.redAccent,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildComunicazioniList(context, notificationProvider),
          _buildNotificheList(context, notificationProvider),
        ],
      ),
    );
  }

  Widget _buildComunicazioniList(BuildContext context, NotificationProvider provider) {
    if (provider.isLoading && provider.comunicazioni.isEmpty) {
      return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
    }

    if (provider.comunicazioni.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.campaign_outlined, color: Colors.white.withOpacity(0.15), size: 80),
              const SizedBox(height: 16),
              Text(
                'Nessuna comunicazione da leggere.',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: Theme.of(context).primaryColor,
      onRefresh: () => provider.fetchUnread(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: provider.comunicazioni.length,
        itemBuilder: (context, index) {
          final c = provider.comunicazioni[index];
          return Card(
            color: const Color(0xFF1E293B),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.4), width: 1.5),
            ),
            elevation: 4,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showComunicazioneDetail(context, c),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.withOpacity(0.4), width: 0.8),
                          ),
                          child: const Text(
                            'Nuovo',
                            style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          c.pubblicataAt ?? '',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      c.titolo,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c.testo,
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificheList(BuildContext context, NotificationProvider provider) {
    if (provider.isLoading && provider.notifiche.isEmpty) {
      return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
    }

    if (provider.notifiche.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_available, color: Colors.white.withOpacity(0.15), size: 80),
              const SizedBox(height: 16),
              Text(
                'Nessuna scadenza imminente.',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: Theme.of(context).primaryColor,
      onRefresh: () => provider.fetchUnread(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: provider.notifiche.length,
        itemBuilder: (context, index) {
          final n = provider.notifiche[index];
          return Card(
            color: const Color(0xFF1E293B),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.redAccent.withOpacity(0.4), width: 1.5),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.4), width: 0.8),
                        ),
                        child: const Text(
                          'Scadenza',
                          style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        n.createdAt ?? '',
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    n.testo,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        n.scadeIl != null ? 'Entro il: ${n.scadeIl}' : '',
                        style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => provider.markNotificaAsRead(n.id),
                        icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.greenAccent),
                        label: const Text('Segna come letta', style: TextStyle(fontSize: 12, color: Colors.greenAccent)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.greenAccent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
