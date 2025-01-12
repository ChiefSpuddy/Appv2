// ...existing code...

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          AppBar(
            // ...existing code...
            actions: [
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Clear Search',
                onPressed: _clearSearch,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.menu),
                onSelected: (value) async {
                  switch (value) {
                    // ...existing cases...
                    case 'toggle_theme':
                      // Toggle theme logic will be added in ThemeProvider
                      break;
                    case 'logout':
                      // ...existing logout code...
                      break;
                  }
                },
                itemBuilder: (context) => [
                  // ...existing menu items...
                  const PopupMenuItem(
                    value: 'toggle_theme',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.brightness_6),
                      title: Text('Toggle Theme'),
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.logout, color: Colors.red),
                      title: Text('Logout'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // ...rest of the existing code...
