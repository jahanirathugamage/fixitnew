import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../controllers/admin/contractor_firm_information_controller.dart';
import '../../models/admin/contractor_firm_information.dart';

class ContractorFirmInformationScreen extends StatelessWidget {
  final String contractorId;

  const ContractorFirmInformationScreen({
    super.key,
    required this.contractorId,
  });

  static const _titleStyle = TextStyle(
    color: Colors.black,
    fontWeight: FontWeight.w700,
  );

  static const _sectionTitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.black,
  );

  static const _subSectionTitleStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Colors.black,
  );

  static const _labelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  static const _valueStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.black,
  );

  Uint8List? _decodeBase64Image(String raw) {
    if (raw.trim().isEmpty) return null;

    var s = raw.trim();

    // handle data:image/...;base64,
    final commaIndex = s.indexOf(',');
    if (s.startsWith('data:') && commaIndex != -1) {
      s = s.substring(commaIndex + 1);
    }

    s = s.replaceAll(RegExp(r'\s+'), '');

    try {
      return base64Decode(s);
    } catch (_) {
      return null;
    }
  }

  Widget _kvLine(String label, String value) {
    final v = value.trim().isEmpty ? '—' : value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: _valueStyle,
          children: [
            TextSpan(text: '$label ', style: _labelStyle),
            TextSpan(text: v, style: _valueStyle),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Divider(height: 1),
      );

  bool _hasMethod(ContractorFirmInformation info, String method) {
    return info.verificationMethods
        .map((e) => e.trim().toLowerCase())
        .contains(method.trim().toLowerCase());
  }

  Widget _checkRow(String label, bool checked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Checkbox(
            value: checked,
            onChanged: null,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ContractorFirmInformationController();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Firm Info', style: _titleStyle),
        centerTitle: true,
      ),
      body: StreamBuilder<ContractorFirmInformation?>(
        stream: controller.watch(contractorId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(
              child: Text(
                'Error: ${snap.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final info = snap.data;
          if (info == null) {
            return const Center(
              child: Text(
                'Contractor details not found.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final certBytes = _decodeBase64Image(info.businessCertBase64);

          final otherChecked = _hasMethod(info, 'Other');
          final otherTextValue =
              info.otherMethodText.trim().isNotEmpty ? info.otherMethodText : '';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Contractor Details', style: _sectionTitleStyle),
                const SizedBox(height: 10),
                _kvLine('Name:', info.fullName),
                _kvLine('NIC No.', info.nic),
                _kvLine('Contact No.', info.personalContact),

                _divider(),

                const Text('Company Details', style: _sectionTitleStyle),
                const SizedBox(height: 10),
                _kvLine('Company Name:', info.companyName),
                _kvLine('Address line 1:', info.companyAddressLine1),
                _kvLine('Address line 2:', info.companyAddressLine2),
                _kvLine('City:', info.companyCity),
                _kvLine('Email:', info.companyEmail),
                _kvLine('Contact No.', info.companyContact),
                _kvLine('BR No.', info.businessRegNo),

                const SizedBox(height: 18),

                Container(
                  width: double.infinity,
                  height: 280,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E5E5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: certBytes == null
                      ? const Center(
                          child: Text(
                            'Business\nregistration\ncertification image',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Image.memory(
                            certBytes,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),

                _divider(),

                const Text('Service Provider Verification',
                    style: _sectionTitleStyle),
                const SizedBox(height: 12),

                const Text('Identity & Legal Verification',
                    style: _subSectionTitleStyle),
                const SizedBox(height: 8),
                _checkRow('NIC Verification', _hasMethod(info, 'NIC Verification')),
                _checkRow('Police Clearance Report',
                    _hasMethod(info, 'Police Clearance Report')),

                const SizedBox(height: 12),

                const Text('Address & Residency Verification',
                    style: _subSectionTitleStyle),
                const SizedBox(height: 8),
                _checkRow('Proof of Address Verification',
                    _hasMethod(info, 'Proof of Address Verification')),

                const SizedBox(height: 12),

                const Text('Background & Character Verification',
                    style: _subSectionTitleStyle),
                const SizedBox(height: 8),
                _checkRow(
                  'Grama Niladhari Character Certificate',
                  _hasMethod(info, 'Grama Niladhari Character Certificate'),
                ),
                _checkRow(
                  'Previous Employer Reference Checks',
                  _hasMethod(info, 'Previous Employer Reference Checks'),
                ),
                _checkRow(
                  'Interview Screening Process',
                  _hasMethod(info, 'Interview Screening Process'),
                ),

                const SizedBox(height: 12),

                const Text('Skills & Qualification Verification',
                    style: _subSectionTitleStyle),
                const SizedBox(height: 8),
                _checkRow(
                  'Trade Qualification Certificates (Ex. NVQ)',
                  _hasMethod(info, 'Trade Qualification Certificates (Ex. NVQ)'),
                ),
                _checkRow(
                  'On-Site Skill Assessment',
                  _hasMethod(info, 'On-Site Skill Assessment'),
                ),

                const SizedBox(height: 12),

                const Text('Performance & Ongoing Monitoring',
                    style: _subSectionTitleStyle),
                const SizedBox(height: 8),
                _checkRow(
                  'Probation Period Monitoring',
                  _hasMethod(info, 'Probation Period Monitoring'),
                ),
                _checkRow(
                  'Workplace Safety & Conduct Briefing',
                  _hasMethod(info, 'Workplace Safety & Conduct Briefing'),
                ),
                _checkRow(
                  'Continual Performance Review',
                  _hasMethod(info, 'Continual Performance Review'),
                ),

                const SizedBox(height: 12),

                const Text('Other Methods', style: _subSectionTitleStyle),
                const SizedBox(height: 8),
                _checkRow('Other', otherChecked),
                const SizedBox(height: 6),
                TextField(
                  enabled: false,
                  controller: TextEditingController(text: otherTextValue),
                  decoration: InputDecoration(
                    hintText: 'Some other thing',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Colors.black26, width: 1),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}
