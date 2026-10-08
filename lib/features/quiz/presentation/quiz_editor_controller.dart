import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/firestore_quiz_repository.dart';
import '../domain/quiz.dart';
import '../domain/quiz_question.dart';

class QuizEditorState {
  final Quiz quiz;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final bool saveSuccess;
  final bool hasUnsavedChanges;

  const QuizEditorState({
    required this.quiz,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.saveSuccess = false,
    this.hasUnsavedChanges = false,
  });

  QuizEditorState copyWith({
    Quiz? quiz,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    bool? saveSuccess,
    bool? hasUnsavedChanges,
  }) {
    return QuizEditorState(
      quiz: quiz ?? this.quiz,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      saveSuccess: saveSuccess ?? this.saveSuccess,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
    );
  }
}

class QuizEditorController extends Notifier<QuizEditorState> {
  final String? quizId;

  QuizEditorController(this.quizId);

  @override
  QuizEditorState build() {
    final user = ref.watch(authStateProvider).asData?.value;
    final profile = ref.watch(currentUserProfileProvider).asData?.value;

    final initialQuiz = Quiz.createDraft(
      creatorId: user?.id ?? '',
      creatorName: profile?.displayName ?? user?.displayName ?? 'Host',
    );

    if (quizId != null && quizId!.isNotEmpty) {
      Future.microtask(() => _loadQuiz(quizId!));
      return QuizEditorState(
        quiz: initialQuiz.copyWith(id: quizId),
        isLoading: true,
      );
    }

    return QuizEditorState(quiz: initialQuiz);
  }

  Future<void> _loadQuiz(String id) async {
    try {
      final loaded = await ref.read(quizRepositoryProvider).getQuiz(id);
      if (loaded != null) {
        state = state.copyWith(
          quiz: loaded,
          isLoading: false,
          hasUnsavedChanges: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Quiz not found.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load quiz: $e',
      );
    }
  }

  void updateTitle(String title) {
    state = state.copyWith(
      quiz: state.quiz.copyWith(title: title),
      hasUnsavedChanges: true,
      clearError: true,
    );
  }

  void updateDescription(String desc) {
    state = state.copyWith(
      quiz: state.quiz.copyWith(description: desc),
      hasUnsavedChanges: true,
      clearError: true,
    );
  }

  void updateThemeColor(int color) {
    state = state.copyWith(
      quiz: state.quiz.copyWith(themeColor: color),
      hasUnsavedChanges: true,
      clearError: true,
    );
  }

  void addQuestion(QuizQuestion question) {
    final updated = List<QuizQuestion>.from(state.quiz.questions)..add(question);
    state = state.copyWith(
      quiz: state.quiz.copyWith(questions: updated),
      hasUnsavedChanges: true,
      clearError: true,
    );
  }

  void updateQuestion(int index, QuizQuestion question) {
    if (index < 0 || index >= state.quiz.questions.length) return;
    final updated = List<QuizQuestion>.from(state.quiz.questions);
    updated[index] = question;
    state = state.copyWith(
      quiz: state.quiz.copyWith(questions: updated),
      hasUnsavedChanges: true,
      clearError: true,
    );
  }

  void removeQuestion(int index) {
    if (index < 0 || index >= state.quiz.questions.length) return;
    final updated = List<QuizQuestion>.from(state.quiz.questions)..removeAt(index);
    state = state.copyWith(
      quiz: state.quiz.copyWith(questions: updated),
      hasUnsavedChanges: true,
      clearError: true,
    );
  }

  void duplicateQuestion(int index) {
    if (index < 0 || index >= state.quiz.questions.length) return;
    final original = state.quiz.questions[index];
    final duplicated = original.duplicate();
    final updated = List<QuizQuestion>.from(state.quiz.questions)
      ..insert(index + 1, duplicated);
    state = state.copyWith(
      quiz: state.quiz.copyWith(questions: updated),
      hasUnsavedChanges: true,
      clearError: true,
    );
  }

  void reorderQuestions(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.quiz.questions.length) return;
    final updated = List<QuizQuestion>.from(state.quiz.questions);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    state = state.copyWith(
      quiz: state.quiz.copyWith(questions: updated),
      hasUnsavedChanges: true,
      clearError: true,
    );
  }

  void moveQuestionUp(int index) {
    if (index <= 0) return;
    reorderQuestions(index, index - 1);
  }

  void moveQuestionDown(int index) {
    if (index >= state.quiz.questions.length - 1) return;
    reorderQuestions(index, index + 2);
  }

  Future<bool> saveDraft() async {
    return _save(isDraft: true);
  }

  Future<bool> publish() async {
    final validationErr = state.quiz.publishValidationError;
    if (validationErr != null) {
      state = state.copyWith(errorMessage: validationErr);
      return false;
    }
    return _save(isDraft: false);
  }

  Future<bool> _save({required bool isDraft}) async {
    // Document quota pre-flight check
    if (!state.quiz.isUnderDocLimit) {
      final kb = (state.quiz.estimatedSizeBytes / 1024).toStringAsFixed(1);
      state = state.copyWith(
        errorMessage:
            'Quiz data size ($kb KB) exceeds Firestore\'s 1 MB limit. Please remove or compress some images before saving.',
      );
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final user = ref.read(authStateProvider).asData?.value;
      final profile = ref.read(currentUserProfileProvider).asData?.value;

      final toSave = state.quiz.copyWith(
        creatorId: user?.id ?? state.quiz.creatorId,
        creatorName: profile?.displayName ??
            user?.displayName ??
            state.quiz.creatorName,
        isDraft: isDraft,
        updatedAt: DateTime.now(),
      );

      await ref.read(quizRepositoryProvider).saveQuiz(toSave);
      state = state.copyWith(
        quiz: toSave,
        isSaving: false,
        saveSuccess: true,
        hasUnsavedChanges: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

final quizEditorControllerProvider =
    NotifierProvider.family<QuizEditorController, QuizEditorState, String?>(
  QuizEditorController.new,
);
