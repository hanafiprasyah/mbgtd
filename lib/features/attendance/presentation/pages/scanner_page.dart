import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/core/helper/global_scaffold_messenger.dart';
import 'package:mbg_test/core/services/camera_prewarm.dart';
import 'package:mbg_test/core/services/permission_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../bloc/attendance_bloc.dart';
import '../../bloc/attendance_event.dart';
import '../../bloc/attendance_state.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mbg_test/core/helper/design_system.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final MobileScannerController _controller =
      CameraPrewarmService.controller;
  bool isScanning = false;
  bool isProcessing = false;
  DateTime? _lastScanTime;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _unlockTimer;

  late Future<bool> _permissionFuture;
  bool _isTorchOn = false;
  String? _lastScannedQR;

  // NEW: surfaces camera-start failures instead of swallowing them.
  String? _cameraError;

  Timer? _idleTimer;
  static const Duration _idleDuration = Duration(seconds: 10);

  // UI-only: drives the animated scan line + breathing glow on the viewfinder.
  late final AnimationController _scanLineController;

  // Shared viewfinder geometry so the painter and the hint-text layout
  // never drift apart.
  static const double _frameSize = 260;
  static const double _frameRadius = 24;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _permissionFuture = PermissionService.requestCamera();
    _initCameraUltraFast();
    _resetIdleTimer();
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();

    _idleTimer = Timer(_idleDuration, () {
      if (!mounted) return;

      if (_controller.value.isRunning) {
        _controller.stop(); // smart pause
      }
    });
  }

  Future<void> _initCameraUltraFast() async {
    try {
      final granted = await _permissionFuture;
      if (!granted) return;

      // In the normal flow this is a no-op: CameraPrewarmService.warmBeforeNavigate()
      // (called from wherever "Scan" was tapped) should already have this running
      // by the time we get here. This is just the safety net for deep links / cold
      // starts that skip that step.
      if (mounted && !_controller.value.isRunning) {
        await _controller.start();
      }
      if (mounted && _cameraError != null) {
        setState(() => _cameraError = null);
      }
    } on MobileScannerException catch (e) {
      if (!mounted) return;
      setState(() => _cameraError = _describeCameraError(e));
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _cameraError = 'Camera failed to start. Please try again.',
      );
    }
  }

  String _describeCameraError(MobileScannerException e) {
    switch (e.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return 'Camera permission denied. Please allow camera access in settings.';
      case MobileScannerErrorCode.unsupported:
        return 'This device does not support camera scanning.';
      default:
        return 'Camera failed to start. Please try again.';
    }
  }

  Future<void> _retryCamera() async {
    setState(() => _cameraError = null);
    await _initCameraUltraFast();
  }

  Future<void> _handleBackAction() async {
    if (!mounted) return;
    // Do NOT stop camera here → keep it alive for next page / next visit.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Explicit black background: no default-canvas flash while the
      // permission FutureBuilder or the camera texture is still booting.
      backgroundColor: Colors.black,
      body: FutureBuilder<bool>(
        future: _permissionFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const _BootingPlaceholder();
          }

          if (!snapshot.data!) {
            return _PermissionDeniedView(
              onRetry: () {
                setState(() {
                  _permissionFuture = PermissionService.requestCamera();
                });
              },
            );
          }

          return BlocListener<AttendanceBloc, AttendanceState>(
            listener: (context, state) {
              if (state is AttendanceSuccess) {
                if (!mounted) return;
                GlobalScaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text('Scan successful! Attendance recorded'),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF16A34A),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );

                setState(() {
                  isProcessing = false;
                });

                Future.microtask(() async {
                  if (!mounted) return;
                  await _handleBackAction();
                });
              }

              if (state is AttendanceError) {
                if (!mounted) return;

                GlobalScaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(child: Text(state.message)),
                      ],
                    ),
                    backgroundColor: const Color(0xFFDC2626),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );

                Future.microtask(() async {
                  if (!mounted) return;
                  await _handleBackAction();
                });
              }
            },
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) async {
                _resetIdleTimer();
                if (!_controller.value.isRunning) {
                  try {
                    await _controller.start();
                    if (mounted && _cameraError != null) {
                      setState(() => _cameraError = null);
                    }
                  } on MobileScannerException catch (e) {
                    if (!mounted) return;
                    setState(() => _cameraError = _describeCameraError(e));
                  } catch (_) {
                    // Non-fatal: user can still tap the frame again.
                  }
                }
              },
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _resetIdleTimer,
                onPanDown: (_) => _resetIdleTimer(),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Center of the viewfinder frame, in local coordinates —
                    // shared by the painter and the hint text below it so
                    // they can never end up misaligned.
                    final centerY = constraints.maxHeight / 2;
                    final hintTop = centerY + (_frameSize / 2) + AppSpacing.lg;

                    return Stack(
                      children: [
                        if (_cameraError != null)
                          _CameraErrorView(
                            message: _cameraError!,
                            onRetry: _retryCamera,
                            onBack: _handleBackAction,
                          )
                        else ...[
                          RepaintBoundary(
                            child: MobileScanner(
                              controller: _controller,
                              fit: BoxFit.cover,
                              tapToFocus: true,
                              useAppLifecycleState: false,
                              errorBuilder: (context, error) {
                                // mobile_scanner's own render-time error path —
                                // previously unhandled, so a texture failure
                                // here just rendered as a blank black surface.
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (!mounted) return;
                                  setState(
                                    () => _cameraError = _describeCameraError(
                                      error,
                                    ),
                                  );
                                });
                                return const _BootingPlaceholder();
                              },
                              placeholderBuilder: (context) =>
                                  const _BootingPlaceholder(),
                              onDetect: (barcodeCapture) async {
                                _resetIdleTimer();
                                if (isScanning) return;

                                final now = DateTime.now();
                                if (_lastScanTime != null &&
                                    now.difference(_lastScanTime!) <
                                        const Duration(milliseconds: 200)) {
                                  return;
                                }
                                _lastScanTime = now;

                                final barcode = barcodeCapture.barcodes.first;
                                final raw =
                                    barcode.rawValue ?? barcode.displayValue;

                                if (raw == null ||
                                    raw.trim().isEmpty ||
                                    raw.trim() == '||') {
                                  return;
                                }

                                if (_lastScannedQR == raw) return;
                                _lastScannedQR = raw;

                                setState(() {
                                  isScanning = true;
                                  isProcessing = true;
                                });

                                if (await Vibration.hasVibrator()) {
                                  Vibration.vibrate(duration: 120);
                                }

                                unawaited(
                                  _audioPlayer.play(AssetSource('notif.wav')),
                                );

                                if (!mounted) return;
                                context.read<AttendanceBloc>().add(ScanQR(raw));

                                _unlockTimer?.cancel();
                                _unlockTimer = Timer(
                                  const Duration(milliseconds: 300),
                                  () {
                                    if (!mounted) return;
                                    setState(() {
                                      isScanning = false;
                                      isProcessing = false;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                          // --- Viewfinder: dim mask + breathing frame + scan line ---
                          Positioned.fill(
                            child: IgnorePointer(
                              child: AnimatedBuilder(
                                animation: _scanLineController,
                                builder: (context, _) {
                                  return CustomPaint(
                                    painter: _ScannerOverlayPainter(
                                      progress: _scanLineController.value,
                                      isProcessing: isProcessing,
                                      frameSize: _frameSize,
                                      frameRadius: _frameRadius,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          // --- Contextual hint below the frame ---
                          Positioned(
                            top: hintTop,
                            left: 32,
                            right: 32,
                            child: IgnorePointer(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: Text(
                                  isProcessing
                                      ? 'Processing…'
                                      : 'Make sure the QR code is fully visible in the frame',
                                  key: ValueKey(isProcessing),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.1,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],

                        // --- Top bar: gradient backdrop + back button + title ---
                        const Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: IgnorePointer(
                            child: SizedBox(
                              height: 140,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black87,
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  _FrostedIconButton(
                                    icon: Icons.arrow_back_ios_new,
                                    onTap: isProcessing
                                        ? null
                                        : _handleBackAction,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Scan QR Code',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          child: Row(
                                            key: ValueKey(_cameraError == null),
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: _cameraError == null
                                                      ? const Color(0xFF34D399)
                                                      : const Color(0xFFDC2626),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                _cameraError == null
                                                    ? 'Camera ready'
                                                    : 'Camera error',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.7),
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                            ],
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

                        // --- Bottom controls: frosted torch toggle ---
                        if (_cameraError == null)
                          Positioned(
                            bottom: AppSpacing.lg,
                            left: 0,
                            right: 0,
                            child: SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _FrostedIconButton(
                                    icon: _isTorchOn
                                        ? Icons.flash_on
                                        : Icons.flash_off,
                                    active: _isTorchOn,
                                    size: 56,
                                    onTap: () {
                                      _controller.toggleTorch();
                                      setState(() {
                                        _isTorchOn = !_isTorchOn;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _isTorchOn ? 'Lighting on' : 'Lighting off',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.75,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // --- Processing state: bottom sheet-style card ---
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: IgnorePointer(
                            child: AnimatedSlide(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                              offset: isProcessing
                                  ? Offset.zero
                                  : const Offset(0, 1),
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: isProcessing ? 1 : 0,
                                child: SafeArea(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      0,
                                      20,
                                      16,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.md,
                                      ),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 20,
                                          sigmaY: 20,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 18,
                                            vertical: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.55,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              AppRadius.md,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.08,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.4,
                                                      color: Color(0xFF34D399),
                                                    ),
                                              ),
                                              const SizedBox(width: 14),
                                              const Expanded(
                                                child: Text(
                                                  'Verifying QR Code...',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _unlockTimer?.cancel();
    _audioPlayer.dispose();
    _scanLineController.dispose();
    // NO dispose controller here (shared via CameraPrewarmService)
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (!mounted || !_controller.value.isInitialized) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _resetIdleTimer();
        if (!_controller.value.isRunning) {
          _controller.start().catchError((e) {
            if (!mounted) return;
            setState(
              () => _cameraError = 'Camera failed to start. Please try again.',
            );
          });
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _idleTimer?.cancel();
        if (_controller.value.isRunning) {
          try {
            _controller.stop();
          } catch (_) {}
        }
        break;
      default:
        break;
    }
  }
}

/// Shown while the camera texture hasn't produced its first frame yet.
/// Matches the viewfinder's dark theme instead of a bare spinner on a
/// mismatched background — this is what covers the (now much shorter)
/// gap instead of a flash of black.
class _BootingPlaceholder extends StatelessWidget {
  const _BootingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}

/// Shared visual shell for the permission-denied and camera-error states:
/// a soft icon container above a title/body hierarchy, so both screens
/// read like a deliberate empty-state instead of a stack tossed in the
/// center of the screen.
class _ScannerStatusView extends StatelessWidget {
  const _ScannerStatusView({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.onPrimaryAction,
    required this.primaryLabel,
    this.onSecondaryAction,
    this.secondaryLabel,
  }) : primaryIcon = Icons.refresh_rounded;

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final VoidCallback onPrimaryAction;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback? onSecondaryAction;
  final String? secondaryLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: iconColor, size: 34),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPrimaryAction,
                icon: Icon(primaryIcon, size: 18),
                label: Text(primaryLabel),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
            if (onSecondaryAction != null && secondaryLabel != null) ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: onSecondaryAction,
                child: Text(
                  secondaryLabel!,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  const _PermissionDeniedView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _ScannerStatusView(
      icon: Icons.no_photography_rounded,
      iconColor: Colors.white70,
      title: 'Camera access required',
      message:
          'Attendance scanning requires camera access. Please allow camera permission in your device settings.',
      primaryLabel: 'Try again',
      onPrimaryAction: onRetry,
      secondaryLabel: 'Back',
      onSecondaryAction: () => Navigator.of(context).maybePop(),
    );
  }
}

class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: _ScannerStatusView(
        icon: Icons.error_outline_rounded,
        iconColor: const Color(0xFFDC2626),
        title: 'Something went wrong',
        message: message,
        primaryLabel: 'Try again',
        onPrimaryAction: onRetry,
        secondaryLabel: 'Back',
        onSecondaryAction: onBack,
      ),
    );
  }
}

/// Frosted-glass circular icon button used for the back and torch controls.
/// Purely presentational — no business logic lives here. Adds a subtle
/// press-scale so taps feel acknowledged instead of static.
class _FrostedIconButton extends StatefulWidget {
  const _FrostedIconButton({
    required this.icon,
    required this.onTap,
    this.size = 44,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final bool active;

  @override
  State<_FrostedIconButton> createState() => _FrostedIconButtonState();
}

class _FrostedIconButtonState extends State<_FrostedIconButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: disabled ? 0.4 : 1,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        scale: _pressed ? 0.92 : 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.size / 2),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Material(
              color: widget.active
                  ? Colors.amber.withValues(alpha: 0.85)
                  : Colors.black.withValues(alpha: 0.35),
              shape: CircleBorder(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.onTap,
                onTapDown: (_) => _setPressed(true),
                onTapCancel: () => _setPressed(false),
                onTapUp: (_) => _setPressed(false),
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: Icon(
                    widget.icon,
                    color: Colors.white,
                    size: widget.size * 0.42,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the dim mask, corner brackets, breathing glow, and animated scan
/// line for the QR viewfinder. Purely presentational — no scanning logic
/// lives here.
class _ScannerOverlayPainter extends CustomPainter {
  _ScannerOverlayPainter({
    required this.progress,
    required this.isProcessing,
    required this.frameSize,
    required this.frameRadius,
  });

  /// 0→1→0 repeating value driving both the scan line and the subtle
  /// breathing opacity on the frame corners.
  final double progress;
  final bool isProcessing;
  final double frameSize;
  final double frameRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final frameRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: frameSize,
      height: frameSize,
    );
    final outerRRect = RRect.fromRectAndRadius(
      frameRect,
      Radius.circular(frameRadius),
    );

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()..addRRect(outerRRect);
    final maskPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      holePath,
    );
    canvas.drawPath(
      maskPath,
      Paint()..color = Colors.black.withValues(alpha: 0.58),
    );

    final accent = isProcessing ? const Color(0xFF34D399) : Colors.white;

    // Soft glow behind the frame edge — gives the corners weight instead
    // of a flat 1px stroke, and breathes gently with `progress`.
    final breathe = 0.5 + 0.5 * math.sin(progress * math.pi);
    canvas.drawRRect(
      outerRRect,
      Paint()
        ..color = accent.withValues(alpha: 0.18 + 0.1 * breathe)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    final bracketPaint = Paint()
      ..color = accent
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const bracketLength = 28.0;

    void drawL(Offset start, Offset corner, Offset end) {
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(corner.dx, corner.dy)
        ..lineTo(end.dx, end.dy);
      canvas.drawPath(path, bracketPaint);
    }

    drawL(
      Offset(frameRect.left, frameRect.top + bracketLength),
      frameRect.topLeft,
      Offset(frameRect.left + bracketLength, frameRect.top),
    );
    drawL(
      Offset(frameRect.right - bracketLength, frameRect.top),
      frameRect.topRight,
      Offset(frameRect.right, frameRect.top + bracketLength),
    );
    drawL(
      Offset(frameRect.left, frameRect.bottom - bracketLength),
      frameRect.bottomLeft,
      Offset(frameRect.left + bracketLength, frameRect.bottom),
    );
    drawL(
      Offset(frameRect.right - bracketLength, frameRect.bottom),
      frameRect.bottomRight,
      Offset(frameRect.right, frameRect.bottom - bracketLength),
    );

    if (!isProcessing) {
      final lineY = frameRect.top + 16 + (frameRect.height - 32) * progress;
      final lineRect = Rect.fromLTWH(
        frameRect.left + 12,
        lineY,
        frameRect.width - 24,
        3,
      );
      final shader = LinearGradient(
        colors: [
          accent.withValues(alpha: 0),
          accent.withValues(alpha: 0.9),
          accent.withValues(alpha: 0),
        ],
      ).createShader(lineRect);
      canvas.drawRRect(
        RRect.fromRectAndRadius(lineRect, const Radius.circular(2)),
        Paint()..shader = shader,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isProcessing != isProcessing;
  }
}
