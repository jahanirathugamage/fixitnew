import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  bool _validEmail(String email) {
    // ignore: deprecated_member_use
    final reg = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return reg.hasMatch(email);
  }

  Future<void> _sendResetLink() async {
    FocusScope.of(context).unfocus(); // close keyboard

    setState(() => _error = null);

    final email = _email.text.trim();

    if (email.isEmpty || !_validEmail(email)) {
      setState(() => _error = "Enter a valid email");
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Reset link sent to $email"),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      String msg;

      switch (e.code) {
        case 'user-not-found':
          msg = "No account found with this email";
          break;
        case 'invalid-email':
          msg = "Email format is invalid";
          break;
        default:
          msg = e.message ?? "Something went wrong";
      }

      if (mounted) {
        setState(() => _error = msg);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = "Something went wrong. Try again.");
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forgot Password"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              TextField(
                controller: _email,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),

              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),

              const SizedBox(height: 12),

              _loading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _sendResetLink,
                        child: const Text('Send Reset Link'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
