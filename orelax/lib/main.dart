import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/facility_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/employee_provider.dart';
import 'providers/social_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/Welcome/welcome_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/Home/report_screen.dart';
import 'screens/security/reports_screen.dart';
import 'screens/security/notes_screen.dart';
import 'screens/Home/profile_screen.dart';
import 'screens/Home/home_screen.dart';
import 'screens/chat/chat_screen.dart';
// AccessControlScreen removed from navigation; reports route used instead
import 'screens/security/visitors_screen.dart';
import 'screens/security/alerts_screen.dart';
import 'screens/security/access_logs_screen.dart';
import 'screens/maintenance/work_orders_screen.dart';
import 'screens/maintenance/pending_requests_screen.dart';
import 'screens/maintenance/schedule_screen.dart';
import 'screens/resident/helping_staff/helping_staff_home_screen.dart';
import 'screens/resident/facilities/resident_facilities_screen.dart';
import 'screens/resident/parking/parking_screen.dart';
import 'screens/facilities_manager/create_edit_facility_screen.dart';
import 'screens/facilities_manager/facility_detail_screen.dart';
import 'screens/facilities_manager/booking_history_screen.dart';
import 'screens/resident/events/events_screen.dart';
import 'screens/resident/community/community_feed_screen.dart';
import 'providers/event_provider.dart';
import 'providers/report_provider.dart';
import 'providers/alert_provider.dart';
import 'providers/fire_alert_provider.dart';
import 'screens/resident/guest_qr/guest_qr_form_screen.dart';
import 'screens/resident/guest_qr/guest_qr_view_screen.dart';
import 'providers/energy_provider.dart';
import 'screens/monitoring/energy_monitoring_screen.dart';
import 'screens/camera/camera_live_stream_screen.dart';
import 'screens/resident/portal_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/Environment/temperature_screen.dart';
import 'services/api_service.dart';
import 'screens/auth/otp_verification_screen.dart';
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
        ChangeNotifierProvider(create: (context) => SocialProvider()),
        ChangeNotifierProvider(create: (context) => EventProvider()),
        ChangeNotifierProvider(create: (context) => ReportProvider()),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
        ChangeNotifierProvider(create: (context) => AlertProvider()),
        ChangeNotifierProvider(create: (context) => FireAlertProvider()),
        ChangeNotifierProvider(create: (context) => EnergyProvider()),
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
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('ar', 'SA'),
        ],
        builder: (context, child) {
          return NotificationBootstrapper(
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const WelcomeScreen(),
        routes: {
          '/welcome': (ctx) {
            final args = ModalRoute.of(ctx)!.settings.arguments as Map<String, dynamic>?;
            final navigateToHome = args?['navigateToHome'] as bool? ?? false;
            return WelcomeScreen(navigateToHome: navigateToHome);
          },
          '/home': (_) => const HomeScreen(),
          '/auth': (_) => const AuthWrapper(),
          '/onboarding': (_) => const OnboardingScreen(),
          '/chat': (_) => const ChatScreen(),
          '/report': (_) => const ReportScreen(),
          '/reports': (_) => const ReportsScreen(),
          '/notes': (_) => const NotesScreen(),
          '/notifications': (_) => const NotificationScreen(),
          '/profile': (_) => const ProfileScreen(),
          '/portal': (_) => const PortalScreen(),
          '/guest_qr': (_) => const GuestQRFormScreen(),
          '/guest_qr_view': (ctx) {
            final args = ModalRoute.of(ctx)!.settings.arguments as Map<String, dynamic>;
            return GuestQRViewScreen(
              qrData: args['qrData'] as String,
              guestName: args['guestName'] as String? ?? '',
              visitDate: args['visitDate'] as String?,
              hostName: args['hostName'] as String?,
            );
          },
          // Resident shortcuts
          '/feed': (_) => const CommunityFeedScreen(),
          '/events': (_) => EventsScreen(),
          '/bookings': (_) => const _ComingSoonScreen(title: 'Bookings'),
          '/maintenance-request': (_) => const _ComingSoonScreen(title: 'Maintenance Request'),
          '/facilities': (_) => const ResidentFacilitiesScreen(),
          // Security screens
          '/access-control': (_) => const ReportScreen(),
          '/visitors': (_) => const VisitorsScreen(),
          '/alerts': (_) => const AlertsScreen(),
          '/access-logs': (_) => const AccessLogsScreen(),
          // Maintenance screens
          '/work-orders': (_) => const WorkOrdersScreen(),
          '/pending-requests': (_) => const PendingRequestsScreen(),
          '/schedule': (_) => const MaintenanceScheduleScreen(),
          // Facilities Manager
          '/create-facility': (_) => const CreateEditFacilityScreen(),
          '/facility-detail': (_) => const _FacilityDetailWrapper(),
          '/booking-history': (_) => const BookingHistoryScreen(),
          // Placeholders
          '/all-services': (_) => const _ComingSoonScreen(title: 'All Services'),
          '/camera-live': (_) => const CameraLiveStreamScreen(),
          // OTP Verification Route
          '/otp': (ctx) {
            final args = ModalRoute.of(ctx)!.settings.arguments as Map<String, dynamic>;
            return OTPVerificationScreen(
              userId: args['userId'] as String,
              email: args['email'] as String,
            );
          },
          '/childcare': (_) => const _ComingSoonScreen(title: 'Childcare'),
          '/helping-staff': (_) => const HelpingStaffScreen(),
          '/parking': (_) => const ParkingScreen(),
          '/manage-accounts': (_) => const _ComingSoonScreen(title: 'Manage Accounts'),
          '/security-management': (_) => const _ComingSoonScreen(title: 'Security Management'),
          '/monitoring': (_) => const EnergyMonitoringScreen(),
          '/temperature': (_) => const TemperatureScreen(),
          // Fire alerts history is embedded in '/alerts'
        },
      ),
    );
  }
}

// Global overlay for fire alerts
class GlobalFireAlertOverlay extends StatefulWidget {
  final Widget child;
  const GlobalFireAlertOverlay({super.key, required this.child});

  @override
  State<GlobalFireAlertOverlay> createState() => _GlobalFireAlertOverlayState();
}

class _GlobalFireAlertOverlayState extends State<GlobalFireAlertOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  void Function(FlutterErrorDetails)? _oldFlutterErrorOnError;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);

    // Capture previous handler and override Flutter error handler so uncaught
    // framework errors show the full-screen red alert via the provider.
    _oldFlutterErrorOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      // Call previous handler to preserve logs
      try {
        _oldFlutterErrorOnError?.call(details);
      } catch (_) {}

      // Post-frame: create an error alert so the Global overlay displays
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (mounted) {
            context.read<FireAlertProvider>().createErrorAlert(details.exceptionAsString());
          }
        } catch (_) {}
      });
    };
  }

  @override
  void dispose() {
    // restore previous handler
    FlutterError.onError = _oldFlutterErrorOnError;
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Consumer<FireAlertProvider>(builder: (context, p, _) {
          final active = p.activeAlert;
          if (active == null) return const SizedBox.shrink();

          final date = '${active.timestamp.day.toString().padLeft(2, '0')} ${_monthName(active.timestamp.month)} ${active.timestamp.year}';
          final time = '${active.timestamp.hour.toString().padLeft(2, '0')}:${active.timestamp.minute.toString().padLeft(2, '0')}:${active.timestamp.second.toString().padLeft(2, '0')}';

          return Positioned.fill(
            child: Material(
              color: Colors.red.shade700.withOpacity(0.95),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _blinkController,
                      child: const Text('🔥', style: TextStyle(fontSize: 96)),
                    ),
                    const SizedBox(height: 24),
                    const Text('FIRE DETECTED!', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text('$date • $time', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 36),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                      onPressed: () {
                        if (active != null) {
                          context.read<FireAlertProvider>().acknowledge(active.id);
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Text('ACKNOWLEDGE', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        })
      ],
    );
  }

  String _monthName(int m) {
    const names = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return names[m-1];
  }
}

class NotificationBootstrapper extends StatefulWidget {
  final Widget child;

  const NotificationBootstrapper({super.key, required this.child});

  @override
  State<NotificationBootstrapper> createState() => _NotificationBootstrapperState();
}

class _NotificationBootstrapperState extends State<NotificationBootstrapper> {
  AuthProvider? _authProvider;
  String? _connectedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentAuthProvider = context.read<AuthProvider>();
    if (_authProvider != currentAuthProvider) {
      _authProvider?.removeListener(_syncNotificationSocket);
      _authProvider = currentAuthProvider;
      _authProvider?.addListener(_syncNotificationSocket);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncNotificationSocket();
    });
  }

  Future<void> _syncNotificationSocket() async {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;
    final notificationProvider = context.read<NotificationProvider>();

    if (userId == null) {
      if (_connectedUserId != null) {
        notificationProvider.disconnect();
        _connectedUserId = null;
      }
      return;
    }

    if (_connectedUserId == userId) {
      return;
    }

    await notificationProvider.initialize(ApiService.serverUrl, userId);
    _connectedUserId = userId;
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_syncNotificationSocket);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlobalFireAlertOverlay(child: widget.child);
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