import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'signup_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login successful!")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Invalid credentials")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {

    setState(() => _loading = true);
    try {
      if (kIsWeb) {
        // WEB: Firebase popup login
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');

        final userCredential =
        await FirebaseAuth.instance.signInWithPopup(googleProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Google sign-in successful!")),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
      else{
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();

      if (googleUser == null) {
        // User canceled the sign-in
        if (mounted) {
          setState(() => _loading = false);
        }
        return;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);

      // Once signed in, return the UserCredential
      await _auth.signInWithCredential(credential);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Google sign-in successful!")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google sign-in failed: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1BA57B),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock, size: 64, color: Color(0xFF1BA57B)),
                const SizedBox(height: 24),
                const Text(
                  "Welcome Back!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1BA57B),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Log in to continue",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: "Email",
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: const Color(0xFFF2F2F2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    filled: true,
                    fillColor: const Color(0xFFF2F2F2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _loading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1BA57B),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _login,
                  child: const Text(
                    "Sign In",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const SignUpScreen()),
                        );
                      },
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          color: Color(0xFF1BA57B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  "- Or sign in with -",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SocialButton(
                      icon: Icons.facebook,
                      color: Colors.blue,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Facebook sign-in not implemented")),
                        );
                      },
                    ),
                    const SizedBox(width: 20),
                    _SocialButton(
                      icon: Icons.g_mobiledata,
                      color: Colors.red,
                      onTap: _signInWithGoogle,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 24,
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}