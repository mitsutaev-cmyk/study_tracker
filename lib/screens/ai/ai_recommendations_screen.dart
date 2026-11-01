import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/ai_service.dart';
import '../../services/api_client.dart';
import '../../widgets/ai_result_view.dart';
import '../../widgets/common.dart';

class AIRecommendationsScreen extends StatefulWidget {
  const AIRecommendationsScreen({super.key});

  @override
  State<AIRecommendationsScreen> createState() =>
      _AIRecommendationsScreenState();
}

class _AIRecommendationsScreenState extends State<AIRecommendationsScreen> {
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _analysis;
  Map<String, dynamic>? _recommendations;

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ai = context.read<AIService>();
      final results = await Future.wait([
        ai.analyzeStats(),
        ai.getRecommendations(),
      ]);
      if (!mounted) return;
      setState(() {
        _analysis = results[0];
        _recommendations = results[1];
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasResults = _analysis != null || _recommendations != null;

    return Scaffold(
      appBar: AppBar(title: const Text('AI-рекомендации')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.insights, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Анализ вашей учёбы',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'AI посмотрит на статистику по предметам и подскажет, '
                  'что улучшить, на чём сосредоточиться и как не потерять мотивацию.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _load,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(
                      _loading
                          ? 'AI анализирует...'
                          : hasResults
                              ? 'Обновить рекомендации'
                              : 'Получить рекомендации',
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            InlineError(message: _error!),
          ],
          if (_loading && !hasResults) ...[
            const SizedBox(height: 24),
            const SizedBox(height: 220, child: LoadingView()),
          ] else if (!hasResults && _error == null) ...[
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: EmptyView(
                icon: Icons.auto_awesome,
                title: 'Здесь появятся рекомендации',
                message:
                    'Чем больше занятий вы завершите, тем точнее будет анализ.',
              ),
            ),
          ],
          if (_analysis != null) ...[
            const SizedBox(height: 16),
            SectionCard(
              title: 'Разбор статистики',
              child: AiResultView(data: _analysis!),
            ),
          ],
          if (_recommendations != null) ...[
            const SizedBox(height: 16),
            SectionCard(
              title: 'Персональные советы',
              child: AiResultView(data: _recommendations!),
            ),
          ],
        ],
      ),
    );
  }
}
