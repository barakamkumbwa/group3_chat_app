import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthService _auth;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool loading = false;
  bool rememberMe = true;
  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _auth = AuthService();
  }

  void login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter both email and password."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => loading = true);
    try {
      var user = await _auth.loginWithEmail(email, password);
      if (!mounted) return;
      setState(() => loading = false);
      if (user != null) {
        // Navigation is handled globally by auth state listener in main.dart.
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);

      String errorMessage = "Login failed. Please try again.";

      if (e.toString().contains("invalid-credential")) {
        errorMessage = "Invalid email or password.";
      } else if (e.toString().contains("user-not-found")) {
        errorMessage = "No account found with this email.";
      } else if (e.toString().contains("wrong-password")) {
        errorMessage = "Incorrect password.";
      } else if (e.toString().contains("too-many-requests")) {
        errorMessage =
            "Too many login attempts. Please try again later.";
      } else if (e.toString().contains("network-request-failed")) {
        errorMessage =
            "Network error. Please check your internet connection.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              const Icon(Icons.spa_rounded, size: 80, color: Color(0xFF2D6A4F)),

              const SizedBox(height: 20),

              const Text(
                "G3 ChatApp",
                style: TextStyle(
                  color: Color(0xFF1B4332),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "Login to explore the world of chatting",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),

              const SizedBox(height: 50),

              buildTextField(
                controller: emailController,
                hint: "Email",
                icon: Icons.email_outlined,
              ),

              const SizedBox(height: 20),

              buildTextField(
                controller: passwordController,
                hint: "Password",
                icon: Icons.lock_outline,
                obscure: obscurePassword,
                isPassword: true,
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: rememberMe,
                        activeColor: const Color(0xFF2D6A4F),
                        onChanged: (v) => setState(() => rememberMe = v!),
                      ),
                      const Text(
                        "Remember Me",
                        style:
                            TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(
                          color: Color(0xFF2D6A4F), fontSize: 13),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              loading
                  ? const CircularProgressIndicator(
                      color: Color(0xFF2D6A4F))
                  : ElevatedButton(
                      onPressed: login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF2D6A4F),
                        foregroundColor: Colors.white,
                        minimumSize:
                            const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

              const SizedBox(height: 40),

              const Text(
                "Or continue with",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  socialIcon(Icons.facebook, Colors.blue),
                  const SizedBox(width: 20),
                  socialIcon(Icons.g_mobiledata, Colors.red,
                      isGoogle: true),
                  const SizedBox(width: 20),
                  socialIcon(Icons.apple, Colors.black),
                ],
              ),

              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Colors.grey),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const RegisterScreen()),
                    ),
                    child: const Text(
                      "Sign up",
                      style: TextStyle(
                        color: Color(0xFF2D6A4F),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget socialIcon(IconData icon, Color color,
      {bool isGoogle = false}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Icon(icon,
          color: color, size: isGoogle ? 35 : 28),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () => setState(
                    () => obscurePassword =
                        !obscurePassword),
              )
            : null,
        hintText: hint,
        hintStyle:
            const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFF1F5F3),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
