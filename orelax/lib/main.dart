import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/Welcome/welcome_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/Home/home_screen.dart';
import 'screens/Home/report_screen.dart';
import 'screens/Home/profile_screen.dart';
import 'screens/chat/chat_screen.dart';

import 'screens/security/access_control_screen.dart';
import 'screens/security/visitors_screen.dart';
import 'screens/security/alerts_screen.dart';
import 'screens/security/access_logs_screen.dart';
import 'screens/maintenance/work_orders_screen.dart';
import 'screens/maintenance/pending_requests_screen.dart';
import 'screens/maintenance/schedule_screen.dart';
import 'screens/facilities_manager/facilities_list_screen.dart';
import 'screens/facilities_manager/facility_registrations_screen.dart';
import 'screens/facilities_manager/facility_details_screen.dart';
import 'screens/facilities_manager/facility_payments_screen.dart';
import 'screens/resident/helping_staff/helping_staff_home_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const OrelaxApp());
}

class OrelaxApp extends StatelessWidget {
  const OrelaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MaterialApp(
        title: 'ORELAX',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF034808),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF034808),
            secondary: Color(0xFFFFD700),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF034808),
            foregroundColor: Colors.white,
          ),
          useMaterial3: true,
        ),
        home: const WelcomeScreen(),
        routes: {
          '/auth': (_) => const AuthWrapper(),
          '/onboarding': (_) => const OnboardingScreen(),
          '/role-based-home': (_) => const HomeScreen(),
          '/home': (_) => const HomeScreen(),
          '/chat': (_) => const ChatScreen(),
          '/report': (_) => const ReportScreen(),
          '/notifications': (_) => const _ComingSoonScreen(title: 'Notifications'),
          '/profile': (_) => const ProfileScreen(),

          // Resident Facility Detail Screens
          '/facility/pool': (_) => const FacilityDetailsScreen(facilityName: 'Pool'),
          '/facility/party-room': (_) => const FacilityDetailsScreen(facilityName: 'Party Room'),
          '/facility/nursery': (_) => const FacilityDetailsScreen(facilityName: 'Nursery'),
          '/facility/gym': (_) => const FacilityDetailsScreen(facilityName: 'Gym'),

          // Resident shortcuts (Coming Soon)
          '/feed': (_) => const _ComingSoonScreen(title: 'Community Feed'),
          '/events': (_) => const _ComingSoonScreen(title: 'Events'),
          '/bookings': (_) => const _ComingSoonScreen(title: 'Bookings'),
          '/maintenance-request':
              (_) => const _ComingSoonScreen(title: 'Maintenance Request'),
          '/facilities': (_) => const _ComingSoonScreen(title: 'Facilities'),

          // Security (real screens — opened from home)
          '/access-control': (_) => const AccessControlScreen(),
          '/visitors': (_) => const VisitorsScreen(),
          '/alerts': (_) => const AlertsScreen(),
          '/access-logs': (_) => const AccessLogsScreen(),

          // Maintenance (real screens — opened from home)
          '/work-orders': (_) => const WorkOrdersScreen(),
          '/pending-requests': (_) => const PendingRequestsScreen(),
          '/schedule': (_) => const MaintenanceScheduleScreen(),

          // Facilities manager screens
          '/fm-facilities': (_) => const FacilitiesListScreen(),
          '/fm-registrations': (_) => const FacilityRegistrationsScreen(),
          '/fm-facility-details': (_) => const FacilityDetailsScreen(facilityName: '',),
          '/fm-payments': (_) => const FacilityPaymentsScreen(),

          // Placeholders
          '/all-services': (_) => const _ComingSoonScreen(title: 'All Services'),
          '/childcare': (_) => const _ComingSoonScreen(title: 'Childcare'),
          '/helping-staff': (_) => const HelpingStaffScreen(),
          '/manage-accounts':
              (_) => const _ComingSoonScreen(title: 'Manage Accounts'),
          '/security-management':
              (_) => const _ComingSoonScreen(title: 'Security Management'),
          '/monitoring': (_) => const _ComingSoonScreen(title: 'Monitoring'),
        },
      ),
    );
  }
}

class _ComingSoonScreen extends StatelessWidget {
  final String title;

  const _ComingSoonScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF034808),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.build,
              size: 80,
              color: const Color(0xFF034808).withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              '$title — Coming Soon',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This feature is under development',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}