// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'firebase_options.dart';

// AUTH SCREENS
import 'screens/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/forgot_password.dart';
import 'screens/auth/register_select.dart';
import 'screens/auth/otp_verification_screen.dart';

// PROFILE SCREENS
import 'screens/profile/profile_client_screen.dart';
import 'screens/profile/profile_contractor_full_screen.dart';
import 'screens/profile/add_provider_screen.dart';

// DASHBOARDS
import 'screens/dashboards/home_client.dart';
import 'screens/dashboards/client/home_screen.dart';
import 'screens/dashboards/client/client_profile.dart';
import 'screens/dashboards/client/client_services.dart';
import 'screens/dashboards/client/client_jobs.dart';
import 'screens/dashboards/client/client_bank_details.dart';
import 'screens/dashboards/client/change_client_password.dart';
import 'screens/dashboards/client/update_client_profile.dart';

import 'screens/dashboards/home_contractor.dart';
import 'screens/dashboards/contractor/contractor_account_info.dart';
import 'screens/dashboards/contractor/contractor_profile.dart';
import 'screens/dashboards/contractor/contractor_jobs.dart';
import 'screens/dashboards/contractor/contractor_service_providers.dart';
import 'screens/dashboards/contractor/contractor_bank_details.dart';
import 'screens/dashboards/contractor/change_contractor_password_screen.dart';
import 'screens/dashboards/contractor/update_contractor_profile.dart';

import 'screens/dashboards/provider/update_provider_screen.dart';
import 'screens/dashboards/provider_home_screen.dart';

// ADMIN SCREENS
import 'screens/admin/create_admin_account_screen.dart';
import 'screens/admin/admin_settings_screen.dart';
import 'screens/admin/contractor_approval_screen.dart';
import 'screens/admin/contractor_approval_detail_screen.dart';
import 'screens/admin/admin_account_info_screen.dart';
import 'screens/admin/contracting_firms_information_screen.dart';
import 'screens/admin/admin_change_password_screen.dart';

// SERVICES SCREENS
import 'screens/services/ac_screen.dart';
import 'screens/services/plumbing_screen.dart';
import 'screens/services/electrical_screen.dart';
import 'screens/services/carpentry_screen.dart';
import 'screens/services/cleaning_screen.dart';
import 'screens/services/gardening_screen.dart';
import 'screens/services/pestcontrol_screen.dart';
import 'screens/services/appliances_screen.dart';
import 'screens/services/matching_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFunctions.instanceFor(region: 'us-central1');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FixIt App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Montserrat',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
      ),
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
        '/dashboards/client/client_profile': (_) => const ClientProfile(),
        '/dashboards/client/client_services': (_) => const ClientServices(),
        '/dashboards/client/client_jobs': (_) => const ClientJobs(),
        '/dashboards/client/client_bank_details': (_) => const ClientBankDetails(),
        '/dashboards/client/update_client_profile': (_) => const UpdateClientProfile(),
        '/dashboards/client/change_client_password': (_) => const ChangeClientPasswordScreen(),

        // CONTRACTOR DASHBOARD
        '/dashboards/home_contractor': (_) => const HomeContractor(),
        '/dashboards/contractor/contractor_account_info': (_) => const ContractorAccountInfo(),
        '/dashboards/contractor/contractor_profile': (_) => const ContractorProfile(),
        '/dashboards/contractor/contractor_jobs': (_) => const ContractorJobs(),
        '/dashboards/contractor/contractor_service_providers': (_) => const ContractorServiceProviders(),
        '/dashboards/contractor/contractor_bank_details': (_) => const ContractorBankDetails(),
        '/dashboards/contractor/change_contractor_password': (_) => const ChangeContractorPasswordScreen(),
        '/dashboards/contractor/update_contractor_profile': (_) => const UpdateContractorProfile(),

        // PROVIDER DASHBOARD
        '/dashboards/home_provider_screen': (_) => const ProviderHomeScreen(),
        '/dashboards/provider/update_profile': (_) => const UpdateProviderScreen(),

        // ADMIN
        '/admin/create_admin_account_screen': (_) => const CreateAdminAccountScreen(),
        '/admin/admin_settings_screen': (_) => const AdminSettingsScreen(),
        '/admin/contractor_approval_screen': (_) => const ContractorApprovalScreen(),
        '/admin/contractor_approval_detail_screen': (_) => const ContractorApprovalDetailScreen(contractorId: ''),
        '/admin/admin_account_info_screen': (_) => const AdminAccountInfoScreen(),
        '/admin/contracting_firms_information_screen': (_) => const ContractingFirmsInformationScreen(),
        '/admin/admin_change_password_screen': (_) => const AdminChangePasswordScreen(),

        // SERVICES
        '/services/ac_screen': (_) => const ACScreen(),
        '/services/plumbing_screen': (_) => const PlumbingScreen(),
        '/services/electrical_screen': (_) => const ElectricalScreen(),
        '/services/carpentry_screen': (_) => const CarpentryScreen(),
        '/services/cleaning_screen': (_) => const CleaningScreen(),
        '/services/gardening_screen': (_) => const GardeningScreen(),
        '/services/pestcontrol_screen': (_) => const PestControlScreen(),
        '/services/appliances_screen': (_) => const AppliancesScreen(),
        '/services/matching_screen': (_) => const MatchingScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<Widget> _getUserHome(User user) async {
    final uid = user.uid;

    if (!user.emailVerified) {
      return const VerifyEmailScreen();
    }

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!userDoc.exists) return const WelcomeScreen();

    final role = userDoc['role'];
    final profileComplete = userDoc['profile_completed'] ?? false;

    if (!profileComplete) {
      if (role == "client") return const ProfileClientScreen();
      if (role == "contractor") return const ProfileContractorFullScreen();
    }

    switch (role) {
      case 'contractor':
        return const HomeContractor();
      case 'provider':
        return const ProviderHomeScreen();
      default:
        return const WelcomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (!snap.hasData) return const WelcomeScreen();
        final user = snap.data!;
        return FutureBuilder(
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
        title: const Text("Verify Email", style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email_outlined, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text("Please verify your email to continue."),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                await user?.sendEmailVerification();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Verification email sent")),
                );
              },
              child: const Text("Resend Verification"),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }
}
