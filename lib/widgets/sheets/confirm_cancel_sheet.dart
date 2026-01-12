// lib/widgets/sheets/confirm_cancel_sheet.dart

import 'package:flutter/material.dart';

class ConfirmCancelSheet {
  static Future<bool?> show({
    required BuildContext context,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ConfirmCancelContent(),
    );
  }
}

class _ConfirmCancelContent extends StatelessWidget {
  const _ConfirmCancelContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
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
            const SizedBox(height: 22),
            const Text(
              "Wait, are you sure?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Montserrat",
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Do you really want to cancel this job request? You'll need to start over if you change your mind.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Montserrat",
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "No, Keep Job",
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Yes, Cancel",
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
  }
}
