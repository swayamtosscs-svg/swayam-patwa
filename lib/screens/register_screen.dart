import 'package:flutter/material.dart';

class RegisterScreen extends StatelessWidget {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFF3F9),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("ॐ", style: TextStyle(fontSize: 32, color: Colors.amber)),
                    SizedBox(width: 10),
                    Text("✝", style: TextStyle(fontSize: 32, color: Colors.amber)),
                    SizedBox(width: 10),
                    Text("☪", style: TextStyle(fontSize: 32, color: Colors.amber)),
                    SizedBox(width: 10),
                    Text("☬", style: TextStyle(fontSize: 32, color: Colors.amber)),
                  ],
                ),
                SizedBox(height: 16),
                Text("DivineConnect", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                Text("Your daily path to spirituality", style: TextStyle(color: Colors.grey[700])),
                SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: "John Doe",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: "john.doe@example.com",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Create a password",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Confirm your password",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 14),
                    child: Text("Sign up"),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: Text("Already have an account? Sign in"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
