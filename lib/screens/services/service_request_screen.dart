// lib/screens/services/service_request_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import '../../models/service_config.dart';
import '../../models/service_request_item.dart';
import '../../controllers/service_request_controller.dart';
import 'matching_screen.dart';

class ServiceRequestScreen extends StatefulWidget {
  final ServiceConfig config;

  const ServiceRequestScreen({super.key, required this.config});

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  final ServiceRequestController _controller = ServiceRequestController();

  // --- top bar state ---
  bool isRequestNowSelected = true;
  final TextEditingController locationController = TextEditingController();

  // Schedule sheet state
  bool _isNowOptionSelected = true; // true = Now, false = Later
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // Language preference sheet state
  bool _englishSelected = false;
  bool _sinhalaSelected = false;
  bool _tamilSelected = false;

  // Selected service tasks (by label)
  final Set<String> _selectedServices = {};

  @override
  void dispose() {
    locationController.dispose();
    super.dispose();
  }

  // ---------- SERVICE SELECTION (ICON BOXES) ----------

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

  // ---------- REQUEST TIME SHEET ----------

  void _onRequestNowPressed() {
    setState(() {
      isRequestNowSelected = true;
    });
    _openScheduleBottomSheet();
  }

  Future<void> _selectTime(
    BuildContext context,
    StateSetter modalSetState,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
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
      setState(() {
        _selectedTime = picked;
      });
      modalSetState(() {
        _selectedTime = picked;
      });
    }
  }

  void _openScheduleBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter modalSetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
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
                        'Schedule it',
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
                          padding: const EdgeInsets.only(
                            left: 24,
                            right: 24,
                            bottom: 8,
                          ),
                          children: [
                            // Now
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isNowOptionSelected = true;
                                });
                                modalSetState(() {
                                  _isNowOptionSelected = true;
                                });
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 28,
                                    color: Colors.black,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Now',
                                          style: TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Book a fix, watch live, stay assured',
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
                                  const SizedBox(width: 12),
                                  Icon(
                                    _isNowOptionSelected
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    size: 22,
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Later
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isNowOptionSelected = false;
                                });
                                modalSetState(() {
                                  _isNowOptionSelected = false;
                                });
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.event,
                                    size: 28,
                                    color: Colors.black,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Later',
                                          style: TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Book with trust, relax with ease',
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
                                  const SizedBox(width: 12),
                                  Icon(
                                    !_isNowOptionSelected
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    size: 22,
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Calendar + time
                            Container(
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.black, width: 1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
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
                                        initialDate: _selectedDate,
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(
                                          const Duration(days: 365),
                                        ),
                                        onDateChanged: (date) {
                                          setState(() {
                                            _selectedDate = date;
                                          });
                                          modalSetState(() {
                                            _selectedDate = date;
                                          });
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
                                          onTap: () => _selectTime(
                                            sheetContext,
                                            modalSetState,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Colors.grey.shade400,
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  _selectedTime
                                                      .format(sheetContext),
                                                  style: const TextStyle(
                                                    fontFamily: 'Montserrat',
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(
                                                  Icons.keyboard_arrow_down,
                                                  size: 18,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 16.0,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
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

  // ---------- PREFERENCES SHEET FOR "OTHER" ----------

  void _onOtherPressed() {
    setState(() {
      isRequestNowSelected = false;
    });
    _openPreferencesBottomSheet();
  }

  void _openPreferencesBottomSheet() {
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                          ),
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
                                setState(() {
                                  _englishSelected = val;
                                });
                                modalSetState(() {
                                  _englishSelected = val;
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            _LanguageCheckboxRow(
                              label: 'Sinhala',
                              value: _sinhalaSelected,
                              onChanged: (val) {
                                setState(() {
                                  _sinhalaSelected = val;
                                });
                                modalSetState(() {
                                  _sinhalaSelected = val;
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            _LanguageCheckboxRow(
                              label: 'Tamil',
                              value: _tamilSelected,
                              onChanged: (val) {
                                setState(() {
                                  _tamilSelected = val;
                                });
                                modalSetState(() {
                                  _tamilSelected = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 16.0,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
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

  // ---------- REQUEST SUMMARY SHEET (CONTINUE BUTTON) ----------

  int _getPriceForService(String label) {
    final opt = widget.config.services.firstWhere(
      (s) => s.label == label,
      orElse: () => widget.config.services.first,
    );
    return opt.price;
  }

  void _onContinuePressed() {
    if (locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your location.')),
      );
      return;
    }
    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one service task.'),
        ),
      );
      return;
    }
    _openRequestSummaryBottomSheet();
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
            
            final int platformFee = (serviceTotal * 0.20).round();
            
            final int totalAmount =
                serviceTotal + visitationFee + platformFee;

            void updateQuantity(int index, int delta) {
              modalSetState(() {
                final item = items[index];

                // Limit quantity between 1 and 3
                if (delta > 0 && item.quantity >= 3) return;

                item.quantity += delta;

                // If quantity goes to 0, remove that item
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

            TextStyle headerStyle = const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            );

            TextStyle valueStyle = const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            );

            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Service Task',
                                    style: headerStyle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 70,
                                  child: Center(
                                    child: Text('Qty', style: headerStyle),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 80,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text('Price', style: headerStyle),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            GestureDetector(
                                              onTap: () =>
                                                  updateQuantity(index, -1),
                                              child: Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: Colors.black,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.remove,
                                                    size: 16,
                                                  ),
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
                                              onTap: () =>
                                                  updateQuantity(index, 1),
                                              child: Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: Colors.black,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.add,
                                                    size: 16,
                                                  ),
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
                                            style: valueStyle,
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
                            const SizedBox(height: 24),
                            const Text(
                              'Payment Summary',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '* Please note that if the job was not completed, you will only need to pay the platform fee and visitation fee.',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
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
                                  style: valueStyle,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  'Visitation Fee',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'LKR 350',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Platform Fee',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'LKR $platformFee',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    modalSetState(() {
                                      isSaving = true;
                                    });

                                    final DateTime scheduledAt = DateTime(
                                      _selectedDate.year,
                                      _selectedDate.month,
                                      _selectedDate.day,
                                      _selectedTime.hour,
                                      _selectedTime.minute,
                                    );

                                    final List<String> languages = [
                                      if (_englishSelected) 'english',
                                      if (_sinhalaSelected) 'sinhala',
                                      if (_tamilSelected) 'tamil',
                                    ];

                                    try {
                                      // NOTE: backend name is still createPlumbingJob,
                                      // but this now works for ANY category because we
                                      // pass the selected items & metadata.
                                      await _controller.createPlumbingJob(
                                        location: locationController.text.trim(),
                                        isNow: _isNowOptionSelected,
                                        scheduledAt: scheduledAt,
                                        languages: languages,
                                        items: items,
                                        visitationFee: visitationFee,
                                        category: widget.config.category,
                                      );

                                      modalSetState(() {
                                        isSaving = false;
                                      });

                                      if (!mounted) return;

                                      Navigator.of(sheetContext).pop();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const MatchingScreen(),
                                        ),
                                      );
                                    } catch (e) {
                                      modalSetState(() {
                                        isSaving = false;
                                      });

                                      if (!mounted) return;

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to create job: $e',
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

  // ---------- MAIN BUILD ----------

  @override
  Widget build(BuildContext context) {
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
                      'Request a Service',
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
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: RequestTypeButton(
                              label: 'Request time',
                              isSelected: isRequestNowSelected,
                              onTap: _onRequestNowPressed,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RequestTypeButton(
                              label: 'Languages',
                              isSelected: !isRequestNowSelected,
                              onTap: _onOtherPressed,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
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
                            borderSide:
                                BorderSide(color: Colors.black, width: 1),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide:
                                BorderSide(color: Colors.black, width: 1),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide:
                                BorderSide(color: Colors.black, width: 2),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
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
                        itemCount: widget.config.services.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          childAspectRatio: 0.85,
                        ),
                        itemBuilder: (context, index) {
                          final option = widget.config.services[index];
                          return ServiceOptionCard(
                            icon: option.icon,
                            label: option.label,
                            isSelected:
                                _selectedServices.contains(option.label),
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

// ---------- SHARED WIDGETS ----------

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

// new class requestTypeButton
class RequestTypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const RequestTypeButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRequestLabel = label.toLowerCase().contains('request');

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
            mainAxisSize: MainAxisSize.min, // <- don't force full width
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isRequestLabel ? Icons.access_time : Icons.filter_list,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              // 🔑 Flexible avoids overflow when space is tight
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
  
