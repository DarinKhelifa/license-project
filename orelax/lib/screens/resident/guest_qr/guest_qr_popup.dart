import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

void showGuestQRPopup(
  BuildContext context,
  String qrData,
  String guestName, {
  String? visitDate,
  String? hostName,
}) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Guest Access Pass',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF034808),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'For $guestName',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Image.memory(
                  base64Decode(
                    qrData.contains(',') ? qrData.split(',').last : qrData,
                  ),
                  width: 200,
                  height: 200,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF034808).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: Color(0xFF034808), size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your guest must show this QR code at the security gate.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF034808),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Preview as Guest button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      '/guest_qr_view',
                      arguments: {
                        'qrData': qrData,
                        'guestName': guestName,
                        'visitDate': visitDate,
                        'hostName': hostName,
                      },
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined, color: Color(0xFF034808)),
                  label: const Text(
                    'Preview Guest Screen',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF034808),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: const BorderSide(color: Color(0xFF034808)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          final bytes = base64Decode(
                              qrData.contains(',') ? qrData.split(',').last : qrData);
                          final tempDir = await getTemporaryDirectory();
                          final file =
                              await File('${tempDir.path}/guest_qr.png').create();
                          await file.writeAsBytes(bytes);
                          await Share.shareXFiles(
                            [XFile(file.path)],
                            text:
                                '🏡 Your Orelax Guest Pass, $guestName!\n\nPresent this QR code to the security guard at the entrance gate.',
                          );
                        } catch (e) {
                          debugPrint('Error sharing QR: $e');
                        }
                      },
                      icon: const Icon(Icons.share, color: Color(0xFF034808)),
                      label: const Text(
                        'Share',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF034808)),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFF034808)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF034808),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}