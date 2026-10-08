import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quizapp/features/auth/presentation/auth_controller.dart';
import 'package:quizapp/features/contest/data/firestore_contest_repository.dart';

class PlayerGameState {
  final bool isSubmitting;
  final bool hasSubmitted;
  final List<dynamic> selectedOptions;
  final String? errorMessage;

  const PlayerGameState({
    this.isSubmitting = false,
    this.hasSubmitted = false,
    this.selectedOptions = const [],
    this.errorMessage,
  });

  PlayerGameState copyWith({
    bool? isSubmitting,
    bool? hasSubmitted,
    List<dynamic>? selectedOptions,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PlayerGameState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      hasSubmitted: hasSubmitted ?? this.hasSubmitted,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PlayerGameController extends Notifier<PlayerGameState> {
  @override
  PlayerGameState build() {
    return const PlayerGameState();
  }

  void resetForNewQuestion() {
    state = const PlayerGameState();
  }

  void toggleOption(dynamic optionValue, {required bool isMultiSelect}) {
    if (state.hasSubmitted) return;

    if (!isMultiSelect) {
      state = state.copyWith(selectedOptions: [optionValue]);
    } else {
      final current = List<dynamic>.from(state.selectedOptions);
      if (current.contains(optionValue)) {
        current.remove(optionValue);
      } else {
        current.add(optionValue);
      }
      state = state.copyWith(selectedOptions: current);
    }
  }

  void setOrdering(List<int> order) {
    if (state.hasSubmitted) return;
    state = state.copyWith(selectedOptions: order);
  }

  void setTextAnswer(String text) {
    if (state.hasSubmitted) return;
    state = state.copyWith(selectedOptions: [text.trim()]);
  }

  Future<bool> submitAnswer({
    required String contestId,
    required int questionIndex,
  }) async {
    if (state.selectedOptions.isEmpty || state.hasSubmitted) return false;

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final user = ref.read(authStateProvider).asData?.value;
      final profile = ref.read(currentUserProfileProvider).asData?.value;

      if (user == null) {
        throw Exception('Must be signed in to submit an answer.');
      }

      final repo = ref.read(contestRepositoryProvider);
      await repo.submitAnswer(
        contestId: contestId,
        participantId: user.id,
        participantName: profile?.displayName ?? user.displayName ?? 'Player',
        questionIndex: questionIndex,
        selectedAnswers: state.selectedOptions,
      );

      state = state.copyWith(
        isSubmitting: false,
        hasSubmitted: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

final playerGameControllerProvider =
    NotifierProvider<PlayerGameController, PlayerGameState>(
  PlayerGameController.new,
);
