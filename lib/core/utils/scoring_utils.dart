/// Scoring utility for Kahoot-style speed and correctness calculations.
class ScoringUtils {
  /// Calculates points earned for a question answer.
  ///
  /// Formula:
  /// - If incorrect: 0 points.
  /// - If correct: `basePoints * (0.5 + 0.5 * (1 - responseTime / timeLimit))`
  ///
  /// Constraints:
  /// - responseTime is clamped between 0 and timeLimit.
  /// - Returns integer score rounded to the nearest whole point.
  static int calculateScore({
    required int basePoints,
    required double responseTimeSeconds,
    required double timeLimitSeconds,
    required bool isCorrect,
  }) {
    if (!isCorrect) return 0;
    if (basePoints <= 0) return 0;
    if (timeLimitSeconds <= 0) return basePoints;

    // Clamp response time within [0, timeLimit]
    final clampedTime = responseTimeSeconds.clamp(0.0, timeLimitSeconds);
    final timeRatio = clampedTime / timeLimitSeconds;

    // Speed multiplier starts at 1.0 (instant answer) down to 0.5 (at time limit)
    final speedMultiplier = 0.5 + 0.5 * (1.0 - timeRatio);

    return (basePoints * speedMultiplier).round();
  }
}
