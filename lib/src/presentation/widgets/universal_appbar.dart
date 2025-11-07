import 'package:flutter/material.dart';

class UniversalAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onHomeTap;
  final VoidCallback onNotificationsTap;

  const UniversalAppBar({
    super.key,
    required this.onHomeTap,
    required this.onNotificationsTap,
  });

  @override
  State<UniversalAppBar> createState() => _UniversalAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _UniversalAppBarState extends State<UniversalAppBar> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  void _submitSearch(BuildContext context) {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    Navigator.pushNamed(context, '/search', arguments: query);
    _searchController.clear();
    setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black87,
      titleSpacing: 0,
      title: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40,
        margin: const EdgeInsets.only(left: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            const Icon(Icons.search, color: Colors.white70, size: 22),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.deepPurpleAccent,
                decoration: const InputDecoration(
                  hintText: 'Buscar jogos...',
                  hintStyle: TextStyle(color: Colors.white60),
                  border: InputBorder.none,
                ),
                onTap: () => setState(() => _isSearching = true),
                onSubmitted: (_) => _submitSearch(context),
              ),
            ),
            if (_isSearching && _searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                tooltip: 'Limpar',
                onPressed: () {
                  _searchController.clear();
                  setState(() => _isSearching = false);
                },
              ),
            IconButton(
              icon: const Icon(Icons.arrow_forward, color: Colors.deepPurpleAccent),
              tooltip: 'Buscar',
              onPressed: () => _submitSearch(context),
            ),
          ],
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          color: const Color(0xFF1E1E1E),
          onSelected: (String result) {
            if (result == 'home') {
              widget.onHomeTap();
            } else if (result == 'notifications') {
              widget.onNotificationsTap();
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'home',
              child: ListTile(
                leading: Icon(Icons.home, color: Colors.white),
                title: Text('Home', style: TextStyle(color: Colors.white)),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'notifications',
              child: ListTile(
                leading: Icon(Icons.notifications, color: Colors.white),
                title: Text('Notificações/Amigos',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
