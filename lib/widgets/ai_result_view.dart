import 'package:flutter/material.dart';

import 'common.dart';

/// Renders the JSON returned by the AI endpoints as readable cards.
class AiResultView extends StatelessWidget {
  final Map<String, dynamic> data;
  final int depth;

  const AiResultView({super.key, required this.data, this.depth = 0});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Text(
        'Пустой ответ',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in data.entries)
          Padding(
            padding: EdgeInsets.only(bottom: depth == 0 ? 12 : 6),
            child: _entry(context, entry.key, entry.value),
          ),
      ],
    );
  }

  Widget _entry(BuildContext context, String key, dynamic value) {
    final label = _label(key);
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      return SectionCard(
        title: label,
        padding: EdgeInsets.all(depth == 0 ? 16 : 12),
        child: AiResultView(data: map, depth: depth + 1),
      );
    }
    if (value is List) {
      return _listSection(context, label, value);
    }
    return _scalarRow(context, label, value);
  }

  Widget _listSection(BuildContext context, String label, List<dynamic> items) {
    if (items.isEmpty) {
      return _scalarRow(context, label, '—');
    }

    final mapItems =
        items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final isMapList = mapItems.length == items.length;

    return SectionCard(
      title: label,
      padding: EdgeInsets.all(depth == 0 ? 16 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isMapList)
            for (var i = 0; i < mapItems.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _mapItem(context, label, i, mapItems[i]),
              )
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6, right: 8),
                      child: Icon(Icons.circle, size: 6),
                    ),
                    Expanded(child: Text(_scalar(item))),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _mapItem(
    BuildContext context,
    String label,
    int index,
    Map<String, dynamic> map,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        title: Text(
          _itemTitle(map, label, index),
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        children: [
          AiResultView(data: map, depth: depth + 1),
        ],
      ),
    );
  }

  Widget _scalarRow(BuildContext context, String label, dynamic value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(_scalar(value))),
      ],
    );
  }

  String _itemTitle(Map<String, dynamic> map, String label, int index) {
    final week = map['week'];
    if (week != null) return 'Неделя $week';

    for (final key in ['name', 'title', 'topic']) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '$label ${index + 1}';
  }

  String _scalar(dynamic value) {
    if (value == null) return '—';
    if (value is bool) return value ? 'Да' : 'Нет';
    if (value is num) {
      return value % 1 == 0 ? value.toInt().toString() : value.toString();
    }
    final text = value.toString().trim();
    return text.isEmpty ? '—' : text;
  }

  String _label(String key) => _labels[key] ?? key.replaceAll('_', ' ');
}

const _labels = <String, String>{
  'title': 'Название',
  'duration_days': 'Длительность (дней)',
  'weeks': 'Недели',
  'week': 'Неделя',
  'topics': 'Темы',
  'daily_hours': 'Часов в день',
  'resources': 'Ресурсы',
  'milestones': 'Контрольные точки',
  'tips': 'Советы',
  'summary': 'Кратко',
  'strengths': 'Сильные стороны',
  'weaknesses': 'Слабые стороны',
  'recommendations': 'Рекомендации',
  'motivation_tips': 'Мотивация',
  'predicted_progress': 'Прогноз прогресса',
  'overall_score': 'Оценка',
  'areas_for_improvement': 'Что улучшить',
  'detailed_feedback': 'Подробный отзыв',
  'suggested_resources': 'Полезные ресурсы',
  'next_steps': 'Следующие шаги',
  'quote': 'Цитата',
  'author': 'Автор',
  'context': 'Контекст',
  'action_point': 'Действие',
  'immediate_actions': 'Сделать сразу',
  'weekly_focus': 'Фокус недели',
  'habit_changes': 'Новые привычки',
  'time_optimization': 'Оптимизация времени',
  'motivation_strategy': 'Стратегия мотивации',
  'books': 'Книги',
  'online_courses': 'Онлайн-курсы',
  'youtube_channels': 'YouTube-каналы',
  'websites': 'Сайты',
  'tools': 'Инструменты',
  'name': 'Название',
  'platform': 'Платформа',
  'duration': 'Длительность',
  'why': 'Почему полезно',
  'description': 'Описание',
  'purpose': 'Назначение',
  'url_format': 'Ссылка',
  'author_name': 'Автор',
  'score': 'Оценка',
};
