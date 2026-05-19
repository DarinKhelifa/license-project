import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/fire_alert_provider.dart';
import '../../providers/auth_provider.dart';

class FireAlertOverlay extends StatefulWidget {
  const FireAlertOverlay({super.key});

  @override
  State<FireAlertOverlay> createState() => _FireAlertOverlayState();
}

class _FireAlertOverlayState extends State<FireAlertOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Create pulsing animation for the red screen
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fireAlertProvider = Provider.of<FireAlertProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Only show if there's an active alert and user is handling it
    if (!fireAlertProvider.isHandlingAlert || fireAlertProvider.activeAlert == null) {
      return const SizedBox.shrink();
    }

    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: Container(
          color: Colors.red.shade900,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Fire icon with animation
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 120,
                  color: Colors.white,
                ),
                const SizedBox(height: 40),

                // Alert text
                Text(
                  'FIRE ALERT!',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: const Offset(2, 2),
                            blurRadius: 4,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Location
                Text(
                  'Location: ${fireAlertProvider.activeAlert?.location ?? 'Unknown'}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Question text
                Text(
                  'Are you in a safe place?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),

                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // SAFE button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // User is safe - dismiss overlay
                            fireAlertProvider.markSafe(
                              fireAlertProvider.activeAlert!.id,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Stay safe. Help is on the way.',
                                  style: TextStyle(fontSize: 16),
                                ),
                                backgroundColor: Colors.green.shade700,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 24,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade700,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 40,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'SAFE',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),

                      // NOT SAFE button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // User is NOT safe - send emergency notification
                            fireAlertProvider.reportNotSafe(
                              fireAlertProvider.activeAlert!.id,
                              authProvider,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Emergency team notified. Stay where you are.',
                                  style: TextStyle(fontSize: 16),
                                ),
                                backgroundColor: Colors.red.shade800,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 24,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade800,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.emergency_share,
                                  size: 40,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'NOT SAFE',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
