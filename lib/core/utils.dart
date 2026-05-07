import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/premium_toast.dart';

/// Utility helpers used across the BSEMS system.
class AppUtils {
  AppUtils._();

  // ── Date / Time formatters ──────────────────────────────────────────
  static String formatDate(DateTime date) =>
      DateFormat('MMM dd, yyyy').format(date);

  static String formatDateTime(DateTime date) =>
      DateFormat('MMM dd, yyyy • hh:mm a').format(date);

  static String formatTime(DateTime date) =>
      DateFormat('hh:mm a').format(date);

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '${diff.inDays ~/ 365}y ago';
    if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  // ── Validators ──────────────────────────────────────────────────────
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? validateRequired(String? value, [String field = 'Field']) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  // ── Snackbar helpers ────────────────────────────────────────────────
  static void showSuccess(BuildContext context, String message) {
    PremiumToast.showSuccess(context, message);
  }

  static void showError(BuildContext context, String message) {
    PremiumToast.showError(context, message);
  }

  static void showInfo(BuildContext context, String message) {
    PremiumToast.showInfo(context, message);
  }

  // ── Misc ────────────────────────────────────────────────────────────
  static String initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'live':
      case 'completed':
        return const Color(0xFF00E676);
      case 'draft':
      case 'scheduled':
        return const Color(0xFFFFD740);
      case 'cancelled':
        return const Color(0xFFFF5252);
      case 'registration':
        return const Color(0xFF40C4FF);
      default:
        return const Color(0xFF90A4AE);
    }
  }
}
