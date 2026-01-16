// lib/screens/dashboards/provider/provider_confirm_final_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:fixitnew/controllers/provider/provider_job_details_controller.dart';

class ProviderConfirmFinalPaymentScreen extends StatelessWidget {
  final String jobId;
  const ProviderConfirmFinalPaymentScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    final controller = ProviderJobDetailsController();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Confirm Payment",
          style: TextStyle(fontFamily: "Montserrat", fontWeight: FontWeight.w800),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Icon(Icons.check_circle_outline, size: 70, color: Colors.black),
            const SizedBox(height: 18),
            const Text(
              "Confirm Final Payment",
              style: TextStyle(
                fontFamily: "Montserrat",
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Confirm you received the final invoice payment to complete this job.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Montserrat",
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await controller.confirmFinalPaymentReceived(jobId: jobId);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Confirmed. Job completed.")),
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Confirm Payment Received",
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
