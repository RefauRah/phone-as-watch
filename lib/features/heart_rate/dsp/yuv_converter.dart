import 'dart:typed_data';
import 'package:camera/camera.dart';

/// Specialist utility to extract optical Red intensity from Camera frames
/// Supports both Android (YUV420 / NV21) and iOS (BGRA8888) format groups.
class YuvConverter {
  YuvConverter._();

  /// Extracts the average Red channel intensity from the center region of interest (ROI)
  /// of the camera frame to optimize frame rate (30-60 FPS) and avoid boundary noise.
  ///
  /// Returns a normalized intensity in the range [0.0, 255.0].
  static double extractCenterRedIntensity(CameraImage image) {
    if (image.planes.isEmpty) return 0.0;

    if (image.format.group == ImageFormatGroup.yuv420) {
      return _extractFromYuv420(image);
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      return _extractFromBgra8888(image);
    } else {
      // Fallback: Use plane 0 luminance
      return _extractFallback(image);
    }
  }

  /// Evaluates ITU-R BT.601 conversion: Red = Y + 1.402 * (V - 128)
  /// Center ROI: 30% x 30% in the middle of the frame
  static double _extractFromYuv420(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    final Plane planeY = image.planes[0];
    final Plane? planeV = image.planes.length > 2 ? image.planes[2] : null;

    final Uint8List bytesY = planeY.bytes;
    final Uint8List? bytesV = planeV?.bytes;

    final int startX = (width * 0.35).toInt();
    final int endX = (width * 0.65).toInt();
    final int startY = (height * 0.35).toInt();
    final int endY = (height * 0.65).toInt();

    final int yRowStride = planeY.bytesPerRow;
    final int? yPixelStride = planeY.bytesPerPixel;

    final int vRowStride = planeV?.bytesPerRow ?? 0;
    final int? vPixelStride = planeV?.bytesPerPixel;

    double totalRed = 0.0;
    int sampleCount = 0;

    // Subsample with step = 2 for ultra-fast DSP throughput without aliasing
    for (int y = startY; y < endY; y += 2) {
      final int yRowOffset = y * yRowStride;
      final int vRowOffset = planeV != null ? (y >> 1) * vRowStride : 0;

      for (int x = startX; x < endX; x += 2) {
        final int yIndex = yRowOffset + (x * (yPixelStride ?? 1));
        if (yIndex >= bytesY.length) continue;
        final int yVal = bytesY[yIndex];

        double redVal = yVal.toDouble();

        if (bytesV != null && vRowOffset < bytesV.length) {
          final int vIndex = vRowOffset + ((x >> 1) * (vPixelStride ?? 1));
          if (vIndex < bytesV.length) {
            final int vVal = bytesV[vIndex];
            // Standard BT.601 color conversion
            redVal = yVal + 1.402 * (vVal - 128);
          }
        }

        totalRed += redVal.clamp(0.0, 255.0);
        sampleCount++;
      }
    }

    return sampleCount > 0 ? (totalRed / sampleCount) : 0.0;
  }

  /// Extracts Red channel from iOS BGRA8888 buffer [B, G, R, A]
  static double _extractFromBgra8888(CameraImage image) {
    final Uint8List bytes = image.planes[0].bytes;
    final int width = image.width;
    final int height = image.height;
    final int bytesPerRow = image.planes[0].bytesPerRow;

    final int startX = (width * 0.35).toInt();
    final int endX = (width * 0.65).toInt();
    final int startY = (height * 0.35).toInt();
    final int endY = (height * 0.65).toInt();

    double totalRed = 0.0;
    int sampleCount = 0;

    for (int y = startY; y < endY; y += 2) {
      final int rowOffset = y * bytesPerRow;
      for (int x = startX; x < endX; x += 2) {
        final int pixelIndex = rowOffset + (x * 4);
        if (pixelIndex + 2 < bytes.length) {
          // In BGRA: byte 0 = B, byte 1 = G, byte 2 = R, byte 3 = A
          final int redVal = bytes[pixelIndex + 2];
          totalRed += redVal;
          sampleCount++;
        }
      }
    }

    return sampleCount > 0 ? (totalRed / sampleCount) : 0.0;
  }

  static double _extractFallback(CameraImage image) {
    final Uint8List bytes = image.planes[0].bytes;
    if (bytes.isEmpty) return 0.0;

    int sum = 0;
    final int step = bytes.length > 5000 ? (bytes.length ~/ 1000) : 1;
    int count = 0;
    for (int i = 0; i < bytes.length; i += step) {
      sum += bytes[i];
      count++;
    }
    return count > 0 ? sum / count : 0.0;
  }

  /// Evaluates whether a human finger is covering the camera sensor
  /// Under flashlight, a covered finger produces high red saturation (> 100)
  static bool isFingerCoveringCamera(double averageRed) {
    return averageRed > 85.0;
  }
}
