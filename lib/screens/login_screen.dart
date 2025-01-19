class LoginScreen extends StatelessWidget {
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ...existing code...
          
          
          // Add Apple Sign In button
          if (Platform.isIOS) // Only show on iOS
            SignInWithAppleButton(
              onPressed: () async {
                final result = await _auth.signInWithApple();
                if (result != null) {
                  // Navigate to home or handle success
                }
              },
            ),
            
          // ...existing code...
        ],
      ),
    );
  }
}
