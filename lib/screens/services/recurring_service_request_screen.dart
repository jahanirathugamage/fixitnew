// lib/screens/services/recurring_service_request_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../models/service_config.dart';
import '../../models/service_request_item.dart';
import '../../controllers/service_request_controller.dart';
import '../profile/pick_location_screen.dart';
import 'matching_screen.dart';

// ✅ IMPORTANT: used ONLY to map categoryKey -> ServiceConfig
import 'service_request_wrapper.dart';

class RecurringServiceRequestScreen extends StatefulWidget {
  /// ✅ Supports both flows:
  /// - If you call with categoryKey (from home carousel), we map it to a ServiceConfig.
  /// - If you call with config directly, we use it.
  final String? categoryKey;
  final ServiceConfig config;

  RecurringServiceRequestScreen({
    super.key,
    ServiceConfig? config,
    this.categoryKey,
  }) : config = config ?? _configFromKey(categoryKey);

  // ✅ Only these categories are allowed for recurring services
  static const Set<String> _allowedRecurringKeys = {
    'gardening',
    'cleaning',
    'ac',
    'pest_control',
  };

  static ServiceConfig _configFromKey(String? key) {
    final k = (key ?? '').trim().toLowerCase();

    if (!_allowedRecurringKeys.contains(k)) {
      // ✅ Safe fallback so app doesn't crash
      // (Ideally you should not navigate here with other categories)
      return ServiceRequestWrapper.cleaningConfig;
    }

    switch (k) {
      case 'ac':
        return ServiceRequestWrapper.acConfig;
      case 'gardening':
        return ServiceRequestWrapper.gardeningConfig;
      case 'pest_control':
        return ServiceRequestWrapper.pestControlConfig;
      case 'cleaning':
        return ServiceRequestWrapper.cleaningConfig;
      default:
        return ServiceRequestWrapper.cleaningConfig;
    }
  }

  @override
  State<RecurringServiceRequestScreen> createState() =>
      _RecurringServiceRequestScreenState();
}

class _RecurringServiceRequestScreenState
    extends State<RecurringServiceRequestScreen> {
  final ServiceRequestController _controller = ServiceRequestController();

  // Location text (optional)
  final TextEditingController locationController = TextEditingController();

  // ✅ Pin location (required)
  LatLng? _pickedLatLng;

  // Language preference sheet state
  bool _englishSelected = false;
  bool _sinhalaSelected = false;
  bool _tamilSelected = false;

  // Selected service tasks (by label)
  final Set<String> _selectedServices = {};

  // Recurrence settings
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();

  static const List<String> _daysFull = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ];
  static const List<String> _daysShort = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

  String _preferredDay = "Tuesday"; // default selected like mock

  static const List<String> _frequencies = [
    "1 week",
    "2 weeks",
    "3 weeks",
    "1 month",
    "2 months",
    "3 months",
  ];
  String? _frequency; // show "Repeat Interval" until chosen (like mock)

  // ✅ Used by backend for recurring availability horizon
  final int _horizonCount = 6;

  @override
  void initState() {
    super.initState();

    // ✅ If someone navigates here with a non-recurring category config, gently block usage
    final cat = widget.config.category.trim().toLowerCase();
    const allowedCats = {'gardening', 'cleaning', 'ac', 'pest_control'};
    if (!allowedCats.contains(cat)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Recurring services are only available for Gardening, Cleaning, AC, and Pest Control.',
            ),
          ),
        );
        Navigator.pop(context);
      });
    }
  }

  @override
  void dispose() {
    locationController.dispose();
    super.dispose();
  }

  // ---------- SERVICE SELECTION ----------
  void _onServiceTapped(String label) {
    setState(() {
      if (_selectedServices.contains(label)) {
        _selectedServices.remove(label);
      } else {
        if (_selectedServices.length < 3) {
          _selectedServices.add(label);
        }
      }
    });
  }

  // ---------- PIN PICKER ----------
  Widget _locationPinPicker() {
    final label = _pickedLatLng == null
        ? 'Pick Job Location on Map'
        : 'Location Selected: (${_pickedLatLng!.latitude.toStringAsFixed(5)}, ${_pickedLatLng!.longitude.toStringAsFixed(5)})';

    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton(
        onPressed: () async {
          final initial = _pickedLatLng ?? LatLng(6.9271, 79.8612); // Colombo
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PickLocationScreen(initial: initial),
            ),
          );

          if (result != null && result is LatLng) {
            setState(() => _pickedLatLng = result);
          }
        },
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: Colors.black),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ---------- TOP BUTTONS ----------
  void _onSchedulePressed() => _openScheduleBottomSheet();
  void _onLanguagePressed() => _openLanguageBottomSheet();

  // ---------- TIME PICKER (inside schedule sheet) ----------
  Future<void> _selectTime(
    BuildContext sheetContext,
    StateSetter modalSetState,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: sheetContext,
      initialTime: _startTime,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _startTime = picked);
      modalSetState(() => _startTime = picked);
    }
  }

  // ---------- SCHEDULE SHEET (mock #5) ----------
  void _openScheduleBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter modalSetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.78,
              minChildSize: 0.45,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => Navigator.of(sheetContext).pop(),
                        child: Center(
                          child: Container(
                            width: 60,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Schedule it',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            const Text(
                              'Start Date & Time',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'This time will be used for all future services',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),

                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black, width: 1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  children: [
                                    Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: Colors.black,
                                          onPrimary: Colors.white,
                                          surface: Colors.white,
                                          onSurface: Colors.black,
                                        ),
                                      ),
                                      child: CalendarDatePicker(
                                        initialDate: _startDate,
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(
                                          const Duration(days: 365),
                                        ),
                                        onDateChanged: (date) {
                                          setState(() => _startDate = date);
                                          modalSetState(() => _startDate = date);
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Text(
                                          'Time',
                                          style: TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const Spacer(),
                                        GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () => _selectTime(sheetContext, modalSetState),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(20),
                                              color: const Color(0xFFF2F2F2),
                                            ),
                                            child: Text(
                                              _startTime.format(sheetContext),
                                              style: const TextStyle(
                                                fontFamily: 'Montserrat',
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            const Text(
                              'Preferred Day',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'The day that the service should occur',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(_daysShort.length, (i) {
                                final full = _daysFull[i];
                                final short = _daysShort[i];
                                final selected = _preferredDay == full;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() => _preferredDay = full);
                                    modalSetState(() => _preferredDay = full);
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: selected ? Colors.black : Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.black, width: 1),
                                    ),
                                    child: Center(
                                      child: Text(
                                        short,
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: selected ? Colors.white : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),

                            const SizedBox(height: 22),

                            const Text(
                              'Service Frequency',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'How often the service repeats',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),

                            Container(
                              height: 46,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.black, width: 1),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _frequency,
                                  hint: const Text(
                                    'Repeat Interval',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down),
                                  items: _frequencies
                                      .map(
                                        (v) => DropdownMenuItem<String>(
                                          value: v,
                                          child: Text(
                                            v,
                                            style: const TextStyle(
                                              fontFamily: 'Montserrat',
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() => _frequency = v);
                                    modalSetState(() => _frequency = v);
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Done',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ---------- LANGUAGE SHEET (from ServiceRequestScreen) ----------
  void _openLanguageBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter modalSetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.3,
              maxChildSize: 0.8,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => Navigator.of(sheetContext).pop(),
                        child: Center(
                          child: Container(
                            width: 60,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Choose Preferences',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          children: [
                            const Text(
                              'Language',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _LanguageCheckboxRow(
                              label: 'English',
                              value: _englishSelected,
                              onChanged: (val) {
                                setState(() => _englishSelected = val);
                                modalSetState(() => _englishSelected = val);
                              },
                            ),
                            const SizedBox(height: 8),
                            _LanguageCheckboxRow(
                              label: 'Sinhala',
                              value: _sinhalaSelected,
                              onChanged: (val) {
                                setState(() => _sinhalaSelected = val);
                                modalSetState(() => _sinhalaSelected = val);
                              },
                            ),
                            const SizedBox(height: 8),
                            _LanguageCheckboxRow(
                              label: 'Tamil',
                              value: _tamilSelected,
                              onChanged: (val) {
                                setState(() => _tamilSelected = val);
                                modalSetState(() => _tamilSelected = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Done',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ---------- MOCK TASKS: force exact labels like your screenshots ----------
  List<ServiceOption> _servicesForMock() {
    final cat = widget.config.category.trim().toLowerCase();

    if (cat == 'cleaning') {
      return const [
        ServiceOption(icon: Icons.cleaning_services_outlined, label: 'Kitchen deep clean', price: 0),
        ServiceOption(icon: Icons.bathtub_outlined, label: 'Bathroom deep clean', price: 0),
        ServiceOption(icon: Icons.weekend_outlined, label: 'Sofa/ cushion cleaning', price: 0),
        ServiceOption(icon: Icons.bed_outlined, label: 'Mattress Cleaning', price: 0),
        ServiceOption(icon: Icons.auto_awesome_outlined, label: 'Floor scrubbing & polishing', price: 0),
        ServiceOption(icon: Icons.window_outlined, label: 'Window & grill cleaning', price: 0),
        ServiceOption(icon: Icons.balcony_outlined, label: 'Balcony cleaning', price: 0),
      ];
    }

    if (cat == 'gardening') {
      return const [
        ServiceOption(icon: Icons.grass_outlined, label: 'Grass cutting', price: 0),
        ServiceOption(icon: Icons.park_outlined, label: 'Hedge trimming', price: 0),
        ServiceOption(icon: Icons.content_cut_outlined, label: 'Weeding', price: 0),
        ServiceOption(icon: Icons.nature_outlined, label: 'Tree branch trimming', price: 0),
        ServiceOption(icon: Icons.yard_outlined, label: 'Garden cleanup', price: 0),
      ];
    }

    if (cat == 'ac') {
      return const [
        ServiceOption(icon: Icons.ac_unit_outlined, label: 'Full service', price: 0),
        ServiceOption(icon: Icons.air_outlined, label: 'Outdoor unit cleaning', price: 0),
        ServiceOption(icon: Icons.filter_alt_outlined, label: 'Filter cleaning', price: 0),
      ];
    }

    if (cat == 'pest_control') {
      return const [
        ServiceOption(icon: Icons.bug_report_outlined, label: 'Cockroach treatment', price: 0),
        ServiceOption(icon: Icons.bug_report_outlined, label: 'Ant control treatment', price: 0),
        ServiceOption(icon: Icons.bug_report_outlined, label: 'Mosquito fogging', price: 0),
        ServiceOption(icon: Icons.pets_outlined, label: 'Rodent inspection', price: 0),
        ServiceOption(icon: Icons.bug_report_outlined, label: 'Bed bug treatment', price: 0),
      ];
    }

    // Should never happen due to initState guard, but keep safe
    return const [];
  }

  int _getPriceForService(String label) {
    // prefer real config prices if label exists there
    final fromConfig = widget.config.services.where((s) => s.label == label);
    if (fromConfig.isNotEmpty) return fromConfig.first.price;

    // fallback: if we forced mock list with price 0, keep 0
    return 0;
  }

  // ---------- VALIDATION + SUMMARY SHEET (mock #6) ----------
  void _onContinuePressed() {
    if (_pickedLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick the job location on the map.')),
      );
      return;
    }

    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one service task.')),
      );
      return;
    }

    if ((_frequency ?? '').trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service frequency.')),
      );
      return;
    }

    _openRequestSummaryBottomSheet();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  Map<String, dynamic> _parseFrequency(String label) {
    // label examples: "1 week", "2 weeks", "1 month", "3 months"
    final parts = label.trim().toLowerCase().split(' ');
    final count = int.tryParse(parts.first) ?? 1;
    final unitRaw = parts.length > 1 ? parts[1] : 'week';
    final unit = unitRaw.startsWith('month') ? 'month' : 'week';
    return {
      'intervalCount': count,
      'intervalUnit': unit, // "week" | "month"
      'label': label,
    };
  }

  void _openRequestSummaryBottomSheet() {
    final List<ServiceRequestItem> items = _selectedServices
        .map(
          (label) => ServiceRequestItem(
            label: label,
            quantity: 1,
            unitPrice: _getPriceForService(label),
          ),
        )
        .toList();

    const int visitationFee = 350;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter modalSetState) {
            final int serviceTotal = items.fold(
              0,
              (total, item) => total + item.unitPrice * item.quantity,
            );

            final int platformFee = (serviceTotal * 0.02).round();
            final int totalAmount = serviceTotal + visitationFee + platformFee;

            void updateQuantity(int index, int delta) {
              modalSetState(() {
                final item = items[index];
                if (delta > 0 && item.quantity >= 3) return;

                item.quantity += delta;

                if (item.quantity <= 0) {
                  final removedLabel = item.label;
                  items.removeAt(index);

                  setState(() {
                    _selectedServices.remove(removedLabel);
                  });

                  if (items.isEmpty) {
                    Navigator.of(sheetContext).pop();
                  }
                }
              });
            }

            final String startLine =
                "$_preferredDay · Starting from ${_two(_startDate.day)}/${_two(_startDate.month)}/${_startDate.year}";
            final String everyLine = "Every ${(_frequency ?? '').trim()}";

            return DraggableScrollableSheet(
              initialChildSize: 0.82,
              minChildSize: 0.55,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => Navigator.of(sheetContext).pop(),
                        child: Center(
                          child: Container(
                            width: 80,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Request',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            const Text(
                              'Each task can only have a maximum quantity of 3.',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 14),

                            Row(
                              children: const [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Service Task',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                SizedBox(
                                  width: 90,
                                  child: Center(
                                    child: Text(
                                      'Qty',
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                SizedBox(
                                  width: 80,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'Price',
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            ...List.generate(items.length, (index) {
                              final item = items[index];
                              return Column(
                                children: [
                                  const Divider(),
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          item.label,
                                          style: const TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 90,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            GestureDetector(
                                              onTap: () => updateQuantity(index, -1),
                                              child: Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: Colors.black, width: 1),
                                                ),
                                                child: const Center(
                                                  child: Icon(Icons.remove, size: 16),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${item.quantity}',
                                              style: const TextStyle(
                                                fontFamily: 'Montserrat',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: () => updateQuantity(index, 1),
                                              child: Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: Colors.black, width: 1),
                                                ),
                                                child: const Center(
                                                  child: Icon(Icons.add, size: 16),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 80,
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            'LKR ${item.unitPrice * item.quantity}',
                                            style: const TextStyle(
                                              fontFamily: 'Montserrat',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              );
                            }),

                            if (items.isNotEmpty) const Divider(),
                            const SizedBox(height: 18),

                            const Text(
                              'Request Summary',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '* Please note that the visitation and platform fees will be shown later and payment is required only after the job is completed.',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 14),

                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.black, width: 1),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time, size: 18, color: Colors.black),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          startLine,
                                          style: const TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _startTime.format(sheetContext),
                                          style: const TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    everyLine,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 18),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Service Total',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'LKR $serviceTotal',
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Divider(),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total amount',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'LKR $totalAmount',
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    modalSetState(() => isSaving = true);

                                    final DateTime scheduledAt = DateTime(
                                      _startDate.year,
                                      _startDate.month,
                                      _startDate.day,
                                      _startTime.hour,
                                      _startTime.minute,
                                    );

                                    final List<String> languages = [
                                      if (_englishSelected) 'english',
                                      if (_sinhalaSelected) 'sinhala',
                                      if (_tamilSelected) 'tamil',
                                    ];

                                    final freq = _parseFrequency((_frequency ?? '').trim());

                                    try {
                                      final lat = _pickedLatLng!.latitude;
                                      final lng = _pickedLatLng!.longitude;

                                      // ✅ Step 1: create base job (scheduled)
                                      // NOTE: we keep your existing controller method to avoid breaking existing code.
                                      final String jobId = await _controller.createPlumbingJob(
                                        locationText: locationController.text.trim(),
                                        latitude: lat,
                                        longitude: lng,
                                        isNow: false,
                                        scheduledAt: scheduledAt,
                                        languages: languages,
                                        items: items,
                                        visitationFee: visitationFee,
                                        category: widget.config.category,
                                      );

                                      // ✅ Step 2: merge recurrence fields
                                      // If this fails due to Firestore rules, you'll see it in debug + snackbar.
                                      await FirebaseFirestore.instance
                                          .collection('jobRequest')
                                          .doc(jobId)
                                          .set(
                                        {
                                          "requestType": "recurring",
                                          "isRecurring": true,
                                          "isRecurringRequest": true,
                                          "recurrence": {
                                            "preferredDay": _preferredDay,
                                            "frequencyLabel": freq['label'],
                                            "intervalCount": freq['intervalCount'],
                                            "intervalUnit": freq['intervalUnit'], // week/month
                                            "horizonCount": _horizonCount,
                                            "startAt": Timestamp.fromDate(scheduledAt),
                                          },
                                          "updatedAt": FieldValue.serverTimestamp(),
                                        },
                                        SetOptions(merge: true),
                                      );

                                      debugPrint("✅ Recurring job created + recurrence saved: $jobId");

                                      if (!mounted) return;

                                      // Close sheet first (rootNavigator is safer)
                                      Navigator.of(sheetContext, rootNavigator: true).pop();

                                      // Then navigate
                                      Future.microtask(() {
                                        if (!mounted) return;
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                            builder: (_) => MatchingScreen(jobId: jobId),
                                          ),
                                        );
                                      });
                                    } catch (e) {
                                      debugPrint("❌ Failed to create recurring request: $e");
                                      modalSetState(() => isSaving = false);
                                      if (!mounted) return;

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to create recurring request: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Confirm',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ---------- MAIN BUILD (matches your mock layout) ----------
  @override
  Widget build(BuildContext context) {
    final services = _servicesForMock();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Stack(
                alignment: Alignment.center,
                children: const [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: BackButtonWidget(),
                  ),
                  Center(
                    child: Text(
                      'Schedule a Service',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // top pills
                      Row(
                        children: [
                          Expanded(
                            child: RequestTypeButton(
                              label: 'Schedule',
                              icon: Icons.access_time,
                              onTap: _onSchedulePressed,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RequestTypeButton(
                              label: 'Language',
                              icon: Icons.tune,
                              onTap: _onLanguagePressed,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // location input (mock says Enter Location)
                      TextField(
                        controller: locationController,
                        decoration: InputDecoration(
                          hintText: 'Enter Location',
                          hintStyle: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                          prefixIcon: const Icon(
                            Icons.location_on_outlined,
                            color: Colors.black,
                            size: 24,
                          ),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: Colors.black, width: 1),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: Colors.black, width: 1),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: Colors.black, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ✅ keep pin picker (required)
                      _locationPinPicker(),

                      const SizedBox(height: 30),

                      Center(
                        child: Column(
                          children: [
                            Text(
                              widget.config.title,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'You can select up to 3 service tasks only.',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: services.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          childAspectRatio: 0.85,
                        ),
                        itemBuilder: (context, index) {
                          final option = services[index];
                          return ServiceOptionCard(
                            icon: option.icon,
                            label: option.label,
                            isSelected: _selectedServices.contains(option.label),
                            onTap: () => _onServiceTapped(option.label),
                          );
                        },
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _onContinuePressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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

// ---------- SHARED WIDGETS (same style as your ServiceRequestScreen) ----------

class BackButtonWidget extends StatefulWidget {
  const BackButtonWidget({super.key});

  @override
  State<BackButtonWidget> createState() => _BackButtonWidgetState();
}

class _BackButtonWidgetState extends State<BackButtonWidget> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) {
        setState(() => isPressed = false);
        Navigator.pop(context);
      },
      onTapCancel: () => setState(() => isPressed = false),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isPressed ? const Color(0xFFE8E8E8) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            Icons.chevron_left,
            size: 40,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class RequestTypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const RequestTypeButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ServiceOptionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const ServiceOptionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<ServiceOptionCard> createState() => _ServiceOptionCardState();
}

class _ServiceOptionCardState extends State<ServiceOptionCard> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.isSelected || isPressed;

    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) {
        setState(() => isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => isPressed = false),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final iconSize = constraints.maxWidth * (40 / 70);

                return AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: active ? Colors.black : Colors.white,
                      border: Border.all(color: Colors.black, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Icon(
                          widget.icon,
                          size: iconSize,
                          color: active ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageCheckboxRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _LanguageCheckboxRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: (v) => onChanged(v ?? false),
          activeColor: Colors.black,
          checkColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
