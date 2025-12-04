// lib/screens/services/service_request_wrapper.dart

import 'package:flutter/material.dart';
import '../../models/service_config.dart';

class ServiceRequestWrapper {
  // AC
  static const ServiceConfig acConfig = ServiceConfig(
    category: "ac",
    title: "AC Repair",
    services: [
      ServiceOption(icon: Icons.ac_unit, label: "Gas refill", price: 2000),
      ServiceOption(
        icon: Icons.build,
        label: "AC inspection",
        price: 1800,
      ),
    ],
  );

  // Plumbing
  static const ServiceConfig plumbingConfig = ServiceConfig(
    category: "plumbing",
    title: "Plumbing",
    services: [
      ServiceOption(
        icon: Icons.water_drop,
        label: "Leak repair",
        price: 1500,
      ),
      ServiceOption(
        icon: Icons.plumbing,
        label: "Pipe replacement",
        price: 3000,
      ),
    ],
  );

  // Electrical
  static const ServiceConfig electricalConfig = ServiceConfig(
    category: "electrical",
    title: "Electrical",
    services: [
      ServiceOption(
        icon: Icons.electrical_services,
        label: "Switch repair",
        price: 1200,
      ),
      ServiceOption(
        icon: Icons.lightbulb,
        label: "Bulb replacement",
        price: 500,
      ),
    ],
  );

  // Carpentry
  static const ServiceConfig carpentryConfig = ServiceConfig(
    category: "carpentry",
    title: "Carpentry",
    services: [
      ServiceOption(
        icon: Icons.chair_alt,
        label: "Furniture repair",
        price: 2500,
      ),
      ServiceOption(
        icon: Icons.inventory_2,
        label: "Cabinet installation",
        price: 4000,
      ),
    ],
  );

  // Gardening
  static const ServiceConfig gardeningConfig = ServiceConfig(
    category: "gardening",
    title: "Gardening",
    services: [
      ServiceOption(
        icon: Icons.grass,
        label: "Grass cutting",
        price: 1500,
      ),
      ServiceOption(
        icon: Icons.yard,
        label: "Weeding & cleanup",
        price: 1800,
      ),
    ],
  );

  // Pest control
  static const ServiceConfig pestControlConfig = ServiceConfig(
    category: "pest_control",
    title: "Pest Control",
    services: [
      ServiceOption(
        icon: Icons.bug_report,
        label: "Cockroach treatment",
        price: 2200,
      ),
      ServiceOption(
        icon: Icons.pest_control_rodent,
        label: "Rodent inspection",
        price: 2500,
      ),
    ],
  );

  // Appliances
  static const ServiceConfig appliancesConfig = ServiceConfig(
    category: "appliances",
    title: "Appliance Repair",
    services: [
      ServiceOption(
        icon: Icons.kitchen,
        label: "Fridge repair",
        price: 3500,
      ),
      ServiceOption(
        icon: Icons.local_laundry_service,
        label: "Washing machine repair",
        price: 3200,
      ),
    ],
  );

  // Cleaning
  static const ServiceConfig cleaningConfig = ServiceConfig(
    category: "cleaning",
    title: "Cleaning",
    services: [
      ServiceOption(
        icon: Icons.cleaning_services,
        label: "Home deep clean",
        price: 3000,
      ),
      ServiceOption(
        icon: Icons.home,
        label: "Regular house cleaning",
        price: 2000,
      ),
    ],
  );
}
