// lib/models/service_config.dart

import 'package:flutter/material.dart';

/// One selectable service option in a category (e.g. “Gas refill”).
class ServiceOption {
  final IconData icon;
  final String label;

  /// Normalised price for this option.
  ///
  /// We support both [price] and the legacy [unitPrice] named parameter
  /// so older code still compiles.
  final int price;

  const ServiceOption({
    required this.icon,
    required this.label,

    /// Preferred new name
    int? price,

    /// Legacy name used in some older screens/configs
    int? unitPrice,
  }) : price = price ?? unitPrice ?? 0;
}

/// Config for a whole service category (AC, Plumbing, etc.)
class ServiceConfig {
  final String category; // e.g. "plumbing"
  final String title;    // e.g. "Plumbing"
  final List<ServiceOption> services;

  const ServiceConfig({
    required this.category,
    required this.title,
    required this.services,
  });
}
