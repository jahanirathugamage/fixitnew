// lib/screens/dashboards/contractor/contractor_service_providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fixitnew/controllers/contractor/contractor_providers_controller.dart';

// ✅ reusable contractor bottom nav
import 'package:fixitnew/widgets/nav/contractor_bottom_nav.dart';

class ContractorServiceProviders extends StatefulWidget {
  const ContractorServiceProviders({super.key});

  @override
  State<ContractorServiceProviders> createState() =>
      _ContractorServiceProvidersState();
}

class _ContractorServiceProvidersState extends State<ContractorServiceProviders> {
  final _controller = ContractorProvidersController();

  static const String _addProviderRoute = "/profile/add_provider_screen";
  static const String _updateProviderRoute =
      "/dashboards/contractor/update_provider_screen";

  static const String _contractorJobsRoute =
      "/dashboards/contractor/contractor_jobs";

  Future<void> _safeBack() async {
    final popped = await Navigator.of(context).maybePop();
    if (!popped && mounted) {
      Navigator.of(context).pushReplacementNamed(_contractorJobsRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contractorId = _controller.getCurrentContractorId();

    if (contractorId == null) {
      return const Scaffold(
        body: Center(child: Text("Not logged in")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 22),
                    onPressed: _safeBack,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 22,
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Service Providers',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 22),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Add Provider Row
                    InkWell(
                      onTap: () => Navigator.pushNamed(context, _addProviderRoute),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Add Service Provider',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1, thickness: 1),

                    // Providers list
                    StreamBuilder<QuerySnapshot>(
                      stream: _controller.providersStream(contractorId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              "No service providers found.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        return Column(
                          children: snapshot.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;

                            final first =
                                (data['firstName'] ?? '').toString().trim();
                            final last = (data['lastName'] ?? '').toString().trim();
                            final name = "$first $last".trim();

                            // NOTE:
                            // Your controller saves profileImageBase64, not a URL.
                            // So we don't try Image.network here.
                            return _buildProviderRow(
                              providerId: doc.id,
                              name: name.isEmpty ? 'Unnamed Provider' : name,
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const ContractorBottomNav(currentIndex: 1),
    );
  }

  Widget _buildProviderRow({
    required String providerId,
    required String name,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // avatar placeholder (since you store base64, not URL)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 34,
                  height: 34,
                  color: const Color(0xFFE6E6E6),
                  child: const Icon(
                    Icons.person,
                    size: 18,
                    color: Color(0xFF9A9A9A),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12.8,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        SizedBox(
                          height: 26,
                          width: 86,
                          child: ElevatedButton(
                            onPressed: () {
                              // ✅ pass only providerId (controller uses auth contractor uid)
                              Navigator.pushNamed(
                                context,
                                _updateProviderRoute,
                                arguments: {"providerId": providerId},
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: const Text(
                              'Manage',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        SizedBox(
                          height: 26,
                          width: 86,
                          child: OutlinedButton(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);

                              final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete Provider'),
                                      content: const Text(
                                        'Are you sure you want to delete this provider?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(true),
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ) ??
                                  false;

                              if (!confirm || !mounted) return;

                              final contractorId =
                                  _controller.getCurrentContractorId();
                              if (contractorId == null) {
                                messenger.showSnackBar(
                                  const SnackBar(content: Text("Not logged in")),
                                );
                                return;
                              }

                              final errorMessage = await _controller.deleteProvider(
                                contractorId: contractorId,
                                providerId: providerId,
                              );

                              if (!mounted) return;

                              if (errorMessage == null) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text("Provider deleted successfully"),
                                  ),
                                );
                              } else {
                                messenger.showSnackBar(
                                  SnackBar(content: Text(errorMessage)),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.zero,
                              side: const BorderSide(
                                color: Colors.black,
                                width: 1.1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: const Text(
                              'Delete',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 11.5,
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
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
      ],
    );
  }
}
