import 'package:flutter_test/flutter_test.dart';
import 'package:quizapp/core/utils/scoring_utils.dart';

void main() {
  group('Kahoot-style Scoring Algorithm Tests', () {
    const int basePoints = 1000;
    const double timeLimit = 20.0;

    test('Incorrect answer yields 0 points regardless of speed', () {
      final scoreInstant = ScoringUtils.calculateScore(
        basePoints: basePoints,
        responseTimeSeconds: 0.1,
        timeLimitSeconds: timeLimit,
        isCorrect: false,
      );
      expect(scoreInstant, equals(0));

      final scoreSlow = ScoringUtils.calculateScore(
        basePoints: basePoints,
        responseTimeSeconds: 19.9,
        timeLimitSeconds: timeLimit,
        isCorrect: false,
      );
      expect(scoreSlow, equals(0));
    });

    test('Instant correct response awards maximum base points (100%)', () {
      final score = ScoringUtils.calculateScore(
        basePoints: basePoints,
        responseTimeSeconds: 0.0,
        timeLimitSeconds: timeLimit,
        isCorrect: true,
      );
      expect(score, equals(1000));
    });

    test('Half-time correct response awards 75% of base points', () {
      final score = ScoringUtils.calculateScore(
        basePoints: basePoints,
        responseTimeSeconds: 10.0,
        timeLimitSeconds: timeLimit,
        isCorrect: true,
      );
      expect(score, equals(750));
    });

    test('Last-second correct response awards 50% minimum points', () {
      final score = ScoringUtils.calculateScore(
        basePoints: basePoints,
        responseTimeSeconds: 20.0,
        timeLimitSeconds: timeLimit,
        isCorrect: true,
      );
      expect(score, equals(500));
    });

    test('Late response exceeding timeLimit clamps to 50% points', () {
      final score = ScoringUtils.calculateScore(
        basePoints: basePoints,
        responseTimeSeconds: 25.0,
        timeLimitSeconds: timeLimit,
        isCorrect: true,
      );
      expect(score, equals(500));
    });

    test('Negative response time clamps safely to instant response (100%)', () {
      final score = ScoringUtils.calculateScore(
        basePoints: basePoints,
        responseTimeSeconds: -2.0,
        timeLimitSeconds: timeLimit,
        isCorrect: true,
      );
      expect(score, equals(1000));
    });
  });
}
