import '../../quiz/domain/quiz.dart';
import '../../quiz/domain/quiz_question.dart';

/// Pre-bundled starter quizzes available offline or anytime for solo practice.
class SampleQuizzes {
  static final DateTime _epoch = DateTime(2025, 1, 1);

  /// 1. General Knowledge & Trivia (Mixed Question Types)
  static final Quiz generalTrivia = Quiz(
    id: 'sample_general_trivia',
    creatorId: 'system',
    creatorName: 'EC QUIZ Team',
    title: 'General Trivia & Wonders',
    description: 'Test your knowledge across science, astronomy, nature, and history!',
    themeColor: 0xFF6C4AB6,
    isDraft: false,
    createdAt: _epoch,
    updatedAt: _epoch,
    questions: [
      QuizQuestion(
        id: 'trivia_q1',
        text: 'Which planet in our solar system is nicknamed the "Red Planet"?',
        type: QuestionType.multipleChoice,
        options: ['Venus', 'Mars', 'Jupiter', 'Saturn'],
        correctAnswers: [1],
        timeLimitSeconds: 20,
        basePoints: 1000,
        explanation: 'Mars appears red because its surface rocks are rich in iron oxide (rust).',
      ),
      QuizQuestion(
        id: 'trivia_q2',
        text: 'The Great Wall of China is visible from the Moon with the naked eye.',
        type: QuestionType.trueFalse,
        options: ['True', 'False'],
        correctAnswers: [1],
        timeLimitSeconds: 15,
        basePoints: 1000,
        explanation: 'This is a widely believed myth. Multiple astronauts have confirmed it is too narrow to see without high-powered optics.',
      ),
      QuizQuestion(
        id: 'trivia_q3',
        text: 'Which of the following are primary colors of light in the RGB color model?',
        type: QuestionType.multipleSelect,
        options: ['Red', 'Yellow', 'Green', 'Blue'],
        correctAnswers: [0, 2, 3],
        timeLimitSeconds: 25,
        basePoints: 1200,
        explanation: 'In the additive light model (RGB), Red, Green, and Blue combine to create all other visible colors.',
      ),
      QuizQuestion(
        id: 'trivia_q4',
        text: 'How many sides does a standard hexagon have?',
        type: QuestionType.numeric,
        options: ['6'],
        correctAnswers: [0],
        timeLimitSeconds: 20,
        basePoints: 1000,
        explanation: 'A hexagon has exactly 6 sides and 6 internal angles.',
      ),
      QuizQuestion(
        id: 'trivia_q5',
        text: 'What is the chemical element symbol for Gold?',
        type: QuestionType.shortText,
        options: ['Au', 'AU', 'au'],
        correctAnswers: [0],
        timeLimitSeconds: 20,
        basePoints: 1000,
        explanation: 'Au comes from the Latin word "Aurum", which means shining dawn.',
      ),
      QuizQuestion(
        id: 'trivia_q6',
        text: 'Arrange these historical events in chronological order from earliest to latest:',
        type: QuestionType.ordering,
        options: [
          'Invention of the Printing Press',
          'First Human in Space (Yuri Gagarin)',
          'Apollo 11 Moon Landing',
          'Launch of the first iPhone',
        ],
        correctAnswers: [0, 1, 2, 3],
        timeLimitSeconds: 30,
        basePoints: 1500,
        explanation: 'Printing Press (c. 1440) ➔ Gagarin (1961) ➔ Apollo 11 (1969) ➔ iPhone (2007).',
      ),
    ],
  );

  /// 2. Science & Nature Expedition
  static final Quiz scienceNature = Quiz(
    id: 'sample_science_nature',
    creatorId: 'system',
    creatorName: 'EC QUIZ Team',
    title: 'Science & Nature Expedition',
    description: 'Explore the elements, biology, temperature, and planetary distances.',
    themeColor: 0xFF00C897,
    isDraft: false,
    createdAt: _epoch,
    updatedAt: _epoch,
    questions: [
      QuizQuestion(
        id: 'science_q1',
        text: 'What is the hardest naturally occurring substance on Earth?',
        type: QuestionType.multipleChoice,
        options: ['Titanium', 'Diamond', 'Granite', 'Tungsten'],
        correctAnswers: [1],
        timeLimitSeconds: 20,
        basePoints: 1000,
        explanation: 'Diamond ranks at 10 on the Mohs mineral hardness scale, the highest possible.',
      ),
      QuizQuestion(
        id: 'science_q2',
        text: 'At what temperature in Celsius does pure water freeze at standard atmospheric pressure?',
        type: QuestionType.numeric,
        options: ['0'],
        correctAnswers: [0],
        timeLimitSeconds: 15,
        basePoints: 1000,
        explanation: 'Pure water freezes at 0 degrees Celsius (32 degrees Fahrenheit).',
      ),
      QuizQuestion(
        id: 'science_q3',
        text: 'Which of the following animals are classified as mammals?',
        type: QuestionType.multipleSelect,
        options: ['Bottlenose Dolphin', 'Great White Shark', 'Fruit Bat', 'Emperor Penguin'],
        correctAnswers: [0, 2],
        timeLimitSeconds: 25,
        basePoints: 1200,
        explanation: 'Dolphins and bats give birth to live young and nurse them; sharks are cartilaginous fish and penguins are birds.',
      ),
      QuizQuestion(
        id: 'science_q4',
        text: 'Sort these planets by their distance from the Sun (closest to farthest):',
        type: QuestionType.ordering,
        options: ['Mercury', 'Earth', 'Jupiter', 'Neptune'],
        correctAnswers: [0, 1, 2, 3],
        timeLimitSeconds: 30,
        basePoints: 1500,
        explanation: 'Mercury (1st) ➔ Earth (3rd) ➔ Jupiter (5th) ➔ Neptune (8th).',
      ),
    ],
  );

  /// 3. Coding & Tech Essentials
  static final Quiz techCoding = Quiz(
    id: 'sample_tech_coding',
    creatorId: 'system',
    creatorName: 'EC QUIZ Team',
    title: 'Tech, Code & Digital Bits',
    description: 'A quick speed-run on web protocols, programming keywords, and data units.',
    themeColor: 0xFF2A85FF,
    isDraft: false,
    createdAt: _epoch,
    updatedAt: _epoch,
    questions: [
      QuizQuestion(
        id: 'tech_q1',
        text: 'What does the acronym HTTP stand for in networking?',
        type: QuestionType.multipleChoice,
        options: [
          'HyperText Transfer Protocol',
          'High Terminal Tracking Process',
          'Hyperlink Telecommunication Protocol',
          'Hosting Transmission Technical Port',
        ],
        correctAnswers: [0],
        timeLimitSeconds: 20,
        basePoints: 1000,
        explanation: 'HTTP stands for HyperText Transfer Protocol, the foundation of data communication on the World Wide Web.',
      ),
      QuizQuestion(
        id: 'tech_q2',
        text: 'Dart is an object-oriented, class-based programming language created by Google.',
        type: QuestionType.trueFalse,
        options: ['True', 'False'],
        correctAnswers: [0],
        timeLimitSeconds: 15,
        basePoints: 1000,
        explanation: 'Dart was created by Google and powers Flutter cross-platform applications.',
      ),
      QuizQuestion(
        id: 'tech_q3',
        text: 'What keyword in Dart is used to declare a compile-time constant?',
        type: QuestionType.shortText,
        options: ['const', 'CONST'],
        correctAnswers: [0],
        timeLimitSeconds: 20,
        basePoints: 1000,
        explanation: 'The "const" keyword in Dart denotes compile-time constants.',
      ),
      QuizQuestion(
        id: 'tech_q4',
        text: 'Order these digital storage units from smallest to largest:',
        type: QuestionType.ordering,
        options: ['Kilobyte (KB)', 'Megabyte (MB)', 'Gigabyte (GB)', 'Terabyte (TB)'],
        correctAnswers: [0, 1, 2, 3],
        timeLimitSeconds: 25,
        basePoints: 1500,
        explanation: '1 KB (1024 B) < 1 MB (1024 KB) < 1 GB (1024 MB) < 1 TB (1024 GB).',
      ),
    ],
  );

  /// All sample quizzes list
  static List<Quiz> get all => [generalTrivia, scienceNature, techCoding];

  /// Find a sample quiz by its ID
  static Quiz? getById(String id) {
    try {
      return all.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }
}
