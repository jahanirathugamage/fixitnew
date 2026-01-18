// lib/screens/dashboards/client/client_quotation_review_screen.dart

import 'package:flutter/material.dart';
import 'package:fixitnew/screens/quotations/client_quotation_screen.dart';

class ClientQuotationReviewScreen extends StatelessWidget {
  final String jobId;
  const ClientQuotationReviewScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    return ClientQuotationScreen(jobId: jobId);
  }
}
