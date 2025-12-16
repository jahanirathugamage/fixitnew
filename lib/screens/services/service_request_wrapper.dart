// lib/screens/services/service_request_wrapper.dart

// import 'package:flutter/material.dart';
// import '../../models/service_config.dart';

// class ServiceRequestWrapper {
//   // AC
//   static const ServiceConfig acConfig = ServiceConfig(
//     category: "ac",
//     title: "AC Repair",
//     services: [
//       ServiceOption(icon: Icons.ac_unit, label: "Gas refill", price: 2000),
//       ServiceOption(
//         icon: Icons.build,
//         label: "AC inspection",
//         price: 1800,
//       ),
//     ],
//   );

//   // Plumbing
//   static const ServiceConfig plumbingConfig = ServiceConfig(
//     category: "plumbing",
//     title: "Plumbing",
//     services: [
//       ServiceOption(
//         icon: Icons.water_drop,
//         label: "Leak repair",
//         price: 1500,
//       ),
//       ServiceOption(
//         icon: Icons.plumbing,
//         label: "Pipe replacement",
//         price: 3000,
//       ),
//     ],
//   );

//   // Electrical
//   static const ServiceConfig electricalConfig = ServiceConfig(
//     category: "electrical",
//     title: "Electrical",
//     services: [
//       ServiceOption(
//         icon: Icons.electrical_services,
//         label: "Switch repair",
//         price: 1200,
//       ),
//       ServiceOption(
//         icon: Icons.lightbulb,
//         label: "Bulb replacement",
//         price: 500,
//       ),
//     ],
//   );

//   // Carpentry
//   static const ServiceConfig carpentryConfig = ServiceConfig(
//     category: "carpentry",
//     title: "Carpentry",
//     services: [
//       ServiceOption(
//         icon: Icons.chair_alt,
//         label: "Furniture repair",
//         price: 2500,
//       ),
//       ServiceOption(
//         icon: Icons.inventory_2,
//         label: "Cabinet installation",
//         price: 4000,
//       ),
//     ],
//   );

//   // Gardening
//   static const ServiceConfig gardeningConfig = ServiceConfig(
//     category: "gardening",
//     title: "Gardening",
//     services: [
//       ServiceOption(
//         icon: Icons.grass,
//         label: "Grass cutting",
//         price: 1500,
//       ),
//       ServiceOption(
//         icon: Icons.yard,
//         label: "Weeding & cleanup",
//         price: 1800,
//       ),
//     ],
//   );

//   // Pest control
//   static const ServiceConfig pestControlConfig = ServiceConfig(
//     category: "pest_control",
//     title: "Pest Control",
//     services: [
//       ServiceOption(
//         icon: Icons.bug_report,
//         label: "Cockroach treatment",
//         price: 2200,
//       ),
//       ServiceOption(
//         icon: Icons.pest_control_rodent,
//         label: "Rodent inspection",
//         price: 2500,
//       ),
//     ],
//   );

//   // Appliances
//   static const ServiceConfig appliancesConfig = ServiceConfig(
//     category: "appliances",
//     title: "Appliance Repair",
//     services: [
//       ServiceOption(
//         icon: Icons.kitchen,
//         label: "Fridge repair",
//         price: 3500,
//       ),
//       ServiceOption(
//         icon: Icons.local_laundry_service,
//         label: "Washing machine repair",
//         price: 3200,
//       ),
//     ],
//   );

//   // Cleaning
//   static const ServiceConfig cleaningConfig = ServiceConfig(
//     category: "cleaning",
//     title: "Cleaning",
//     services: [
//       ServiceOption(
//         icon: Icons.cleaning_services,
//         label: "Home deep clean",
//         price: 3000,
//       ),
//       ServiceOption(
//         icon: Icons.home,
//         label: "Regular house cleaning",
//         price: 2000,
//       ),
//     ],
//   );
// }

// lib/screens/services/service_request_wrapper.dart

import 'package:flutter/material.dart';
import '../../models/service_config.dart';

class ServiceRequestWrapper {
  // ---------------- AC ----------------
  static const ServiceConfig acConfig = ServiceConfig(
    category: "ac",
    title: "AC",
    services: [
      ServiceOption(
        icon: Icons.build_circle_outlined,
        label: "Full service",
        price: 5000,
      ),
      ServiceOption(
        icon: Icons.local_gas_station_outlined,
        label: "Gas top-up",
        price: 3500,
      ),
      ServiceOption(
        icon: Icons.filter_alt_outlined,
        label: "Filter cleaning",
        price: 2000,
      ),
      ServiceOption(
        icon: Icons.water_damage_outlined,
        label: "Water leak repair",
        price: 2500,
      ),
      ServiceOption(
        icon: Icons.handyman_outlined,
        label: "Basic repair",
        price: 3000,
      ),
      ServiceOption(
        icon: Icons.ac_unit_outlined,
        label: "Outdoor unit cleaning",
        price: 2800,
      ),
      ServiceOption(
        icon: Icons.settings_remote_outlined,
        label: "Remote programming",
        price: 1500,
      ),
      ServiceOption(
        icon: Icons.plumbing_outlined,
        label: "Drainage pipe unclogging",
        price: 2200,
      ),
    ],
  );

  // -------------- Plumbing --------------
  static const ServiceConfig plumbingConfig = ServiceConfig(
    category: "plumbing",
    title: "Plumbing",
    services: [
      ServiceOption(
        icon: Icons.water_damage_outlined,
        label: "Tap Fix",
        price: 1500,
      ),
      ServiceOption(
        icon: Icons.plumbing,
        label: "Minor pipe repair",
        price: 2000,
      ),
      ServiceOption(
        icon: Icons.water_damage,
        label: "Pipe sealing",
        price: 2200,
      ),
      ServiceOption(
        icon: Icons.wc,
        label: "Toilet Flushing System Repair",
        price: 2500,
      ),
      ServiceOption(
        icon: Icons.waves_outlined,
        label: "Unclogging drainage",
        price: 2300,
      ),
      ServiceOption(
        icon: Icons.shower_outlined,
        label: "Shower head replacement",
        price: 2600,
      ),
      ServiceOption(
        icon: Icons.filter_alt_outlined,
        label: "Water filter Installation",
        price: 2800,
      ),
      ServiceOption(
        icon: Icons.water_drop_outlined,
        label: "Running toilet fix",
        price: 2100,
      ),
    ],
  );

  // ------------ Electrical -------------
  static const ServiceConfig electricalConfig = ServiceConfig(
    category: "electrical",
    title: "Electrical",
    services: [
      ServiceOption(
        icon: Icons.lightbulb_outline,
        label: "Light bulb replacement",
        price: 800,
      ),
      ServiceOption(
        icon: Icons.light_outlined,
        label: "Light fixture installation",
        price: 2500,
      ),
      ServiceOption(
        icon: Icons.toggle_on_outlined,
        label: "Switch replacement",
        price: 1500,
      ),
      ServiceOption(
        icon: Icons.power_outlined,
        label: "Socket Fix",
        price: 1800,
      ),
      ServiceOption(
        icon: Icons.electric_bolt_outlined,
        label: "Trip switch troubleshoot",
        price: 2200,
      ),
      ServiceOption(
        icon: Icons.cable_outlined,
        label: "Minor wiring repairs",
        price: 2600,
      ),
      ServiceOption(
        icon: Icons.report_gmailerrorred_outlined,
        label: "Power outage diagnosis",
        price: 3000,
      ),
    ],
  );

  // ------------- Carpentry -------------
  static const ServiceConfig carpentryConfig = ServiceConfig(
    category: "carpentry",
    title: "Carpentry",
    services: [
      ServiceOption(
        icon: Icons.door_front_door_outlined,
        label: "Door hinge repair",
        price: 2200,
      ),
      ServiceOption(
        icon: Icons.chair_outlined,
        label: "Broken chair leg repair",
        price: 2500,
      ),
      ServiceOption(
        icon: Icons.shelves,
        label: "Shelf installation",
        price: 2800,
      ),
      ServiceOption(
        icon: Icons.view_list_outlined,
        label: "Shelf repair",
        price: 2200,
      ),
      ServiceOption(
        icon: Icons.settings_ethernet_outlined,
        label: "Handle Replacement",
        price: 2000,
      ),
      ServiceOption(
        icon: Icons.table_bar_outlined,
        label: "Table leg repair",
        price: 2400,
      ),
      ServiceOption(
        icon: Icons.weekend_outlined,
        label: "Assemble furniture",
        price: 3500,
      ),
      ServiceOption(
        icon: Icons.open_in_full_outlined,
        label: "Drawer repair",
        price: 2300,
      ),
      ServiceOption(
        icon: Icons.construction_outlined,
        label: "Patching wood cracks",
        price: 2600,
      ),
    ],
  );

  // ------------- Gardening -------------
  static const ServiceConfig gardeningConfig = ServiceConfig(
    category: "gardening",
    title: "Gardening",
    services: [
      ServiceOption(
        icon: Icons.grass,
        label: "Grass cutting",
        price: 1800,
      ),
      ServiceOption(
        icon: Icons.park_outlined,
        label: "Hedge trimming",
        price: 2000,
      ),
      ServiceOption(
        icon: Icons.yard_outlined,
        label: "Weeding",
        price: 1700,
      ),
      ServiceOption(
        icon: Icons.eco_outlined,
        label: "Compost application",
        price: 1900,
      ),
      ServiceOption(
        icon: Icons.nature_outlined,
        label: "Tree branch trimming",
        price: 2600,
      ),
      ServiceOption(
        icon: Icons.nature_people_outlined,
        label: "Garden cleanup",
        price: 2500,
      ),
      ServiceOption(
        icon: Icons.local_florist_outlined,
        label: "Flowerbed arrangement",
        price: 2300,
      ),
      ServiceOption(
        icon: Icons.grass_outlined,
        label: "Potting plants",
        price: 2000,
      ),
    ],
  );

  // ---------- Pest Control ----------
  static const ServiceConfig pestControlConfig = ServiceConfig(
    category: "pest_control",
    title: "Pest Control",
    services: [
      ServiceOption(
        icon: Icons.bug_report_outlined,
        label: "Cockroach treatment",
        price: 3000,
      ),
      ServiceOption(
        icon: Icons.pest_control_outlined,
        label: "Ant control treatment",
        price: 2800,
      ),
      ServiceOption(
        icon: Icons.cloud_outlined,
        label: "Mosquito fogging",
        price: 3200,
      ),
      ServiceOption(
        icon: Icons.pest_control_rodent_outlined,
        label: "Rodent inspection",
        price: 2900,
      ),
      ServiceOption(
        icon: Icons.bug_report,
        label: "Bed bug treatment",
        price: 3500,
      ),
      ServiceOption(
        icon: Icons.bug_report_rounded,
        label: "Termite control",
        price: 4200,
      ),
    ],
  );

  // ------------- Appliances -------------
  static const ServiceConfig appliancesConfig = ServiceConfig(
    category: "appliances",
    title: "Appliances",
    services: [
      ServiceOption(
        icon: Icons.local_laundry_service_outlined,
        label: "Washing Machine",
        price: 3500,
      ),
      ServiceOption(
        icon: Icons.microwave_outlined,
        label: "Microwave",
        price: 2800,
      ),
      ServiceOption(
        icon: Icons.rice_bowl_outlined,
        label: "Rice cooker",
        price: 2500,
      ),
      ServiceOption(
        icon: Icons.blender_outlined,
        label: "Blender/ mixer",
        price: 1800,
      ),
      ServiceOption(
        icon: Icons.local_fire_department_outlined,
        label: "Gas cooker ignition",
        price: 2200,
      ),
      ServiceOption(
        icon: Icons.kitchen_outlined,
        label: "Refrigerator",
        price: 4000,
      ),
      ServiceOption(
        icon: Icons.local_pizza_outlined,
        label: "Electric oven",
        price: 3200,
      ),
      ServiceOption(
        icon: Icons.tv_outlined,
        label: "TV",
        price: 2600,
      ),
    ],
  );

  // ------------- Cleaning -------------
  static const ServiceConfig cleaningConfig = ServiceConfig(
    category: "cleaning",
    title: "Cleaning",
    services: [
      ServiceOption(
        icon: Icons.kitchen_outlined,
        label: "Kitchen deep clean",
        price: 2500,
      ),
      ServiceOption(
        icon: Icons.bathtub_outlined,
        label: "Bathroom deep clean",
        price: 2500,
      ),
      ServiceOption(
        icon: Icons.chair_outlined,
        label: "Sofa/ cushion cleaning",
        price: 2300,
      ),
      ServiceOption(
        icon: Icons.bed_outlined,
        label: "Mattress Cleaning",
        price: 2600,
      ),
      ServiceOption(
        icon: Icons.cleaning_services_outlined,
        label: "Floor scrubbing & polishing",
        price: 2800,
      ),
      ServiceOption(
        icon: Icons.window_outlined,
        label: "Window & grill cleaning",
        price: 2400,
      ),
      ServiceOption(
        icon: Icons.balcony_outlined,
        label: "Balcony cleaning",
        price: 2200,
      ),
    ],
  );
}

