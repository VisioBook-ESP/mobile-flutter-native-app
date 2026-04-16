import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/core/routing/app_router.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/core/widgets/app_button.dart';
import 'package:visiobook_mobile/core/widgets/gradient_background.dart';
import 'package:visiobook_mobile/features/import/presentation/providers/import_provider.dart';
import 'package:visiobook_mobile/features/project_detail/presentation/providers/project_detail_provider.dart';

/// Ecran de scan de document via la camera
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isCapturing = false;
  bool _isUploading = false;

  // Captured pages
  final List<String> _capturedImagePaths = [];

  // Preview state (after capturing a single photo)
  String? _previewImagePath;

  // Permission state
  bool _permissionDenied = false;
  bool _permissionChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      setState(() {
        _isCameraInitialized = false;
        _cameraController = null;
      });
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    // Request camera permission
    final status = await Permission.camera.request();

    setState(() {
      _permissionChecked = true;
      _permissionDenied = !status.isGranted;
    });

    if (!status.isGranted) return;

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      final backCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint('Erreur initialisation camera: $e');
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;

    try {
      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
      } else {
        await _cameraController!.setFlashMode(FlashMode.torch);
      }
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      debugPrint('Erreur toggle flash: $e');
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      // Turn off flash for capture if it was on as torch
      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.auto);
      }

      final xFile = await _cameraController!.takePicture();

      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.torch);
      }

      if (!mounted) return;
      setState(() {
        _previewImagePath = xFile.path;
        _isCapturing = false;
      });
    } catch (e) {
      debugPrint('Erreur capture: $e');
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  void _retakePhoto() {
    // Delete the preview image file
    if (_previewImagePath != null) {
      final file = File(_previewImagePath!);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
    setState(() {
      _previewImagePath = null;
    });
  }

  void _usePhoto() {
    if (_previewImagePath == null) return;
    setState(() {
      _capturedImagePaths.add(_previewImagePath!);
      _previewImagePath = null;
    });
  }

  Future<void> _finishScanning() async {
    if (_capturedImagePaths.isEmpty) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final provider = context.read<ImportProvider>();
      await provider.uploadScannedImages(_capturedImagePaths);

      if (!mounted) return;

      if (provider.state == ImportState.uploaded) {
        final result = provider.uploadResult;
        final file = provider.selectedFile;
        if (result != null && file != null) {
          context.read<ProjectDetailProvider>().initFromImport(
            fileId: result.fileId ?? 'unknown',
            fileName: file.name,
            extractedText: result.extractedText,
            wordCount: result.wordCount,
          );
          provider.reset();
          context.push(AppRoutes.projectConfig);
        }
      } else if (provider.state == ImportState.error) {
        setState(() {
          _isUploading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                provider.error ?? 'Erreur lors du traitement du scan',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading / uploading state
    if (_isUploading) {
      return _buildUploadingScreen();
    }

    // Preview state (after capturing a photo)
    if (_previewImagePath != null) {
      return _buildPreviewScreen();
    }

    // Permission denied state
    if (_permissionChecked && _permissionDenied) {
      return _buildPermissionDeniedScreen();
    }

    // Camera not ready state
    if (!_isCameraInitialized) {
      return _buildLoadingScreen();
    }

    // Camera live view
    return _buildCameraScreen();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.neutral900,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 24),
            Text(
              'Initialisation de la camera...',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.neutral300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedScreen() {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              LucideIcons.arrowLeft,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Scanner',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    LucideIcons.cameraOff,
                    size: 40,
                    color: AppColors.neutral500,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Acces a la camera requis',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Pour scanner un document, veuillez autoriser '
                  "l'acces a la camera dans les reglages.",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.neutral500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                AppButton(
                  text: 'Ouvrir les reglages',
                  fullWidth: true,
                  size: AppButtonSize.lg,
                  onPressed: () => openAppSettings(),
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: 'Retour',
                  variant: AppButtonVariant.outline,
                  fullWidth: true,
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraScreen() {
    return Scaffold(
      backgroundColor: AppColors.neutral900,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview (full screen)
          Positioned.fill(child: CameraPreview(_cameraController!)),

          // Document frame overlay
          const _DocumentFrameOverlay(),

          // Top bar: back + flash
          _buildTopBar(),

          // Bottom controls: gallery badge + capture + finish
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CircleIconButton(
                icon: LucideIcons.arrowLeft,
                onPressed: () {
                  // Clean up captured files
                  for (final path in _capturedImagePaths) {
                    final file = File(path);
                    if (file.existsSync()) file.deleteSync();
                  }
                  context.pop();
                },
              ),
              _CircleIconButton(
                icon: _isFlashOn ? LucideIcons.zapOff : LucideIcons.zap,
                onPressed: _toggleFlash,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 32, left: 24, right: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // "Terminer" button (visible when pages captured)
              if (_capturedImagePaths.isNotEmpty) ...[
                GestureDetector(
                  onTap: _finishScanning,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'Terminer (${_capturedImagePaths.length})',
                      style: const TextStyle(
                        color: AppColors.neutral900,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Capture button row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Page count badge (left)
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: _capturedImagePaths.isNotEmpty
                        ? _buildPageCountBadge()
                        : null,
                  ),

                  const SizedBox(width: 24),

                  // Capture button (center)
                  _buildCaptureButton(),

                  const SizedBox(width: 24),

                  // Spacer (right) for symmetry
                  const SizedBox(width: 56, height: 56),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageCountBadge() {
    return GestureDetector(
      onTap: () {
        // Show captured pages count info
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_capturedImagePaths.length} page(s) capturee(s)'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(LucideIcons.layers, color: Colors.white, size: 24),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${_capturedImagePaths.length}',
                    style: const TextStyle(
                      color: AppColors.neutral900,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _isCapturing ? null : _captureImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isCapturing
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewScreen() {
    return Scaffold(
      backgroundColor: AppColors.neutral900,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Preview image
          Positioned.fill(
            child: Image.file(File(_previewImagePath!), fit: BoxFit.contain),
          ),

          // Top bar
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
                    _CircleIconButton(
                      icon: LucideIcons.x,
                      onPressed: _retakePhoto,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom action buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    // Retake
                    Expanded(
                      child: AppButton(
                        text: 'Reprendre',
                        variant: AppButtonVariant.outline,
                        onPressed: _retakePhoto,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Use this
                    Expanded(
                      child: AppButton(text: 'Utiliser', onPressed: _usePhoto),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadingScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Consumer<ImportProvider>(
              builder: (context, provider, _) {
                final progress = provider.uploadProgress;
                final percentage = (progress * 100).toInt();

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        LucideIcons.scanLine,
                        size: 40,
                        color: AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Traitement du scan...',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_capturedImagePaths.length} page(s) en cours '
                      "d'analyse",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.neutral500,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress > 0 ? progress : null,
                        minHeight: 8,
                        backgroundColor: AppColors.neutral200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.neutral900,
                        ),
                      ),
                    ),
                    if (progress > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '$percentage%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.neutral500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlay with a semi-transparent frame guide for document scanning
class _DocumentFrameOverlay extends StatelessWidget {
  const _DocumentFrameOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _DocumentFramePainter(), size: Size.infinite),
    );
  }
}

class _DocumentFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Semi-transparent overlay
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    // Frame dimensions (80% width, 60% height, centered)
    final frameWidth = size.width * 0.85;
    final frameHeight = size.height * 0.55;
    final frameLeft = (size.width - frameWidth) / 2;
    final frameTop = (size.height - frameHeight) / 2;
    const cornerRadius = 16.0;

    final frameRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(frameLeft, frameTop, frameWidth, frameHeight),
      const Radius.circular(cornerRadius),
    );

    // Draw overlay with cut-out
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final framePath = Path()..addRRect(frameRect);

    final combinedPath = Path.combine(
      PathOperation.difference,
      overlayPath,
      framePath,
    );

    canvas.drawPath(combinedPath, overlayPaint);

    // Draw frame border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(frameRect, borderPaint);

    // Draw corner accents (thicker, shorter lines at each corner)
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const accentLength = 30.0;

    // Top-left corner
    canvas.drawLine(
      Offset(frameLeft + cornerRadius, frameTop),
      Offset(frameLeft + cornerRadius + accentLength, frameTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameLeft, frameTop + cornerRadius),
      Offset(frameLeft, frameTop + cornerRadius + accentLength),
      cornerPaint,
    );

    // Top-right corner
    final frameRight = frameLeft + frameWidth;
    canvas.drawLine(
      Offset(frameRight - cornerRadius, frameTop),
      Offset(frameRight - cornerRadius - accentLength, frameTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameRight, frameTop + cornerRadius),
      Offset(frameRight, frameTop + cornerRadius + accentLength),
      cornerPaint,
    );

    // Bottom-left corner
    final frameBottom = frameTop + frameHeight;
    canvas.drawLine(
      Offset(frameLeft + cornerRadius, frameBottom),
      Offset(frameLeft + cornerRadius + accentLength, frameBottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameLeft, frameBottom - cornerRadius),
      Offset(frameLeft, frameBottom - cornerRadius - accentLength),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(frameRight - cornerRadius, frameBottom),
      Offset(frameRight - cornerRadius - accentLength, frameBottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameRight, frameBottom - cornerRadius),
      Offset(frameRight, frameBottom - cornerRadius - accentLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Circular icon button for overlay controls
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
