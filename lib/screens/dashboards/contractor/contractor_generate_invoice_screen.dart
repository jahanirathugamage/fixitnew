// lib/screens/dashboards/contractor/contractor_generate_invoice_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:fixitnew/backend/api_client.dart';

class ContractorGenerateInvoiceScreen extends StatefulWidget {
  final String jobId;
  const ContractorGenerateInvoiceScreen({super.key, required this.jobId});

  @override
  State<ContractorGenerateInvoiceScreen> createState() =>
      _ContractorGenerateInvoiceScreenState();
}

class _ContractorGenerateInvoiceScreenState
    extends State<ContractorGenerateInvoiceScreen> {
  bool _loading = false;
  final TextEditingController _note = TextEditingController();

  File? _pickedImageFile;
  String? _uploadedUrl;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickInvoiceImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (xFile == null) return;

    setState(() {
      _pickedImageFile = File(xFile.path);
      _uploadedUrl = null;
    });
  }

  Future<String> _uploadInvoiceImage({
    required String jobId,
    required File file,
  }) async {
    final storage = FirebaseStorage.instance;

    // ✅ storage path
    final ref = storage
        .ref()
        .child('invoices')
        .child(jobId)
        .child('invoice_${DateTime.now().millisecondsSinceEpoch}.jpg');

    final meta = SettableMetadata(contentType: 'image/jpeg');

    final task = await ref.putFile(file, meta);
    final url = await task.ref.getDownloadURL();
    return url;
  }

  Future<void> _submit() async {
    if (_pickedImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload the invoice image.")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final url = await _uploadInvoiceImage(
        jobId: widget.jobId,
        file: _pickedImageFile!,
      );

      setState(() => _uploadedUrl = url);

      await ApiClient.postJson(
        "/api/invoice-create",
        body: {
          "jobId": widget.jobId,
          "note": _note.text.trim(),
          "invoiceImageUrl": url,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invoice sent to client.")),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _primaryButton({
    required String text,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: "Montserrat",
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _outlineButton({
    required String text,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.black),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: "Montserrat",
            fontWeight: FontWeight.w800,
            color: Colors.black,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _pickedImageFile != null;

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
          "Generate Invoice",
          style: TextStyle(fontFamily: "Montserrat", fontWeight: FontWeight.w800),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Upload Invoice Image",
              style: TextStyle(
                fontFamily: "Montserrat",
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),

            // ✅ Upload card (matches your minimal UI)
            GestureDetector(
              onTap: _loading ? null : _pickInvoiceImage,
              child: Container(
                width: double.infinity,
                height: 170,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black12),
                  color: Colors.white,
                ),
                child: hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _pickedImageFile!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.upload_file, size: 44, color: Colors.black),
                          SizedBox(height: 10),
                          Text(
                            "Tap to upload invoice image",
                            style: TextStyle(
                              fontFamily: "Montserrat",
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "PNG / JPG",
                            style: TextStyle(
                              fontFamily: "Montserrat",
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 14),

            if (hasImage) ...[
              _outlineButton(
                text: "Change Image",
                onPressed: _loading ? null : _pickInvoiceImage,
              ),
              const SizedBox(height: 14),
            ],

            const Text(
              "Note (optional)",
              style: TextStyle(
                fontFamily: "Montserrat",
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _note,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Add invoice note...",
                hintStyle: const TextStyle(
                  fontFamily: "Montserrat",
                  fontWeight: FontWeight.w600,
                  color: Colors.black38,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const Spacer(),

            _primaryButton(
              text: _loading ? "Sending..." : "Send Invoice",
              onPressed: _loading ? null : _submit,
            ),

            const SizedBox(height: 6),

            if (_uploadedUrl != null)
              const Text(
                "Invoice uploaded successfully.",
                style: TextStyle(
                  fontFamily: "Montserrat",
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
