import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../widgets/avatar_picker_dialog.dart';
import '../screens/auth_screen.dart';  // Add this import

class ProfileScreen extends StatefulWidget {  // Change to StatefulWidget
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static final AuthService _authService = AuthService();
  bool _showEmail = false;
  String? _currentAvatar;  // Add this to cache avatar path
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final avatar = await _authService.getAvatarPath();
    final username = await _authService.getUsername();
    if (mounted) {
      setState(() {
        _currentAvatar = avatar;
        _username = username;
      });
    }
  }

  Future<void> _updateUsername(BuildContext context) async {
    String? newUsername = await showDialog<String>(
      context: context,
      builder: (context) => const UsernameDialog(),
    );

    if (newUsername != null && newUsername.isNotEmpty && context.mounted) {
      final success = await _authService.updateUsername(newUsername);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Username updated successfully' : 'Username is already taken',
            ),
          ),
        );
      }
    }
  }

  Future<void> _updateAvatar(BuildContext context) async {
    final String? selectedAvatarId = await showDialog<String>(
      context: context,
      builder: (context) => const AvatarPickerDialog(),
    );

    if (selectedAvatarId != null && mounted) {
      final success = await _authService.updateAvatar(selectedAvatarId);
      if (mounted) {
        if (success) {
          // Immediately update the avatar path
          final newAvatarPath = 'assets/avatars/avatar$selectedAvatarId.png';
          setState(() => _currentAvatar = newAvatarPath);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Avatar updated' : 'Failed to update avatar',
            ),
          ),
        );
      }
    }
  }

  Widget _buildProfileCard(BuildContext context, User user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Column(
              children: [
                // Avatar Section with Edit Button
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () => _updateAvatar(context),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? Colors.grey[800] : Colors.white,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _currentAvatar != null
                              ? Image.asset(
                                  _currentAvatar!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    Icons.person,
                                    size: 50,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 50,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _updateAvatar(context),
                          customBorder: const CircleBorder(),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.edit,
                              size: 20,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Username Section
                Column(
                  children: [
                    Text(
                      _username ?? 'Set username',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: () => _updateUsername(context),
                      icon: const Icon(Icons.edit, color: Colors.white70, size: 16),
                      label: const Text(
                        'Edit Username',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Email Display with Toggle
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.email, color: isDark ? Colors.white : Theme.of(context).primaryColor),
                  title: const Text('Email'),
                  subtitle: _showEmail ? Text(user.email ?? 'No email') : const Text('Hidden'),
                  trailing: IconButton(
                    icon: Icon(_showEmail ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _showEmail = !_showEmail),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_circle,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sign in to view your profile',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AuthScreen(),
                        ),
                      );
                    },
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ),
          );
        }

        // User is signed in, show profile content
        final user = snapshot.data!;
        final themeProvider = Provider.of<ThemeProvider>(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            elevation: 0,
          ),
          body: ListView(
            children: [
              _buildProfileCard(context, user),
              const SizedBox(height: 8),
              
              // Settings Section
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.palette),
                      title: const Text('Theme'),
                      subtitle: Text(themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode'),
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (value) => themeProvider.toggleTheme(),
                      ),
                    ),
                  ],
                ),
              ),

              // Account Section
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'ACCOUNT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.password),
                      title: const Text('Change Password'),
                      onTap: () {
                        // TODO: Implement password change
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Coming soon')),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.logout,
                        color: isDark ? Colors.red[300] : Colors.red,
                      ),
                      title: Text(
                        'Sign Out',
                        style: TextStyle(
                          color: isDark ? Colors.red[300] : Colors.red,
                        ),
                      ),
                      onTap: () async {
                        await _authService.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushReplacementNamed('/');
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Danger Zone
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'DANGER ZONE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text(
                        'Delete Account',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Account'),
                            content: const Text(
                              'Are you sure you want to delete your account? This action cannot be undone.'
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('CANCEL'),
                              ),
                              TextButton(
                                onPressed: () {
                                  // TODO: Implement account deletion
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Coming soon')),
                                  );
                                },
                                child: const Text(
                                  'DELETE',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Credits Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Powered by TCGPlayer, PokeAPI, and TCGAPI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class UsernameDialog extends StatefulWidget {
  const UsernameDialog({super.key});

  @override
  State<UsernameDialog> createState() => _UsernameDialogState();
}

class _UsernameDialogState extends State<UsernameDialog> {
  final _controller = TextEditingController();
  String? _error;

  Future<void> _validateUsername(String value) async {
    if (value.length < 3) {
      setState(() => _error = 'Username must be at least 3 characters');
      return;
    }
    if (value.length > 20) {
      setState(() => _error = 'Username must be less than 20 characters');
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      setState(() => _error = 'Only letters, numbers, and underscores allowed');
      return;
    }

    final isAvailable = await AuthService().isUsernameAvailable(value);
    if (!isAvailable) {
      setState(() => _error = 'Username is already taken');
      return;
    }

    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Username'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Enter username',
              errorText: _error,
            ),
            onChanged: _validateUsername,
          ),
          const SizedBox(height: 8),
          const Text(
            'Username must be 3-20 characters long and can only contain letters, numbers, and underscores.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: _error == null && _controller.text.isNotEmpty
              ? () => Navigator.pop(context, _controller.text)
              : null,
          child: const Text('SAVE'),
        ),
      ],
    );
  }
}
