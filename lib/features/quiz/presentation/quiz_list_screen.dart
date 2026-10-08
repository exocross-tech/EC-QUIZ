import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../domain/quiz.dart';
import 'quiz_list_controller.dart';

class QuizListScreen extends ConsumerStatefulWidget {
  const QuizListScreen({super.key});

  @override
  ConsumerState<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends ConsumerState<QuizListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(Quiz quiz) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: Text('Are you sure you want to delete "${quiz.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gameRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(quizListControllerProvider.notifier)
          .deleteQuiz(quiz.id);

      if (mounted && success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Quiz deleted.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _duplicateQuiz(Quiz quiz) async {
    final messenger = ScaffoldMessenger.of(context);
    final duplicated = await ref
        .read(quizListControllerProvider.notifier)
        .duplicateQuiz(quiz);

    if (mounted && duplicated != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Created duplicate: "${duplicated.title}"'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => context.push('/quiz/edit/${duplicated.id}'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quizzesAsync = ref.watch(userQuizzesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quiz Studio',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Published'),
            Tab(text: 'Drafts'),
          ],
        ),
      ),
      body: quizzesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.gameRed),
                const SizedBox(height: 12),
                Text('Failed to load quizzes: $err', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        data: (allQuizzes) {
          // Filter by search query
          final filtered = allQuizzes.where((q) {
            if (_searchQuery.isEmpty) return true;
            return q.title.toLowerCase().contains(_searchQuery) ||
                q.description.toLowerCase().contains(_searchQuery);
          }).toList();

          final published = filtered.where((q) => !q.isDraft).toList();
          final drafts = filtered.where((q) => q.isDraft).toList();

          return Column(
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search your quizzes...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    isDense: true,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildQuizList(context, filtered, 'No quizzes found'),
                    _buildQuizList(context, published, 'No published quizzes yet'),
                    _buildQuizList(context, drafts, 'No drafts found'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/quiz/new'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Quiz'),
      ),
    );
  }

  Widget _buildQuizList(
    BuildContext context,
    List<Quiz> quizzes,
    String emptyMessage,
  ) {
    final theme = Theme.of(context);

    if (quizzes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.quiz_outlined,
                size: 64,
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create custom multiple-choice quizzes for your upcoming game contests.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => context.push('/quiz/new'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create Quiz'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: quizzes.length,
      itemBuilder: (context, idx) {
        final quiz = quizzes[idx];
        return _buildQuizCard(context, quiz);
      },
    );
  }

  Widget _buildQuizCard(BuildContext context, Quiz quiz) {
    final theme = Theme.of(context);
    final themeColor = Color(quiz.themeColor);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/quiz/edit/${quiz.id}'),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Theme color accent strip
              Container(
                width: 8,
                color: themeColor,
              ),

              // Main Card content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Chip & More Menu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: quiz.isDraft
                                  ? Colors.amber.shade100
                                  : AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              quiz.isDraft ? 'DRAFT' : 'READY TO PLAY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: quiz.isDraft
                                    ? Colors.amber.shade900
                                    : AppColors.accent,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 20),
                            onSelected: (val) {
                              if (val == 'edit') {
                                context.push('/quiz/edit/${quiz.id}');
                              } else if (val == 'duplicate') {
                                _duplicateQuiz(quiz);
                              } else if (val == 'delete') {
                                _confirmDelete(quiz);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 18),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'duplicate',
                                child: Row(
                                  children: [
                                    Icon(Icons.copy_outlined, size: 18),
                                    SizedBox(width: 8),
                                    Text('Duplicate'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline,
                                        size: 18, color: AppColors.gameRed),
                                    SizedBox(width: 8),
                                    Text('Delete',
                                        style: TextStyle(color: AppColors.gameRed)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Title
                      Text(
                        quiz.title.isEmpty ? '(Untitled Quiz)' : quiz.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      if (quiz.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          quiz.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Stat Badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildStatBadge(
                            Icons.format_list_numbered,
                            '${quiz.questionsCount} Questions',
                            theme,
                          ),
                          _buildStatBadge(
                            Icons.timer_outlined,
                            '~${quiz.totalTimeSeconds}s',
                            theme,
                          ),
                          _buildStatBadge(
                            Icons.star_outline,
                            '${quiz.totalPoints} pts',
                            theme,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String text, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
