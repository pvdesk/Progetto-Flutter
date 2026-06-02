import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../models/contact_model.dart';
import 'chat_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().fetchContacts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'superadmin':
        return Colors.redAccent;
      case 'responsabile_regione':
        return Colors.amberAccent;
      case 'responsabile_area':
        return Colors.orangeAccent;
      case 'responsabile_commessa':
        return Colors.lightBlueAccent;
      case 'responsabile':
        return Colors.tealAccent;
      default:
        return Colors.greenAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final currentUser = authProvider.currentUser;

    // Filtra la lista dei contatti in base alla ricerca inserita dall'utente
    final filteredContacts = chatProvider.contacts.where((contact) {
      final name = contact.nomeCompleto.toLowerCase();
      final email = contact.email.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'Rubrica Chat',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => chatProvider.fetchContacts(),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1E293B),
                  title: const Text('Disconnessione', style: TextStyle(color: Colors.white)),
                  content: const Text('Sei sicuro di voler uscire dall\'applicazione?', style: TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annulla', style: TextStyle(color: Color(0xFFFF8C61))),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: () {
                        Navigator.pop(context);
                        authProvider.logout();
                      },
                      child: const Text('Esci', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header info utente loggato (Sleek card)
          if (currentUser != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: const Color(0xFF1E293B),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFFF6B35),
                    radius: 24,
                    child: Text(
                      currentUser.nome.isNotEmpty ? currentUser.nome[0].toUpperCase() : 'U',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser.nomeCompleto,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentUser.ruoloEtichetta,
                          style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Campo di Ricerca Contatti
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cerca contatti...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFF8C61)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFFF6B35)),
                ),
              ),
            ),
          ),

          // Lista dei Contatti
          Expanded(
            child: chatProvider.isLoadingContacts
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
                : chatProvider.errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                chatProvider.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35)),
                                onPressed: () => chatProvider.fetchContacts(),
                                child: const Text('Riprova', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filteredContacts.isEmpty
                        ? Center(
                            child: Text(
                              _searchQuery.isEmpty ? 'Nessun contatto disponibile.' : 'Nessun contatto corrisponde alla ricerca.',
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 15),
                            ),
                          )
                        : RefreshIndicator(
                            color: const Color(0xFFFF6B35),
                            onRefresh: () => chatProvider.fetchContacts(),
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filteredContacts.length,
                              separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.04)),
                              itemBuilder: (context, index) {
                                final ContactModel contact = filteredContacts[index];
                                final roleColor = _getRoleColor(contact.ruolo);

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(contact: contact),
                                      ),
                                    ).then((_) {
                                      // Al rientro, rinfresca la rubrica per i messaggi letti
                                      chatProvider.fetchContacts();
                                    });
                                  },
                                  leading: Badge(
                                    isLabelVisible: contact.unreadCount > 0,
                                    label: Text(
                                      contact.unreadCount.toString(),
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                    backgroundColor: Colors.redAccent,
                                    offset: const Offset(4, -4),
                                    child: CircleAvatar(
                                      backgroundColor: const Color(0xFF004E89),
                                      radius: 22,
                                      child: Text(
                                        contact.nome.isNotEmpty ? contact.nome[0].toUpperCase() : 'C',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    contact.nomeCompleto,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: roleColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: roleColor.withOpacity(0.3), width: 0.5),
                                          ),
                                          child: Text(
                                            contact.ruoloEtichetta,
                                            style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Colors.white24,
                                    size: 14,
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
