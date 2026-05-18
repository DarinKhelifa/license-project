import 'package:flutter/material.dart';

enum AuthBannerVariant { error, info }

class AuthErrorBanner extends StatelessWidget {
  final String message;
  final AuthBannerVariant variant;

  const AuthErrorBanner({super.key, required this.message, this.variant = AuthBannerVariant.error});

  bool get _isInfo => variant == AuthBannerVariant.info;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isInfo ? const Color(0xFFF1F8FF) : const Color(0xFFFFF1F1);
    final borderColor = _isInfo ? const Color(0xFFC8DDF3) : const Color(0xFFF2C2C2);
    final accentColor = _isInfo ? const Color(0xFF1D5FA7) : const Color(0xFFB3261E);
    final chipColor = _isInfo ? const Color(0xFFD9EBFB) : const Color(0xFFFFD9D9);
    final shadowColor = _isInfo ? const Color(0xFF1D5FA7) : Colors.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: chipColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isInfo ? Icons.info_outline : Icons.error_outline,
              size: 18,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: _isInfo ? const Color(0xFF134C86) : const Color(0xFF8A1F1A),
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}