// lib/screens/services/service_request_screen.dart
// ignore_for_file: use_build_context_synchronously, unused_field, unused_element, unused_import

import 'package:flutter/material.dart';

import '../../models/service_config.dart';
import '../../models/service_request_item.dart';
import 'job_service.dart';          // ✅ correct relative path
import 'matching_screen.dart';     // kept for when you hook up navigation

class ServiceRequestScreen extends StatefulWidget {
  final ServiceConfig config;

  const ServiceRequestScreen({super.key, required this.config});

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  bool _isNow = true;
  DateTime _pickedDate = DateTime.now();
  TimeOfDay _pickedTime = TimeOfDay.now();

  final Map<String, bool> _languagePrefs = {
    "english": false,
    "sinhala": false,
    "tamil": false,
  };

  final TextEditingController _location = TextEditingController();
  final List<ServiceRequestItem> _tasks = [];
  final Set<String> _selectedLabels = {};

  void _toggleNow(bool now) => setState(() => _isNow = now);

  Future<void> _pickTime(BuildContext ctx, StateSetter ss) async {
    final t = await showTimePicker(
      context: ctx,
      initialTime: _pickedTime,
    );
    if (t != null) {
      setState(() => _pickedTime = t);
      ss(() => _pickedTime = t);
    }
  }

  Future<void> _pickSchedule() async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, ss) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _isNow,
                    onChanged: (_) => ss(() => _toggleNow(true)),
                  ),
                  const Text("Now"),
                  const Spacer(),
                  Checkbox(
                    value: !_isNow,
                    onChanged: (_) => ss(() => _toggleNow(false)),
                  ),
                  const Text("Later"),
                ],
              ),
              CalendarDatePicker(
                initialDate: _pickedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                onDateChanged: (d) => ss(() => _pickedDate = d),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _pickTime(ctx, ss),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_pickedTime.format(ctx)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("Done"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: plug in the rest of the UI (service grid, summary, confirm button)
    return const Scaffold(
      body: Center(
        child: Text('ServiceRequestScreen – UI to be completed'),
      ),
    );
  }
}
