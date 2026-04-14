import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/facility_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/employee_provider.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/Welcome/welcome_screen.dart';
import 'screens/onboarding_screen.dart';
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
import 'screens/resident/helping_staff/helping_staff_home_screen.dart';
import 'screens/resident/facilities/resident_facilities_screen.dart';
import 'screens/facilities_manager/create_edit_facility_screen.dart';
import 'screens/facilities_manager/facility_detail_screen.dart';
import 'screens/facilities_manager/booking_history_screen.dart';
import 'screens/resident/events/events_screen.dart';  // Add this import
import 'providers/event_provider.dart';  // Add this import
import 'providers/report_provider.dart';  // Add this import
import 'providers/alert_provider.dart';
import 'screens/resident/guest_qr/guest_qr_form_screen.dart';  // Add this import
import 'screens/resident/guest_qr/guest_qr_view_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OrelaxApp());
}

class OrelaxApp extends StatelessWidget {
  const OrelaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => FacilityProvider()),
        ChangeNotifierProvider(create: (context) => BookingProvider()),
        ChangeNotifierProvider(create: (context) => EmployeeProvider()),
        ChangeNotifierProvider(create: (context) => EventProvider()),  // ADD THIS
        ChangeNotifierProvider(create: (context) => ReportProvider()), 
         // ADD THIS
        ChangeNotifierProvider(create: (context) => AlertProvider()),  // ADD THIS


      ],
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
          '/chat': (_) => const ChatScreen(),
          '/report': (_) => const ReportScreen(),
          '/notifications': (_) => const _ComingSoonScreen(title: 'Notifications'),
          '/profile': (_) => const ProfileScreen(),
          '/guest_qr': (_) => const GuestQRFormScreen(),
          '/guest_qr_view': (ctx) {
            final args = ModalRoute.of(ctx)!.settings.arguments
                as Map<String, dynamic>;
            return GuestQRViewScreen(
              qrData: args['qrData'] as String,
              guestName: args['guestName'] as String? ?? '',
              visitDate: args['visitDate'] as String?,
              hostName: args['hostName'] as String?,
            );
          },

          // Resident shortcuts
          '/feed': (_) => const _ComingSoonScreen(title: 'Community Feed'),
          '/events': (_) => EventsScreen(),  // Add this line
          '/bookings': (_) => const _ComingSoonScreen(title: 'Bookings'),
          '/maintenance-request':
              (_) => const _ComingSoonScreen(title: 'Maintenance Request'),
          '/facilities': (_) => const ResidentFacilitiesScreen(),

          // Security screens
          '/access-control': (_) => const AccessControlScreen(),
          '/visitors': (_) => const VisitorsScreen(),
          '/alerts': (_) => const AlertsScreen(),
          '/access-logs': (_) => const AccessLogsScreen(),

          // Maintenance screens
          '/work-orders': (_) => const WorkOrdersScreen(),
          '/pending-requests': (_) => const PendingRequestsScreen(),
          '/schedule': (_) => const MaintenanceScheduleScreen(),

          // Facilities Manager
          '/create-facility': (_) =>const CreateEditFacilityScreen(),
          '/facility-detail': (_) => const _FacilityDetailWrapper(),
          '/booking-history': (_) => const BookingHistoryScreen(),

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

// Wrapper for facility detail to pass arguments
class _FacilityDetailWrapper extends StatelessWidget {
  const _FacilityDetailWrapper();

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as String;
    return FacilityDetailScreen(facilityId: args);
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