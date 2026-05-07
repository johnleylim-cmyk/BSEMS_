import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app/theme.dart';

/// Rich premium toast notification with gradient accent, icon, and auto-dismiss progress.
class PremiumToast {
  /// Show a success toast.
  static void showSuccess(BuildContext context, String message) {
    _show(context, message: message, type: _ToastType.success);
  }

  /// Show an error toast.
  static void showError(BuildContext context, String message) {
    _show(context, message: message, type: _ToastType.error);
  }

  /// Show an info toast.
  static void showInfo(BuildContext context, String message) {
    _show(context, message: message, type: _ToastType.info);
  }

  static void _show(
    BuildContext context, {
    required String message,
    required _ToastType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: message,
        type: type,
        duration: duration,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

enum _ToastType { success, error, info }

class _ToastWidget extends StatefulWidget {
  final String message;
  final _ToastType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward().then((_) {
        if (!_dismissed) {
          _dismissed = true;
          widget.onDismiss();
        }
      });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Color get _accentColor {
    switch (widget.type) {
      case _ToastType.success:
        return AppTheme.accentGreen;
      case _ToastType.error:
        return AppTheme.accentRed;
      case _ToastType.info:
        return AppTheme.accentCyan;
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case _ToastType.success:
        return Icons.check_circle_rounded;
      case _ToastType.error:
        return Icons.error_rounded;
      case _ToastType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final border = isDark ? AppTheme.border : AppTheme.lightBorder;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

    return Positioned(
      top: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 380,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: _accentColor.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Gradient accent bar
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _accentColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(_icon, color: _accentColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        if (!_dismissed) {
                          _dismissed = true;
                          widget.onDismiss();
                        }
                      },
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Progress bar
              AnimatedBuilder(
                animation: _progressController,
                builder: (_, child) => LinearProgressIndicator(
                  value: 1.0 - _progressController.value,
                  minHeight: 3,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(_accentColor.withValues(alpha: 0.5)),
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, duration: 300.ms),
    );
  }
}
