import 'dart:async';
import 'package:camera/camera.dart';
import '../dsp/ppg_signal_processor.dart';
import '../dsp/yuv_converter.dart';

/// Camera service managing the optical sensor stream, torch lighting,
/// and low-overhead frame dispatch to the DSP pipeline.
class CameraPpgService {
  CameraController? _cameraController;
  final PpgSignalProcessor _signalProcessor = PpgSignalProcessor(nominalSampleRate: 30.0);

  final StreamController<PpgProcessingResult> _resultStreamController =
      StreamController<PpgProcessingResult>.broadcast();

  Stream<PpgProcessingResult> get resultStream => _resultStreamController.stream;

  bool _isProcessing = false;
  bool _isDisposed = false;
  bool _isTorchOn = false;

  bool get isInitialized => _cameraController != null && _cameraController!.value.isInitialized;
  bool get isRecording => _isProcessing;
  CameraController? get controller => _cameraController;

  /// Initializes the rear camera with ResolutionPreset.low for 30-60 FPS throughput
  Future<void> initialize() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception("No camera found on device");
      }

      // Find back-facing camera
      final backCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.low, // Ultra-low resolution (approx 320x240) for max FPS & low thermals
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
    } catch (e) {
      rethrow;
    }
  }

  /// Starts torch illumination and image frame stream processing
  Future<void> startMeasurement() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      await initialize();
    }

    if (_isProcessing) return;

    _signalProcessor.reset();
    _isProcessing = true;

    try {
      // Turn on flashlight to illuminate fingertip capillary bed
      await _cameraController!.setFlashMode(FlashMode.torch);
      _isTorchOn = true;
    } catch (e) {
      // In case torch is temporarily busy or unavailable on simulator
      _isTorchOn = false;
    }

    bool isFrameBusy = false;

    await _cameraController!.startImageStream((CameraImage image) {
      if (!_isProcessing || _isDisposed) return;
      if (isFrameBusy) return; // Prevent frame backlog drop

      isFrameBusy = true;
      try {
        final double redIntensity = YuvConverter.extractCenterRedIntensity(image);
        final int timestampMs = DateTime.now().millisecondsSinceEpoch;

        final PpgProcessingResult result = _signalProcessor.processSample(
          redIntensity,
          timestampMs,
        );

        if (!_resultStreamController.isClosed) {
          _resultStreamController.add(result);
        }
      } catch (e) {
        // Log frame error without halting stream
      } finally {
        isFrameBusy = false;
      }
    });
  }

  /// Stops stream and shuts down torch
  Future<void> stopMeasurement() async {
    _isProcessing = false;
    final controller = _cameraController;

    if (controller != null && controller.value.isInitialized) {
      if (controller.value.isStreamingImages) {
        try {
          await controller.stopImageStream();
        } catch (_) {}
      }

      if (_isTorchOn) {
        try {
          await controller.setFlashMode(FlashMode.off);
        } catch (_) {}
        _isTorchOn = false;
      }
    }

    _signalProcessor.reset();
  }

  /// Disposes camera resources
  Future<void> dispose() async {
    _isDisposed = true;
    await stopMeasurement();
    await _cameraController?.dispose();
    _cameraController = null;
    await _resultStreamController.close();
  }
}
