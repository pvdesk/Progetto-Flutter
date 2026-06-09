import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../models/contact_model.dart';
import '../models/room_model.dart';
import 'chat_screen.dart';
import 'group_chat_screen.dart';
import 'profile_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().fetchContacts();
      context.read<ChatProvider>().fetchRooms();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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

    // Filtra contatti
    final filteredContacts = chatProvider.contacts.where((contact) {
      final name = contact.nomeCompleto.toLowerCase();
      final email = contact.email.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();

    // Filtra stanze
    final filteredRooms = chatProvider.rooms.where((room) {
      final name = room.nome.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'Chat',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Private', icon: Icon(Icons.person)),
            Tab(text: 'Punti Servizio', icon: Icon(Icons.group)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              chatProvider.fetchContacts();
              chatProvider.fetchRooms();
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white70),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (currentUser != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: const Color(0xFF1E293B),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
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

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cerca...',
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
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: PRIVATE
                _buildPrivateTab(chatProvider, filteredContacts),
                // TAB 2: PUBBLICHE (STANZE)
                _buildRoomsTab(chatProvider, filteredRooms),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivateTab(ChatProvider chatProvider, List<ContactModel> filteredContacts) {
    if (chatProvider.isLoadingContacts) {
      return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
    }
    if (chatProvider.errorMessage != null) {
      return Center(
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
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                onPressed: () => chatProvider.fetchContacts(),
                child: const Text('Riprova', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }
    if (filteredContacts.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty ? 'Nessun contatto disponibile.' : 'Nessun contatto corrisponde alla ricerca.',
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 15),
        ),
      );
    }
    return RefreshIndicator(
      color: Theme.of(context).primaryColor,
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
    );
  }

  Widget _buildRoomsTab(ChatProvider chatProvider, List<RoomModel> filteredRooms) {
    if (chatProvider.isLoadingRooms) {
      return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
    }
    if (chatProvider.errorMessage != null && chatProvider.rooms.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                'Impossibile caricare le stanze',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                onPressed: () => chatProvider.fetchRooms(),
                child: const Text('Riprova', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }
    if (filteredRooms.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty ? 'Nessun punto servizio disponibile.' : 'Nessuna stanza corrisponde.',
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 15),
        ),
      );
    }
    return RefreshIndicator(
      color: Theme.of(context).primaryColor,
      onRefresh: () => chatProvider.fetchRooms(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredRooms.length,
        separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.04)),
        itemBuilder: (context, index) {
          final RoomModel room = filteredRooms[index];

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupChatScreen(room: room),
                ),
              ).then((_) {
                chatProvider.fetchRooms();
              });
            },
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF0075A2),
              radius: 22,
              child: const Icon(Icons.group, color: Colors.white, size: 20),
            ),
            title: Text(
              room.nome,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: room.indirizzo != null
              ? Text(
                  room.indirizzo!,
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
            trailing: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white24,
              size: 14,
            ),
          );
        },
      ),
    );
  }
}
