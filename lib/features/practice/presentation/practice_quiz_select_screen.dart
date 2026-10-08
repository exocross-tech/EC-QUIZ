import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../quiz/domain/quiz.dart';
import '../../quiz/presentation/quiz_list_controller.dart';
import '../data/sample_quizzes.dart';

class PracticeQuizSelectScreen extends ConsumerStatefulWidget {
  const PracticeQuizSelectScreen({super.key});

  @override
  ConsumerState<PracticeQuizSelectScreen> createState() =>
      _PracticeQuizSelectScreenState();
}

class _PracticeQuizSelectScreenState
    extends ConsumerState<PracticeQuizSelectScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All'; // 'All', 'Starter', 'My Quizzes', 'Community'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userQuizzesAsync = ref.watch(userQuizzesProvider);
    final publishedQuizzesAsync = ref.watch(publishedQuizzesProvider);
    final currentUserId = ref.watch(authStateProvider).asData?.value?.id;

    final query = _searchController.text.trim().toLowerCase();

    // 1. Gather all quizzes
    final starterQuizzes = SampleQuizzes.all;
    final userQuizzes = userQuizzesAsync.asData?.value ?? [];
    final publishedQuizzes = (publishedQuizzesAsync.asData?.value ?? [])
        .where((q) => q.creatorId != currentUserId)
        .toList();

    // 2. Filter by Category / Tab
    List<Quiz> displayedQuizzes;
    switch (_selectedFilter) {
      case 'Starter':
        displayedQuizzes = starterQuizzes;
        break;
      case 'My Quizzes':
        displayedQuizzes = userQuizzes;
        break;
      case 'Community':
        displayedQuizzes = publishedQuizzes;
        break;
      case 'All':
      default:
        // Combine all, avoiding duplicates
        final Set<String> seenIds = {};
        displayedQuizzes = [];
        for (final q in [...starterQuizzes, ...userQuizzes, ...publishedQuizzes]) {
          if (!seenIds.contains(q.id)) {
            seenIds.add(q.id);
            displayedQuizzes.add(q);
          }
        }
        break;
    }

    // 3. Filter by Search Query
    if (query.isNotEmpty) {
      displayedQuizzes = displayedQuizzes.where((q) {
        return q.title.toLowerCase().contains(query) ||
            q.description.toLowerCase().contains(query);
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.speed_rounded, color: AppColors.gameYellow),
            SizedBox(width: 10),
            Text('Solo Practice'),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.12),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search Field
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search quizzes by title or topic...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', Icons.grid_view_rounded),
                      const SizedBox(width: 8),
                      _buildFilterChip('Starter', Icons.flash_on_rounded),
                      const SizedBox(width: 8),
                      _buildFilterChip('My Quizzes', Icons.person_rounded),
                      const SizedBox(width: 8),
                      _buildFilterChip('Community', Icons.public_rounded),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Quizzes List
          Expanded(
            child: displayedQuizzes.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayedQuizzes.length,
                    itemBuilder: (context, index) {
                      final quiz = displayedQuizzes[index];
                      return _buildQuizCard(context, quiz);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedFilter == label;
    final theme = Theme.of(context);

    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : theme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 13,
        ),
      ),
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      selectedColor: AppColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.transparent,
        ),
      ),
      onSelected: (_) {
        setState(() {
          _selectedFilter = label;
        });
      },
    );
  }

  Widget _buildQuizCard(BuildContext context, Quiz quiz) {
    final theme = Theme.of(context);
    final cardColor = Color(quiz.themeColor);
    final isStarter = quiz.id.startsWith('sample_');

    final minutes = (quiz.totalTimeSeconds / 60).ceil();

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.grey.withValues(alpha: 0.12),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          context.push('/practice/${quiz.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Leading Color Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cardColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isStarter ? Icons.bolt_rounded : Icons.quiz_rounded,
                      color: cardColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Title and author
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isStarter
                                    ? AppColors.gameYellow.withValues(alpha: 0.18)
                                    : Colors.blue.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isStarter ? 'INSTANT PLAY' : quiz.creatorName,
                                style: TextStyle(
                                  color: isStarter
                                      ? Colors.amber.shade900
                                      : Colors.blue.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Start practice CTA button
                  ElevatedButton(
                    onPressed: () {
                      context.push('/practice/${quiz.id}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Practice',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.play_arrow_rounded, size: 18),
                      ],
                    ),
                  ),
                ],
              ),

              if (quiz.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  quiz.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Bottom Stats Row
              Row(
                children: [
                  Icon(
                    Icons.format_list_numbered_rounded,
                    size: 15,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${quiz.questionsCount} Questions',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.timer_outlined,
                    size: 15,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '~$minutes min',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 15,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${quiz.totalPoints} pts',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No quizzes found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try clearing your search query or selecting a different filter.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
