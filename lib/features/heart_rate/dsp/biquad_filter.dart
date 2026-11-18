import 'dart:math' as math;

/// Second-order Infinite Impulse Response (IIR) Biquad Filter
/// Formulated via Bilinear Transform:
/// y[n] = b0*x[n] + b1*x[n-1] + b2*x[n-2] - a1*y[n-1] - a2*y[n-2] (normalized with a0 = 1.0)
class BiquadFilter {
  double b0 = 1.0;
  double b1 = 0.0;
  double b2 = 0.0;
  double a1 = 0.0;
  double a2 = 0.0;

  // State delay registers
  double _x1 = 0.0;
  double _x2 = 0.0;
  double _y1 = 0.0;
  double _y2 = 0.0;

  BiquadFilter.lowpass({required double sampleRate, required double cutoffHz}) {
    _calculateLowpass(sampleRate, cutoffHz);
  }

  BiquadFilter.highpass({required double sampleRate, required double cutoffHz}) {
    _calculateHighpass(sampleRate, cutoffHz);
  }

  void _calculateLowpass(double fs, double fc) {
    // 2nd-order Butterworth low-pass filter (Q = 1 / sqrt(2) ≈ 0.7071)
    final double omega = 2.0 * math.pi * fc / fs;
    final double k = math.tan(omega / 2.0);
    final double k2 = k * k;
    final double sqrt2K = math.sqrt(2.0) * k;
    final double norm = 1.0 / (1.0 + sqrt2K + k2);

    b0 = k2 * norm;
    b1 = 2.0 * b0;
    b2 = b0;
    a1 = 2.0 * (k2 - 1.0) * norm;
    a2 = (1.0 - sqrt2K + k2) * norm;
  }

  void _calculateHighpass(double fs, double fc) {
    // 2nd-order Butterworth high-pass filter (Q = 1 / sqrt(2) ≈ 0.7071)
    final double omega = 2.0 * math.pi * fc / fs;
    final double k = math.tan(omega / 2.0);
    final double k2 = k * k;
    final double sqrt2K = math.sqrt(2.0) * k;
    final double norm = 1.0 / (1.0 + sqrt2K + k2);

    b0 = 1.0 * norm;
    b1 = -2.0 * b0;
    b2 = b0;
    a1 = 2.0 * (k2 - 1.0) * norm;
    a2 = (1.0 - sqrt2K + k2) * norm;
  }

  /// Processes a single input sample through the IIR difference equation
  double filter(double input) {
    final double output = (b0 * input) + (b1 * _x1) + (b2 * _x2) - (a1 * _y1) - (a2 * _y2);

    // Shift state history
    _x2 = _x1;
    _x1 = input;
    _y2 = _y1;
    _y1 = output;

    return output;
  }

  /// Resets internal state memory registers
  void reset() {
    _x1 = 0.0;
    _x2 = 0.0;
    _y1 = 0.0;
    _y2 = 0.0;
  }
}

/// Cascaded Bandpass filter for PPG cardiac signals (0.7 Hz to 3.5 Hz)
/// 0.7 Hz (42 BPM) removes respiration, baseline drift, and DC offset
/// 3.5 Hz (210 BPM) attenuates high-frequency noise and 50/60Hz AC flicker
class PpgBandpassFilter {
  late BiquadFilter _highpass;
  late BiquadFilter _lowpass;

  final double sampleRate;
  final double lowCutoff;
  final double highCutoff;

  PpgBandpassFilter({
    this.sampleRate = 30.0,
    this.lowCutoff = 0.7,
    this.highCutoff = 3.5,
  }) {
    _highpass = BiquadFilter.highpass(sampleRate: sampleRate, cutoffHz: lowCutoff);
    _lowpass = BiquadFilter.lowpass(sampleRate: sampleRate, cutoffHz: highCutoff);
  }

  double process(double sample) {
    final double dcRemoved = _highpass.filter(sample);
    final double bandpassed = _lowpass.filter(dcRemoved);
    return bandpassed;
  }

  void reset() {
    _highpass.reset();
    _lowpass.reset();
  }
}
