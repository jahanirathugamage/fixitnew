import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RatingReviewSheet {
  /// role:
  /// - "client"  => reviewer = currentUser, reviewee = job.selectedProviderUid
  /// - "provider" => reviewer = currentUser, reviewee = job.clientId
  static Future<void> show({
    required BuildContext context,
    required String jobId,
    required String role,
  }) async {
    final cleanJobId = jobId.trim();
    final cleanRole = role.trim().toLowerCase();

    if (cleanJobId.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _RatingReviewContent(
          jobId: cleanJobId,
          role: cleanRole,
        );
      },
    );
  }
}

class _RatingReviewContent extends StatefulWidget {
  final String jobId;
  final String role;

  const _RatingReviewContent({
    required this.jobId,
    required this.role,
  });

  @override
  State<_RatingReviewContent> createState() => _RatingReviewContentState();
}

class _RatingReviewContentState extends State<_RatingReviewContent> {
  final _commentController = TextEditingController();

  int _rating = 0;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _resolveReviewerReviewee() async {
    final user = FirebaseAuth.instance.currentUser;
    final reviewerId = user?.uid.trim() ?? "";

    if (reviewerId.isEmpty) {
      throw Exception("Not signed in");
    }

    final jobSnap = await FirebaseFirestore.instance
        .collection("jobRequest")
        .doc(widget.jobId)
        .get();

    final job = jobSnap.data() ?? {};
    final clientId = (job["clientId"] ?? "").toString().trim();
    final providerId = (job["selectedProviderUid"] ?? job["providerUid"] ?? "")
        .toString()
        .trim();

    if (widget.role == "client") {
      if (providerId.isEmpty) {
        throw Exception("Missing selectedProviderUid for this job");
      }
      return {
        "reviewerId": reviewerId,
        "revieweeId": providerId,
      };
    }

    if (widget.role == "provider") {
      if (clientId.isEmpty) {
        throw Exception("Missing clientId for this job");
      }
      return {
        "reviewerId": reviewerId,
        "revieweeId": clientId,
      };
    }

    throw Exception("Invalid role: ${widget.role}");
  }

  Future<void> _submit() async {
    if (_saving) return;

    if (_rating < 1 || _rating > 5) {
      setState(() => _error = "Please select a rating.");
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final ids = await _resolveReviewerReviewee();

      final reviewerId = ids["reviewerId"]!;
      final revieweeId = ids["revieweeId"]!;
      final reviewText = _commentController.text.trim();

      await FirebaseFirestore.instance.collection("reviews").add({
        "jobId": widget.jobId,
        "reviewerId": reviewerId,
        "revieweeId": revieweeId,
        "rating": _rating,
        "review": reviewText,
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }

    // ✅ IMPORTANT FIX:
    // Don't "return" inside finally (it triggers the lint you saw).
    if (!mounted) return;
    setState(() => _saving = false);
  }

  Widget _star(int index) {
    final selected = _rating >= index;
    return InkWell(
      onTap: _saving ? null : () => setState(() => _rating = index),
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          selected ? Icons.star : Icons.star_border,
          size: 32,
          color: selected ? Colors.black : Colors.black26,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.45,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6E6E6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "Rate your experience",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "Montserrat",
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Tap a star to rate. You can also leave a comment.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "Montserrat",
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _star(1),
                      _star(2),
                      _star(3),
                      _star(4),
                      _star(5),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _commentController,
                    enabled: !_saving,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Write a comment (optional)",
                      hintStyle: const TextStyle(
                        fontFamily: "Montserrat",
                        fontWeight: FontWeight.w500,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF6F6F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                    style: const TextStyle(
                      fontFamily: "Montserrat",
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: "Montserrat",
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        color: Colors.red,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Submit",
                              style: TextStyle(
                                fontFamily: "Montserrat",
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Not now",
                        style: TextStyle(
                          fontFamily: "Montserrat",
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}