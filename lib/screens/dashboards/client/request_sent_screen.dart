import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixitnew/screens/dashboards/client/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../backend/api_config.dart';
import 'job_tracking_screen.dart';

class RequestSentScreen extends StatefulWidget {
  final String jobId;

  const RequestSentScreen({super.key, required this.jobId});

  @override
  State<RequestSentScreen> createState() => _RequestSentScreenState();
}

class _RequestSentScreenState extends State<RequestSentScreen> {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  Timer? _timer;

  DateTime? _expiresAt;
  Duration _remaining = Duration.zero;

  bool _handledTerminal = false;
  bool _cancelling = false;

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();

    final ref =
        FirebaseFirestore.instance.collection('jobRequest').doc(widget.jobId);

    _sub = ref.snapshots().listen((snap) {
      if (!mounted) return;
      if (!snap.exists) return;

      final data = snap.data() ?? {};

      // countdown
      final ts = data['holdExpiresAt'];
      if (ts is Timestamp) {
        _expiresAt = ts.toDate();
        _tick(); // update immediately
        _timer ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      }

      // auto navigation rules
      final status = (data['status'] ?? '').toString().trim().toLowerCase();

      // ACCEPTED / CONFIRMED
      if (!_handledTerminal && (status == 'confirmed' || status == 'accepted')) {
        _handledTerminal = true;
        _timer?.cancel();

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => JobTrackingScreen(jobId: widget.jobId),
          ),
        );
        return;
      }

      // REJECTED / CANCELLED / EXPIRED
      if (!_handledTerminal &&
          (status == 'rejected' ||
              status == 'expired' ||
              status == 'cancelled_by_client' ||
              status == 'cancelled')) {
        _handledTerminal = true;
        _timer?.cancel();

        if (!mounted) return;
        Navigator.pop(context); // back to matches
        return;
      }
    });
  }

  void _tick() {
    if (!mounted) return;
    final exp = _expiresAt;
    if (exp == null) return;

    final now = DateTime.now();
    final diff = exp.difference(now);

    setState(() {
      _remaining = diff.isNegative ? Duration.zero : diff;
    });

    // auto-expire return if time hits 0
    if (!_handledTerminal && diff.isNegative) {
      _handledTerminal = true;
      _timer?.cancel();

      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  String _fmt(Duration d) {
    final s = d.inSeconds;
    final mm = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Future<void> _cancelRequest() async {
    if (_cancelling) return;

    setState(() => _cancelling = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("No user logged in.");

      final token = await user.getIdToken(true);

      final uri = Uri.parse("${ApiConfig.baseUrl}/api/cancel-hold");

      final resp = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"jobId": widget.jobId}),
      );

      if (!mounted) return; // ✅ guard before using context/messenger

      final messenger = ScaffoldMessenger.of(context);

      if (resp.statusCode == 200) {
        messenger.showSnackBar(
          const SnackBar(content: Text("✅ Request cancelled.")),
        );
        if (mounted) Navigator.pop(context);
        return;
      }

      throw Exception("Cancel failed (${resp.statusCode}): ${resp.body}");
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cancel error: $e")),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countdown = _expiresAt == null ? "--:--" : _fmt(_remaining);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // ✅ Header row exactly like screenshot (FixIt + back arrow)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.black,
                      size: 18,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "FixIt",
                    style: TextStyle(
                      fontFamily: "Montserrat",
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Center content
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✅ white circle with black border + check (like screenshot)
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check,
                            size: 36,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        "Request Sent!",
                        style: TextStyle(
                          fontFamily: "Montserrat",
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Waiting for the provider to accept...",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: "Montserrat",
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // ✅ Plain text line (no box) like screenshot
                      Text(
                        "Hold expires in $countdown",
                        style: const TextStyle(
                          fontFamily: "Montserrat",
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ✅ Primary button: Back to Home (black filled)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _goHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Back to Home",
                    style: TextStyle(
                      fontFamily: "Montserrat",
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ✅ Secondary button: Cancel Request (outlined)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _cancelling ? null : _cancelRequest,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black, width: 1.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _cancelling ? "Cancelling..." : "Cancel Request",
                    style: const TextStyle(
                      fontFamily: "Montserrat",
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}
