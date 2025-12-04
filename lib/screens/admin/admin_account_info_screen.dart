import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAccountInfoScreen extends StatefulWidget {
  const AdminAccountInfoScreen({super.key});

  @override
  State<AdminAccountInfoScreen> createState() =>
      _AdminAccountInfoScreenState();
}

class _AdminAccountInfoScreenState extends State<AdminAccountInfoScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadAdminProfile();
  }

  Future<void> _loadAdminProfile() async {
    final user = _user;
    if (user == null) {
      setState(() {
        _error = 'No logged in admin.';
        _loading = false;
      });
      return;
    }

    try {
      // primary admin profile in /admins/{uid}
      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        final firstName = (data['firstName'] ?? '') as String;
        final lastName = (data['lastName'] ?? '') as String;
        final email =
            (data['email'] ?? user.email ?? '') as String;

        _first.text = firstName;
        _last.text = lastName;
        _email.text = email;
      } else {
        // fallback if admins/{uid} not yet created
        _first.text = '';
        _last.text = '';
        _email.text = user.email ?? '';
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _save() async {
    if (_saving) return;

    final user = _user;
    if (user == null) {
      setState(() => _error = 'No authenticated admin.');
      return;
    }

    final first = _first.text.trim();
    final last = _last.text.trim();
    final email = _email.text.trim();

    if (first.isEmpty || last.isEmpty || email.isEmpty || !email.contains('@')) {
      setState(() => _error =
          'Please enter valid first name, last name and email.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final uid = user.uid;

      // 1) Update /admins/{uid}
      await FirebaseFirestore.instance.collection('admins').doc(uid).set({
        'firstName': first,
        'lastName': last,
        'email': email,
        'role': 'admin',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2) Update /users/{uid} (global user doc)
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'role': 'admin',
        'firstName': first,
        'lastName': last,
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Optional: update auth displayName (does NOT change login email)
      try {
        await user.updateDisplayName('$first $last');
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account details updated')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Save failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _deleteAccount() async {
    final user = _user;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete this admin account? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final uid = user.uid;

      // Delete Firestore docs (ignore if they don't exist)
      await FirebaseFirestore.instance
          .collection('admins')
          .doc(uid)
          .delete()
          .catchError((_) {});
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .delete()
          .catchError((_) {});

      // Try to delete auth user (may fail if not recently logged in)
      try {
        await user.delete();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not delete login user (needs recent login). '
                'Firestore admin profile was removed.\n$e',
              ),
            ),
          );
        }
      }

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Manage Account',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label('First Name'),
              _inputBox(_first),
              _label('Last Name'),
              _inputBox(_last),
              _label('Email'),
              _inputBox(_email, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 12),
              ],
              _saving
                  ? const Center(child: CircularProgressIndicator())
                  : _primaryButton('Done', _save),
              const SizedBox(height: 16),
              _secondaryButton('Delete Account', _deleteAccount),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 4, top: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _inputBox(
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _primaryButton(String text, VoidCallback onPressed) {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _secondaryButton(String text, VoidCallback onPressed) {
    return SizedBox(
      height: 55,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.black),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
