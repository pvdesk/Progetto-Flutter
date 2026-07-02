import 'package:flutter/material.dart';
import 'automezzi_screen.dart';
import 'attrezzature_screen.dart';

class ManutenzioniHubScreen extends StatefulWidget {
  const ManutenzioniHubScreen({super.key});

  @override
  State<ManutenzioniHubScreen> createState() => _ManutenzioniHubScreenState();
}

class _ManutenzioniHubScreenState extends State<ManutenzioniHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'Centro Manutenzioni',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E293B),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Automezzi', icon: Icon(Icons.local_shipping_rounded)),
            Tab(text: 'Attrezzature', icon: Icon(Icons.build_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AutomezziScreen(showAppBar: false),
          AttrezzatureScreen(showAppBar: false),
        ],
      ),
    );
  }
}
