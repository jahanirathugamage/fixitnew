// lib/main.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:fixitnew/firebase_options.dart';
import 'package:fixitnew/services/push_notifications.dart';
import 'package:fixitnew/services/notification_router.dart';

// AUTH SCREENS
import 'package:fixitnew/screens/welcome_screen.dart';
import 'package:fixitnew/screens/auth/login_screen.dart';
import 'package:fixitnew/screens/auth/forgot_password.dart';
import 'package:fixitnew/screens/auth/register_select.dart';
import 'package:fixitnew/screens/auth/otp_verification_screen.dart';

// PROFILE SCREENS
import 'package:fixitnew/screens/profile/profile_client_screen.dart';
import 'package:fixitnew/screens/profile/profile_contractor_full_screen.dart';
import 'package:fixitnew/screens/profile/add_provider_screen.dart';

// DASHBOARDS – CLIENT
import 'package:fixitnew/screens/dashboards/home_client.dart';
import 'package:fixitnew/screens/dashboards/client/home_screen.dart';
import 'package:fixitnew/screens/dashboards/client/client_jobs.dart';
import 'package:fixitnew/screens/dashboards/client/change_client_password.dart';
import 'package:fixitnew/screens/dashboards/client/update_client_profile.dart';
import 'package:fixitnew/screens/dashboards/client/client_job_requests.dart';
import 'package:fixitnew/screens/dashboards/client/client_job_details_screen.dart';

// DASHBOARDS – CONTRACTOR
import 'package:fixitnew/screens/dashboards/home_contractor.dart';
import 'package:fixitnew/screens/dashboards/contractor/contractor_account_info.dart';
import 'package:fixitnew/screens/dashboards/contractor/contractor_jobs_screen.dart';
import 'package:fixitnew/screens/dashboards/contractor/contractor_service_providers.dart';
import 'package:fixitnew/screens/dashboards/contractor/change_contractor_password_screen.dart';
import 'package:fixitnew/screens/dashboards/contractor/update_contractor_profile.dart';
import 'package:fixitnew/screens/dashboards/contractor/update_provider_screen.dart';

// DASHBOARDS – PROVIDER
import 'package:fixitnew/screens/dashboards/provider_home_screen.dart';
import 'package:fixitnew/screens/dashboards/provider/provider_jobs.dart';
import 'package:fixitnew/screens/dashboards/provider/job_requests_screen.dart';
import 'package:fixitnew/screens/dashboards/provider/job_details_screen.dart';

// ADMIN SCREENS
import 'package:fixitnew/screens/admin/create_admin_account_screen.dart';
import 'package:fixitnew/screens/admin/admin_settings_screen.dart';
import 'package:fixitnew/screens/admin/admin_account_info_screen.dart';
import 'package:fixitnew/screens/admin/admin_change_password_screen.dart';
import 'package:fixitnew/screens/admin/contractor_approval_detail_screen.dart'
    as admin_detail;
import 'package:fixitnew/screens/admin/contractor_approval_screen.dart';
import 'package:fixitnew/screens/admin/contracting_firms_information_screen.dart'
    as admin_firms;
import 'package:fixitnew/screens/admin/contractor_firm_information_screen.dart'
    as admin_firm_info;

// MATCHING
import 'package:fixitnew/screens/services/matching_screen.dart';

// NEW GENERIC SERVICE REQUEST FLOW
import 'package:fixitnew/screens/services/service_request_screen.dart';
import 'package:fixitnew/screens/services/service_request_wrapper.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // No UI work here.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ Ensure Functions region is set (if you call callable functions)
  FirebaseFunctions.instanceFor(region: 'us-central1');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/service/matching':
        final args = settings.arguments;
        if (args is String && args.trim().isNotEmpty) {
          return MaterialPageRoute(
            builder: (_) => MatchingScreen(jobId: args),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => const _RouteErrorScreen(
            message:
                "Missing or invalid jobId for '/service/matching'.\n\n"
                "Fix:\nNavigator.pushNamed(context, '/service/matching', arguments: jobId);",
          ),
          settings: settings,
        );

      case '/admin/contractor_approval_detail_screen':
        final args = settings.arguments;
        if (args is String && args.trim().isNotEmpty) {
          return MaterialPageRoute(
            builder: (_) =>
                admin_detail.ContractorApprovalDetailScreen(contractorId: args),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => const _RouteErrorScreen(
            message:
                "Missing or invalid contractorId for '/admin/contractor_approval_detail_screen'.\n\n"
                "Fix:\nNavigator.pushNamed(context, '/admin/contractor_approval_detail_screen', arguments: contractorId);",
          ),
          settings: settings,
        );

      // ✅ NEW: Contractor Firm Info detail (Admin)
      case '/admin/contractor_firm_information_screen':
        final args = settings.arguments;
        if (args is String && args.trim().isNotEmpty) {
          return MaterialPageRoute(
            builder: (_) => admin_firm_info.ContractorFirmInformationScreen(
              contractorId: args,
            ),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => const _RouteErrorScreen(
            message:
                "Missing or invalid contractorId for '/admin/contractor_firm_information_screen'.\n\n"
                "Fix:\nNavigator.pushNamed(context, '/admin/contractor_firm_information_screen', arguments: contractorId);",
          ),
          settings: settings,
        );

      // ✅ Client Job Details by jobRequestId
      case '/dashboards/client/job_details':
        final args = settings.arguments;
        if (args is String && args.trim().isNotEmpty) {
          return MaterialPageRoute(
            builder: (_) => ClientJobDetailsScreen(jobId: args),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => const _RouteErrorScreen(
            message:
                "Missing or invalid jobId for '/dashboards/client/job_details'.\n\n"
                "Fix:\nNavigator.pushNamed(context, '/dashboards/client/job_details', arguments: jobId);",
          ),
          settings: settings,
        );

      // ✅ Provider Job Details by jobRequestId
      case '/provider/job_details':
        final args = settings.arguments;
        if (args is String && args.trim().isNotEmpty) {
          return MaterialPageRoute(
            builder: (_) => ProviderJobDetailsScreen(jobId: args),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => const _RouteErrorScreen(
            message:
                "Missing or invalid jobId for '/provider/job_details'.\n\n"
                "Fix:\nNavigator.pushNamed(context, '/provider/job_details', arguments: jobId);",
          ),
          settings: settings,
        );

      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Init routing for notification taps (use the SAME navigatorKey used by MaterialApp)
    NotificationRouter.instance.init(PushNotifications.navigatorKey);

    return MaterialApp(
      title: 'FixIt App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Montserrat',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
      ),
      navigatorKey: PushNotifications.navigatorKey, // ✅ ONLY ONCE
      home: const AuthWrapper(),
      routes: {
        // AUTH
        '/welcome': (_) => const WelcomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/forgot_password': (_) => const ForgotPasswordScreen(),
        '/register_select': (_) => const RegisterSelectScreen(),
        '/otp_verification': (_) => const OtpVerificationScreen(),

        // PROFILE
        '/profile_client': (_) => const ProfileClientScreen(),
        '/profile_contractor_full': (_) => const ProfileContractorFullScreen(),
        '/profile/add_provider_screen': (_) => const AddProviderScreen(),

        // CLIENT DASHBOARD
        '/dashboards/home_client': (_) => const HomeClient(),
        '/dashboards/client/home_screen': (_) => const HomeScreen(),
        '/dashboards/client/client_jobs': (_) => const ClientJobsScreen(),
        '/dashboards/client/client_job_requests': (_) =>
            const ClientJobRequestsScreen(),
        '/dashboards/client/update_client_profile': (_) =>
            const UpdateClientProfile(),
        '/dashboards/client/change_client_password': (_) =>
            const ChangeClientPasswordScreen(),

        // CONTRACTOR DASHBOARD
        '/dashboards/home_contractor': (_) => const HomeContractor(),
        '/dashboards/contractor/contractor_account_info': (_) =>
            const ContractorAccountInfo(),
        '/dashboards/contractor/contractor_jobs_screen': (_) => const ContractorJobsScreen(),
        '/dashboards/contractor/contractor_service_providers': (_) =>
            const ContractorServiceProviders(),
        '/dashboards/contractor/update_provider_screen': (_) =>
            const UpdateProviderScreen(),
        '/dashboards/contractor/change_contractor_password': (_) =>
            const ChangeContractorPasswordScreen(),
        '/dashboards/contractor/update_contractor_profile': (_) =>
            const UpdateContractorProfile(),

        // PROVIDER DASHBOARD
        '/dashboards/provider_home_screen': (_) => const ProviderHomeScreen(),
        '/provider/provider_jobs': (_) => const ProviderJobsScreen(),
        '/provider/job_requests_screen': (_) =>
            const ProviderJobRequestsScreen(),

        // ADMIN
        '/admin/create_admin_account_screen': (_) =>
            const CreateAdminAccountScreen(),
        '/admin/admin_settings_screen': (_) => const AdminSettingsScreen(),
        '/admin/admin_account_info_screen': (_) =>
            const AdminAccountInfoScreen(),
        '/admin/contractor_approval_screen': (_) =>
            const ContractorApprovalScreen(),
        '/admin/contracting_firms_information_screen': (_) =>
            const admin_firms.ContractingFirmsInformationScreen(),
        '/admin/admin_change_password_screen': (_) =>
            const AdminChangePasswordScreen(),

        // SERVICES
        '/service/ac': (_) =>
            ServiceRequestScreen(config: ServiceRequestWrapper.acConfig),
        '/service/plumbing': (_) =>
            ServiceRequestScreen(config: ServiceRequestWrapper.plumbingConfig),
        '/service/electrical': (_) =>
            ServiceRequestScreen(config: ServiceRequestWrapper.electricalConfig),
        '/service/carpentry': (_) =>
            ServiceRequestScreen(config: ServiceRequestWrapper.carpentryConfig),
        '/service/gardening': (_) =>
            ServiceRequestScreen(config: ServiceRequestWrapper.gardeningConfig),
        '/service/pest': (_) => ServiceRequestScreen(
              config: ServiceRequestWrapper.pestControlConfig,
            ),
        '/service/appliances': (_) =>
            ServiceRequestScreen(config: ServiceRequestWrapper.appliancesConfig),
        '/service/cleaning': (_) =>
            ServiceRequestScreen(config: ServiceRequestWrapper.cleaningConfig),
      },
      onGenerateRoute: _onGenerateRoute,
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => _RouteErrorScreen(
            message: "Unknown route: ${settings.name}",
          ),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<Widget> _getUserHome(User user) async {
    final uid = user.uid;

    // ✅ Refresh user to ensure emailVerified is up-to-date
    await user.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;

    if (refreshedUser == null) return const WelcomeScreen();

    if (!refreshedUser.emailVerified) {
      return const VerifyEmailScreen();
    }

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!userDoc.exists) return const WelcomeScreen();

    // ✅ Subscribe user to push notifications
    await PushNotifications.initForUser(uid);

    final role = userDoc.data()?['role'];

    if (role == 'client') {
      final profileComplete = userDoc.data()?['profile_completed'] ?? false;
      if (!profileComplete) return const ProfileClientScreen();
      return const HomeClient();
    }

    if (role == 'provider') {
      return const ProviderHomeScreen();
    }

    if (role == 'contractor') {
      final contractorDoc = await FirebaseFirestore.instance
          .collection('contractors')
          .doc(uid)
          .get();

      if (!contractorDoc.exists) {
        return const ProfileContractorFullScreen();
      }

      final data = contractorDoc.data() ?? {};
      final approvalStatus = (data['approvalStatus'] ?? '').toString();

      if (approvalStatus == 'approved') {
        return const HomeContractor();
      }

      if (approvalStatus == 'rejected') {
        final reason = (data['rejectionReason'] ?? '').toString();
        return ContractorRejectedScreen(reason: reason);
      }

      return const ContractorPendingApprovalScreen();
    }

    return const WelcomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snap.hasData) return const WelcomeScreen();

        final user = snap.data!;
        return FutureBuilder<Widget>(
          future: _getUserHome(user),
          builder: (context, roleSnap) {
            if (!roleSnap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return roleSnap.data!;
          },
        );
      },
    );
  }
}

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Verify Email',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email_outlined, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text('Please verify your email to continue.'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                await user?.sendEmailVerification();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Verification email sent')),
                );
              },
              child: const Text('Resend Verification'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}

class ContractorPendingApprovalScreen extends StatelessWidget {
  const ContractorPendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pending Approval',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_top, size: 70, color: Colors.black),
            const SizedBox(height: 14),
            const Text(
              'Your contractor application is under review.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'You will be able to log in once an admin approves your firm.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
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

class ContractorRejectedScreen extends StatelessWidget {
  final String reason;

  const ContractorRejectedScreen({super.key, required this.reason});

  @override
  Widget build(BuildContext context) {
    final cleanReason =
        reason.trim().isEmpty ? 'No reason was provided.' : reason.trim();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Application Rejected',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel, size: 70, color: Colors.black),
            const SizedBox(height: 14),
            const Text(
              'Your contractor application was rejected.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'Reason: $cleanReason',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
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

class _RouteErrorScreen extends StatelessWidget {
  final String message;

  const _RouteErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Navigation Error',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
      ),
    );
  }
}
