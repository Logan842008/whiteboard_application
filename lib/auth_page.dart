import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dashboard_page.dart';

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();

  bool _isSignIn = true; // Toggle between Sign In and Register

  // Handle Email/Password Authentication
  void _handleAuth(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final displayName =
        _displayNameController.text.trim(); // New display name field

    try {
      if (_isSignIn) {
        // Sign In Flow
        final authResponse =
            await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (authResponse.user != null) {
          _navigateToDashboard(context);
        } else {
          _showError(context, "Sign-In failed. Check your credentials.");
        }
      } else {
        // Registration Flow with Display Name
        final authResponse = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
          data: {'display_name': displayName}, // Add metadata
        );

        if (authResponse.user != null) {
          // Update user profile display name
          await Supabase.instance.client.auth.updateUser(UserAttributes(
            data: {'display_name': displayName},
          ));
          _navigateToDashboard(context);
        } else {
          _showError(context, "Registration failed. Try again.");
        }
      }
    } catch (e) {
      _showError(context, e.toString());
    }
  }

  void _navigateToDashboard(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => DashboardPage()),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo or Illustration
                Icon(Icons.draw_outlined, size: 100, color: Colors.blue),
                SizedBox(height: 20),
                Text(
                  _isSignIn ? "Welcome Back!" : "Create an Account",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                SizedBox(height: 10),
                Text(
                  _isSignIn ? "Sign in to continue" : "Register to get started",
                  style: TextStyle(color: Colors.grey[700]),
                ),
                SizedBox(height: 30),

                // Form with email and password
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        if (!_isSignIn)
                          TextField(
                            controller: _displayNameController,
                            decoration: InputDecoration(
                              labelText: "Display Name",
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        SizedBox(height: 15),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: "Email",
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        SizedBox(height: 15),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => _handleAuth(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            minimumSize: Size(double.infinity, 50),
                          ),
                          child: Text(
                            _isSignIn ? "Sign In" : "Register",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Google Sign-In Button
                SizedBox(height: 20),

                // Toggle between Sign In and Register
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSignIn = !_isSignIn;
                    });
                  },
                  child: Text(
                    _isSignIn
                        ? "Don't have an account? Register"
                        : "Already have an account? Sign In",
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
