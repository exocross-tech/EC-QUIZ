import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Generates crisp, synthesized WAV sound effects for Quiz Clash.
void main() {
  final audioDir = Directory('assets/audio');
  if (!audioDir.existsSync()) {
    audioDir.createSync(recursive: true);
  }

  // 1. Correct Answer Chime (Major triad arpeggio: C6 -> E6 -> G6 -> C7)
  final correctBytes = synthesizeArpeggio(
    notes: [1046.50, 1318.51, 1567.98, 2093.00],
    noteDurationMs: 90,
    decayMs: 250,
  );
  File('assets/audio/correct.wav').writeAsBytesSync(correctBytes);

  // 2. Incorrect Answer Buzz (Descending low harsh dissonance)
  final incorrectBytes = synthesizeBuzzer(
    freq1: 180.0,
    freq2: 120.0,
    durationMs: 380,
  );
  File('assets/audio/incorrect.wav').writeAsBytesSync(incorrectBytes);

  // 3. Tick Sound (Percussive woodblock click)
  final tickBytes = synthesizeClick(
    freq: 1100.0,
    durationMs: 40,
  );
  File('assets/audio/tick.wav').writeAsBytesSync(tickBytes);

  // 4. Streak Level Up (Upward frequency sweep + sparkle)
  final streakBytes = synthesizeSweep(
    startFreq: 440.0,
    endFreq: 1760.0,
    durationMs: 320,
  );
  File('assets/audio/streak.wav').writeAsBytesSync(streakBytes);

  // 5. Fanfare Victory (Celebratory fanfare melody: G4 -> C5 -> E5 -> G5 -> C6)
  final fanfareBytes = synthesizeArpeggio(
    notes: [392.00, 523.25, 659.25, 783.99, 1046.50],
    noteDurationMs: 140,
    decayMs: 450,
  );
  File('assets/audio/fanfare.wav').writeAsBytesSync(fanfareBytes);

  // 6. UI Button Click
  final clickBytes = synthesizeClick(
    freq: 1400.0,
    durationMs: 25,
  );
  File('assets/audio/click.wav').writeAsBytesSync(clickBytes);

  stdout.writeln('Successfully generated 6 WAV sound effects in assets/audio/!');
}

Uint8List buildWav({required List<int> samples, int sampleRate = 22050}) {
  final dataLength = samples.length * 2; // 16-bit = 2 bytes per sample
  final fileLength = 36 + dataLength;

  final buffer = BytesBuilder();

  // RIFF Header
  buffer.add('RIFF'.codeUnits);
  buffer.add(int32ToBytes(fileLength));
  buffer.add('WAVE'.codeUnits);

  // fmt subchunk
  buffer.add('fmt '.codeUnits);
  buffer.add(int32ToBytes(16)); // Subchunk1Size for PCM
  buffer.add(int16ToBytes(1)); // AudioFormat = 1 (PCM)
  buffer.add(int16ToBytes(1)); // NumChannels = 1 (Mono)
  buffer.add(int32ToBytes(sampleRate)); // SampleRate
  buffer.add(int32ToBytes(sampleRate * 2)); // ByteRate = SampleRate * NumChannels * BitsPerSample/8
  buffer.add(int16ToBytes(2)); // BlockAlign = NumChannels * BitsPerSample/8
  buffer.add(int16ToBytes(16)); // BitsPerSample = 16

  // data subchunk
  buffer.add('data'.codeUnits);
  buffer.add(int32ToBytes(dataLength));

  for (final sample in samples) {
    buffer.add(int16ToBytes(sample.clamp(-32768, 32767)));
  }

  return buffer.toBytes();
}

List<int> int16ToBytes(int value) {
  final bytes = Uint8List(2);
  final byteData = ByteData.view(bytes.buffer);
  byteData.setInt16(0, value, Endian.little);
  return bytes;
}

List<int> int32ToBytes(int value) {
  final bytes = Uint8List(4);
  final byteData = ByteData.view(bytes.buffer);
  byteData.setInt32(0, value, Endian.little);
  return bytes;
}

Uint8List synthesizeArpeggio({
  required List<double> notes,
  required int noteDurationMs,
  required int decayMs,
  int sampleRate = 22050,
}) {
  final samples = <int>[];
  final noteSamples = (sampleRate * (noteDurationMs / 1000.0)).round();

  for (int n = 0; n < notes.length; n++) {
    final freq = notes[n];
    final isLast = n == notes.length - 1;
    final totalNoteSamples = isLast
        ? noteSamples + (sampleRate * (decayMs / 1000.0)).round()
        : noteSamples;

    for (int i = 0; i < totalNoteSamples; i++) {
      final t = i / sampleRate;
      final envelope = exp(-i / (sampleRate * 0.18));
      // Fundamental + gentle harmonics
      final wave = 0.7 * sin(2 * pi * freq * t) +
          0.25 * sin(2 * pi * (freq * 2) * t) +
          0.05 * sin(2 * pi * (freq * 3) * t);
      final sample = (wave * envelope * 24000).round();
      samples.add(sample);
    }
  }

  return buildWav(samples: samples, sampleRate: sampleRate);
}

Uint8List synthesizeBuzzer({
  required double freq1,
  required double freq2,
  required int durationMs,
  int sampleRate = 22050,
}) {
  final samples = <int>[];
  final totalSamples = (sampleRate * (durationMs / 1000.0)).round();

  for (int i = 0; i < totalSamples; i++) {
    final t = i / sampleRate;
    final progress = i / totalSamples;
    final currentFreq = freq1 + (freq2 - freq1) * progress;
    final envelope = (1.0 - progress);

    // Sawtooth-like harsh buzzer
    final phase = (currentFreq * t) % 1.0;
    final wave = (phase < 0.5 ? 1.0 : -1.0) * 0.8;
    final sample = (wave * envelope * 22000).round();
    samples.add(sample);
  }

  return buildWav(samples: samples, sampleRate: sampleRate);
}

Uint8List synthesizeClick({
  required double freq,
  required int durationMs,
  int sampleRate = 22050,
}) {
  final samples = <int>[];
  final totalSamples = (sampleRate * (durationMs / 1000.0)).round();

  for (int i = 0; i < totalSamples; i++) {
    final t = i / sampleRate;
    final envelope = exp(-i / (totalSamples * 0.25));
    final wave = sin(2 * pi * freq * t);
    final sample = (wave * envelope * 20000).round();
    samples.add(sample);
  }

  return buildWav(samples: samples, sampleRate: sampleRate);
}

Uint8List synthesizeSweep({
  required double startFreq,
  required double endFreq,
  required int durationMs,
  int sampleRate = 22050,
}) {
  final samples = <int>[];
  final totalSamples = (sampleRate * (durationMs / 1000.0)).round();

  double phase = 0.0;
  for (int i = 0; i < totalSamples; i++) {
    final progress = i / totalSamples;
    final currentFreq = startFreq + (endFreq - startFreq) * (progress * progress);
    phase += (2 * pi * currentFreq) / sampleRate;

    final envelope = sin(pi * progress);
    final wave = sin(phase) + 0.3 * sin(phase * 2);
    final sample = (wave * envelope * 25000).round();
    samples.add(sample);
  }

  return buildWav(samples: samples, sampleRate: sampleRate);
}
