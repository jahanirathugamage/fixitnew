// lib/controllers/payments/final_payment_controller.dart

import 'package:fixitnew/backend/api_client.dart';

class FinalPaymentController {
  /// CLIENT:
  /// Client confirms they have paid the final invoice amount.
  /// Backend: pages/api/client-final-payment-confirm.ts
  ///
  /// Expected backend effects:
  /// - mark payment as client_confirmed
  /// - move job to awaiting_final_payment_confirmation
  /// - notify provider to confirm receipt
  Future<void> clientConfirmFinalPayment({
    required String jobId,
  }) async {
    final cleanJobId = jobId.trim();
    if (cleanJobId.isEmpty) {
      throw Exception("jobId is required");
    }

    await ApiClient.postJson(
      "/api/client-final-payment-confirm",
      body: {
        "jobId": cleanJobId,
      },
    );
  }

  /// PROVIDER:
  /// Provider confirms they have received the final payment.
  /// Backend: pages/api/provider-confirm-final-payment.ts
  ///
  /// Expected backend effects:
  /// - mark payment as completed
  /// - mark job as completed
  /// - notify client
  Future<void> providerConfirmFinalPaymentReceived({
    required String jobId,
  }) async {
    final cleanJobId = jobId.trim();
    if (cleanJobId.isEmpty) {
      throw Exception("jobId is required");
    }

    await ApiClient.postJson(
      "/api/provider-confirm-final-payment",
      body: {
        "jobId": cleanJobId,
      },
    );
  }
}
