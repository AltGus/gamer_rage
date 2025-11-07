import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gamer_rage/src/presentation/pages/home_page.dart';
import 'package:gamer_rage/src/presentation/pages/notifications_page.dart';
import 'package:gamer_rage/src/presentation/widgets/universal_appbar.dart';

/// 🧭 AppShell — estrutura principal do app autenticado.
/// Contém a [UniversalAppBar] com busca global e navegação entre páginas.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      HomePage(),
      NotificationsPage(),
    ];
  }

  /// Alterna entre páginas principais
  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  /// Faz logout e volta para a tela de login
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      /// 🔹 Barra superior universal — com busca e botões rápidos
      appBar: UniversalAppBar(
        onHomeTap: () => _onItemTapped(0),
        onNotificationsTap: () => _onItemTapped(1),
      ),

      /// 🔹 Corpo — alterna entre as páginas
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: _pages[_selectedIndex],
      ),

      /// 🔹 Barra inferior simples
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF1A1A1A),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home, color: Colors.white),
              tooltip: 'Página Inicial',
              onPressed: () => _onItemTapped(0),
            ),
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              tooltip: 'Notificações',
              onPressed: () => _onItemTapped(1),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              tooltip: 'Sair',
              onPressed: _logout,
            ),
          ],
        ),
      ),
    );
  }
}
