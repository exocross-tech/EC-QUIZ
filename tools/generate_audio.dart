import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Generates crisp, synthesized WAV sound effects for EC QUIZ.
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

  // 7. Looping Background Game Music (Upbeat 4-bar progression in C-G-Am-F)
  final bgmBytes = synthesizeBgmLoop();
  File('assets/audio/bgm_loop.wav').writeAsBytesSync(bgmBytes);

  stdout.writeln('Successfully generated audio assets (including bgm_loop.wav) in assets/audio/!');
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

Uint8List synthesizeBgmLoop({int sampleRate = 22050}) {
  const bpm = 124.0;
  const beatSec = 60.0 / bpm; // ~0.48387s
  const totalBeats = 16; // 4 bars of 4 beats
  final totalDuration = beatSec * totalBeats;
  final numSamples = (sampleRate * totalDuration).round();
  final buffer = List<double>.filled(numSamples, 0.0);

  // 1. Bass track (C3, G2, A2, F2 with fun rhythmic cadence)
  final bassNotes = [
    130.81, 130.81, 130.81, 130.81, // C3
    98.00,  98.00,  98.00,  123.47, // G2, G2, G2, B2
    110.00, 110.00, 110.00, 110.00, // A2
    87.31,  87.31,  87.31,  110.00, // F2, F2, F2, A2
  ];

  for (int beat = 0; beat < totalBeats; beat++) {
    final noteFreq = bassNotes[beat];
    final startIdx = (beat * beatSec * sampleRate).round();
    final noteLength = (beatSec * 0.85 * sampleRate).round();
    for (int i = 0; i < noteLength; i++) {
      final idx = startIdx + i;
      if (idx >= numSamples) break;
      final t = i / sampleRate;
      final env = exp(-i / (sampleRate * 0.28));
      final bassWave = 0.7 * sin(2 * pi * noteFreq * t) + 0.3 * sin(2 * pi * (noteFreq * 2) * t);
      buffer[idx] += bassWave * env * 0.32;
    }
  }

  // 2. Upbeat playful 16th-note arpeggio / melody
  final arpeggios = [
    // Bar 1: C Major (C4, E4, G4, C5...)
    [261.63, 329.63, 392.00, 523.25, 392.00, 329.63, 523.25, 659.25, 523.25, 392.00, 329.63, 261.63, 329.63, 392.00, 523.25, 659.25],
    // Bar 2: G Major (G3, B3, D4, G4...)
    [196.00, 246.94, 293.66, 392.00, 293.66, 246.94, 392.00, 587.33, 392.00, 293.66, 246.94, 196.00, 246.94, 293.66, 392.00, 493.88],
    // Bar 3: A Minor (A3, C4, E4, A4...)
    [220.00, 261.63, 329.63, 440.00, 329.63, 261.63, 440.00, 659.25, 440.00, 329.63, 261.63, 220.00, 261.63, 329.63, 440.00, 523.25],
    // Bar 4: F Major (F3, A3, C4, F4...)
    [174.61, 220.00, 261.63, 349.23, 261.63, 220.00, 349.23, 523.25, 349.23, 261.63, 220.00, 261.63, 329.63, 392.00, 493.88, 523.25],
  ];

  final sixteenthSec = beatSec / 4.0;
  for (int bar = 0; bar < 4; bar++) {
    final barNotes = arpeggios[bar];
    for (int s = 0; s < 16; s++) {
      final freq = barNotes[s];
      final globalS = bar * 16 + s;
      final startIdx = (globalS * sixteenthSec * sampleRate).round();
      final len = (sixteenthSec * 0.9 * sampleRate).round();
      for (int i = 0; i < len; i++) {
        final idx = startIdx + i;
        if (idx >= numSamples) break;
        final t = i / sampleRate;
        final env = exp(-i / (sampleRate * 0.08));
        final wave = 0.6 * sin(2 * pi * freq * t) +
            0.3 * sin(2 * pi * (freq * 2) * t) +
            0.1 * sin(2 * pi * (freq * 3) * t);
        buffer[idx] += wave * env * 0.22;
      }
    }
  }

  // 3. Gentle rhythmic percussion
  final eighthSec = beatSec / 2.0;
  for (int e = 0; e < totalBeats * 2; e++) {
    final startIdx = (e * eighthSec * sampleRate).round();
    final isBeat = (e % 2 == 0);
    final beatNum = e ~/ 2;
    final isBackbeat = (beatNum % 2 == 1 && isBeat); // Beats 2, 4, 6, 8...

    if (isBackbeat) {
      final len = (0.06 * sampleRate).round();
      final random = Random(42 + e);
      for (int i = 0; i < len; i++) {
        final idx = startIdx + i;
        if (idx >= numSamples) break;
        final env = exp(-i / (sampleRate * 0.02));
        final noise = (random.nextDouble() * 2.0 - 1.0);
        buffer[idx] += noise * env * 0.12;
      }
    } else {
      final len = (0.02 * sampleRate).round();
      for (int i = 0; i < len; i++) {
        final idx = startIdx + i;
        if (idx >= numSamples) break;
        final t = i / sampleRate;
        final env = exp(-i / (sampleRate * 0.005));
        buffer[idx] += sin(2 * pi * 1800 * t) * env * 0.04;
      }
    }
  }

  // 4. Smooth loop boundary crossfade (50ms) to ensure seamless endless looping without pop
  final xfadeSamples = (0.05 * sampleRate).round();
  for (int i = 0; i < xfadeSamples; i++) {
    final frac = i / xfadeSamples;
    final tailIdx = numSamples - xfadeSamples + i;
    final headIdx = i;
    final combinedHead = buffer[headIdx] * frac + buffer[tailIdx] * (1.0 - frac);
    buffer[headIdx] = combinedHead;
  }
  final trimmedSamples = numSamples - xfadeSamples;

  final finalSamples = <int>[];
  for (int i = 0; i < trimmedSamples; i++) {
    final val = (buffer[i].clamp(-1.0, 1.0) * 22000).round();
    finalSamples.add(val);
  }

  return buildWav(samples: finalSamples, sampleRate: sampleRate);
}

