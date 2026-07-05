import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ddt_provider.dart';
import 'ddt_detail_screen.dart';

class DdtListScreen extends StatefulWidget {
  const DdtListScreen({super.key});

  @override
  State<DdtListScreen> createState() => _DdtListScreenState();
}

class _DdtListScreenState extends State<DdtListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DdtProvider>().fetchAssignedDdt();
    });
  }

  Future<void> _refresh() async {
    await context.read<DdtProvider>().fetchAssignedDdt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DDT / Trasporti'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: Consumer<DdtProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.ddts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.ddts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  provider.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (provider.ddts.isEmpty) {
            return const Center(
              child: Text('Nessun DDT assegnato al momento.'),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  padding: EdgeInsets.only(
                    top: 8,
                    left: 8,
                    right: 8,
                    bottom: MediaQuery.of(context).padding.bottom + 80, // Prevent overlapping with bottom bar or android commands
                  ),
                  itemCount: provider.ddts.length,
                  itemBuilder: (context, index) {
                    final ddt = provider.ddts[index];
                    
                    Color statoColor = Colors.grey;
                    if (ddt.stato == 'in_transito') statoColor = Colors.orange;
                    if (ddt.stato == 'consegnato') statoColor = Colors.green;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        title: Text(
                          '${ddt.numero} - ${ddt.destinatario ?? ""}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Data: ${ddt.data ?? "-"}'),
                            if (ddt.indirizzo != null) Text('Indirizzo: ${ddt.indirizzo}'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statoColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    ddt.stato.toUpperCase().replaceAll('_', ' '),
                                    style: TextStyle(
                                      color: statoColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (ddt.colli != null && ddt.colli! > 0)
                                  Text('Colli: ${ddt.colli}  ', style: const TextStyle(fontSize: 12)),
                                if (ddt.pesoKg != null && ddt.pesoKg! > 0)
                                  Text('Peso: ${ddt.pesoKg}kg', style: const TextStyle(fontSize: 12)),
                              ],
                            )
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DdtDetailScreen(ddtId: ddt.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
