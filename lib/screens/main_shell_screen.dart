import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/document_provider.dart';
import 'contacts_screen.dart';
import 'documents_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ContactsScreen(),
    DocumentsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Eseguiamo il fetch iniziale dei contatori
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().fetchUnreadCount();
      context.read<DocumentProvider>().fetchDocuments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final documentProvider = context.watch<DocumentProvider>();

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.06),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            // Quando passiamo a una pagina, rinfreschiamo i dati correlati
            if (index == 0) {
              context.read<ChatProvider>().fetchContacts();
              context.read<ChatProvider>().fetchUnreadCount();
            } else if (index == 1) {
              context.read<DocumentProvider>().fetchDocuments();
            }
          },
          backgroundColor: const Color(0xFF1E293B),
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.white.withOpacity(0.4),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          items: [
            // Voce Chat
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Badge(
                  isLabelVisible: chatProvider.unreadCount > 0,
                  label: Text(
                    chatProvider.unreadCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.redAccent,
                  child: const Icon(Icons.chat_bubble_rounded),
                ),
              ),
              label: 'Chat',
            ),
            
            // Voce Documenti
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Badge(
                  isLabelVisible: documentProvider.unreadDocumentsCount > 0,
                  label: Text(
                    documentProvider.unreadDocumentsCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.redAccent,
                  child: const Icon(Icons.folder_shared_rounded),
                ),
              ),
              label: 'Documenti',
            ),
          ],
        ),
      ),
    );
  }
}
