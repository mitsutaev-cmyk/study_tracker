import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/ai_service.dart';
import '../../services/api_client.dart';
import '../../widgets/ai_result_view.dart';
import '../../widgets/common.dart';

class MotivationalQuoteScreen extends StatefulWidget {
  const MotivationalQuoteScreen({super.key});

  @override
  State<MotivationalQuoteScreen> createState() =>
      _MotivationalQuoteScreenState();
}

class _MotivationalQuoteScreenState extends State<MotivationalQuoteScreen> {
  final _goalController = TextEditingController();
  final _subjectController = TextEditingController();

  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _quote;

  @override
  void dispose() {
    _goalController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    FocusScope.of(context).unfocus();
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final quote = await context.read<AIService>().generateMotivationalQuote(
            goal: _goalController.text.trim(),
            subject: _subjectController.text.trim(),
          );
      if (!mounted) return;
      setState(() => _quote = quote);
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
    final quote = _quote;
    Map<String, dynamic>? extras;
    if (quote != null) {
      extras = Map<String, dynamic>.from(quote)
        ..remove('quote')
        ..remove('author');
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Мотивация')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SectionCard(
            child: Column(
              children: [
                TextField(
                  controller: _goalController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Ваша цель (необязательно)',
                    hintText: 'Например: сдать сессию без долгов',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _subjectController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Предмет (необязательно)',
                    hintText: 'Например: физика',
                    prefixIcon: Icon(Icons.menu_book_outlined),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _generate,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.format_quote),
                    label: Text(
                      _loading ? 'Придумываем...' : 'Получить цитату',
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
          if (quote != null) ...[
            const SizedBox(height: 20),
            Card(
              margin: EdgeInsets.zero,
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote_rounded,
                      size: 40,
                      color: theme.colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      quote['quote']?.toString() ?? '',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '— ${quote['author']?.toString() ?? 'AI'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (extras != null && extras.isNotEmpty) ...[
              const SizedBox(height: 16),
              SectionCard(
                title: 'Как применить',
                child: AiResultView(data: extras),
              ),
            ],
          ] else if (!_loading) ...[
            const SizedBox(height: 24),
            SizedBox(
              height: 260,
              child: EmptyView(
                icon: Icons.emoji_objects_outlined,
                title: 'Нужна порция мотивации?',
                message: 'Нажмите кнопку — AI придумает цитату под вашу цель.',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
