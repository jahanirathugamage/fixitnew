// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// class ProviderJobRequestsScreen extends StatelessWidget {
//   const ProviderJobRequestsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final user = FirebaseAuth.instance.currentUser;

//     if (user == null) {
//       return const Scaffold(
//         body: Center(child: Text("Not logged in.")),
//       );
//     }

//     final providerUid = user.uid;

//     // Provider can see pending + held jobs where they were matched
//     final query = FirebaseFirestore.instance
//         .collection('jobRequest')
//         .where('matchedProviderIds', arrayContains: providerUid)
//         .where('status', whereIn: ['pending', 'held']);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Job Requests"),
//       ),
//       body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//         stream: query.snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Padding(
//               padding: const EdgeInsets.all(16),
//               child: Text("Error: ${snapshot.error}"),
//             );
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final docs = snapshot.data?.docs ?? [];
//           if (docs.isEmpty) {
//             return const Center(
//               child: Text("No job requests yet."),
//             );
//           }

//           return ListView.separated(
//             padding: const EdgeInsets.all(12),
//             itemCount: docs.length,
//             separatorBuilder: (_, __) => const SizedBox(height: 10),
//             itemBuilder: (context, i) {
//               final doc = docs[i];
//               final data = doc.data();

//               final jobId = doc.id;
//               final category = (data['category'] ?? '').toString();
//               final status = (data['status'] ?? '').toString();
//               final locationText = (data['locationText'] ?? '').toString();

//               Timestamp? scheduledDate;
//               if (data['scheduledDate'] is Timestamp) {
//                 scheduledDate = data['scheduledDate'] as Timestamp;
//               }

//               Timestamp? startAt;
//               if (data['startAt'] is Timestamp) {
//                 startAt = data['startAt'] as Timestamp;
//               }

//               final totalDurationMins = data['totalDurationMins'];

//               final displayTime = (startAt ?? scheduledDate)?.toDate();

//               return Card(
//                 child: ListTile(
//                   title: Text(
//                     category.isEmpty ? "Job Request" : category,
//                     style: const TextStyle(fontWeight: FontWeight.w600),
//                   ),
//                   subtitle: Padding(
//                     padding: const EdgeInsets.only(top: 6),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text("Job ID: $jobId"),
//                         if (displayTime != null) Text("Start: $displayTime"),
//                         if (locationText.isNotEmpty) Text("Address: $locationText"),
//                         Text("Status: $status"),
//                         if (totalDurationMins != null) Text("Duration: $totalDurationMins mins"),
//                       ],
//                     ),
//                   ),
//                   trailing: const Icon(Icons.chevron_right),
//                   onTap: () {
//                     // For now, just show a basic dialog. Later we can navigate to a details page.
//                     showDialog(
//                       context: context,
//                       builder: (_) => AlertDialog(
//                         title: const Text("Job Request"),
//                         content: Text("Open details for jobId: $jobId"),
//                         actions: [
//                           TextButton(
//                             onPressed: () => Navigator.pop(context),
//                             child: const Text("OK"),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
