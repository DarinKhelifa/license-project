import 'dart:convert';
import 'package:flutter/material.dart';

/// The screen shown to the GUEST after the resident shares the QR code.
/// Design matches the "Welcome to Orelax" mockup exactly.
class GuestQRViewScreen extends StatelessWidget {
  final String qrData;
  final String guestName;
  final String? visitDate;
  final String? hostName;

  const GuestQRViewScreen({
    super.key,
    required this.qrData,
    required this.guestName,
    this.visitDate,
    this.hostName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Light grey page background — same as mockup
      backgroundColor: const Color(0xFFEEEEEE),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: _WhiteCard(
              qrData: qrData,
              guestName: guestName,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Internal card widget ───────────────────────────────────────────────────────

class _WhiteCard extends StatelessWidget {
  final String qrData;
  final String guestName;

  const _WhiteCard({required this.qrData, required this.guestName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── "Welcome to Orelax" ─────────────────────────────────────────
          const Text(
            'Welcome to Orelax',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF034808),
              height: 1.2,
            ),
          ),

          const SizedBox(height: 6),

          // ── Subtitle ────────────────────────────────────────────────────
          const Text(
            'Smart. safe. confortabale',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.2,
            ),
          ),

          const SizedBox(height: 36),

          // ── QR Code Image ───────────────────────────────────────────────
          _QRImage(qrData: qrData),

          const SizedBox(height: 14),

          // ── Caption ─────────────────────────────────────────────────────
          const Text(
            'This is your QR code',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 44),

          // ── Quote ────────────────────────────────────────────────────────
          const Text(
            '" You made it. Now just relax "',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── QR Image renderer ─────────────────────────────────────────────────────────

class _QRImage extends StatelessWidget {
  final String qrData;

  const _QRImage({required this.qrData});

  @override
  Widget build(BuildContext context) {
    try {
      final raw =
          qrData.contains(',') ? qrData.split(',').last : qrData;
      return Image.memory(
        base64Decode(raw),
        width: 220,
        height: 220,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } catch (_) {
      return _placeholder();
    }
  }

  Widget _placeholder() {
    return Container(
      width: 220,
      height: 220,
      color: Colors.white,
      child: const Center(
        child: Icon(
          Icons.qr_code_2_rounded,
          size: 120,
          color: Colors.black26,
        ),
      ),
    );
  }
}
