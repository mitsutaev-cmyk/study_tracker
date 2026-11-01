import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/motivation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/motivation_provider.dart';
import '../../services/api_client.dart';
import '../../utils/profile_options.dart';
import '../../widgets/change_password_dialog.dart';
import '../../widgets/common.dart';

class ProfileScreen extends StatefulWidget {
  final bool embedded;

  const ProfileScreen({super.key, this.embedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();

  String _avatar = '🎓';
  String _accentColor = '#4F46E5';
  String _themeMode = 'system';
  double _dailyGoal = 60;

  bool _dirty = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fillFromUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MotivationProvider>().load();
      _fillFromUser();
    });
  }

  void _fillFromUser() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    _nameController.text = user.name;
    _bioController.text = user.bio;
    _avatar = user.avatar;
    _accentColor = user.accentColor;
    _themeMode = user.themeMode;
    _dailyGoal = user.dailyGoalMinutes.toDouble();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || _saving) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await context.read<AuthProvider>().updateProfile(
            name: _nameController.text,
            bio: _bioController.text,
            avatar: _avatar,
            dailyGoalMinutes: _dailyGoal.round(),
            accentColor: _accentColor,
            themeMode: _themeMode,
          );
      if (!mounted) return;
      setState(() => _dirty = false);
      context.read<MotivationProvider>().load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль сохранён')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => const ChangePasswordDialog(),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пароль изменён')),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Данные на сервере сохранятся.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final motivation = context.watch<MotivationProvider>();
    final theme = Theme.of(context);

    final content = RefreshIndicator(
      onRefresh: motivation.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 8, 16, widget.embedded ? 96 : 24),
        children: [
          Card(
            margin: EdgeInsets.zero,
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      _avatar,
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          auth.user?.email ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _MiniChip(
                              icon: Icons.military_tech,
                              label: 'Ур. ${motivation.data.level} · '
                                  '${motivation.data.levelTitle}',
                            ),
                            _MiniChip(
                              icon: Icons.local_fire_department,
                              label: 'Серия ${motivation.data.streak} дн.',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Профиль',
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Имя',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Введите имя'
                            : null,
                    onChanged: (_) => _markDirty(),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _bioController,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'О себе',
                      hintText: 'Например: готовлюсь к сессии, учу английский',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.info_outline),
                    ),
                    onChanged: (_) => _markDirty(),
                  ),
                  const SizedBox(height: 4),
                  Text('Аватар', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final emoji in avatarOptions)
                        _SelectableEmoji(
                          emoji: emoji,
                          selected: _avatar == emoji,
                          onTap: () {
                            setState(() => _avatar = emoji);
                            _markDirty();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text('Цель дня', style: theme.textTheme.labelLarge),
                      const Spacer(),
                      Text(
                        '${_dailyGoal.round()} мин',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Slider(
                    value: _dailyGoal,
                    min: 15,
                    max: 240,
                    divisions: 15,
                    label: '${_dailyGoal.round()} мин',
                    onChanged: (value) {
                      setState(() => _dailyGoal = value);
                      _markDirty();
                    },
                  ),
                  const SizedBox(height: 8),
                  Text('Акцентный цвет', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final color in accentColorOptions)
                        GestureDetector(
                          onTap: () {
                            setState(() => _accentColor = color);
                            _markDirty();
                          },
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: seedColorFromHex(color),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _accentColor == color
                                    ? theme.colorScheme.onSurface
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: _accentColor == color
                                ? const Icon(
                                    Icons.check,
                                    size: 18,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Тема', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in themeModeOptions)
                        ChoiceChip(
                          avatar: Icon(option.$3, size: 18),
                          label: Text(option.$2),
                          selected: _themeMode == option.$1,
                          onSelected: (_) {
                            setState(() => _themeMode = option.$1);
                            _markDirty();
                          },
                        ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    InlineError(message: _error!),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving || !_dirty ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _saving
                            ? 'Сохраняем...'
                            : _dirty
                                ? 'Сохранить изменения'
                                : 'Всё сохранено',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Мотивация',
            trailing: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/motivation'),
              child: const Text('Все достижения'),
            ),
            child: motivation.loading && motivation.data.achievements.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _MotivationSummary(data: motivation.data),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Аккаунт',
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.password),
                  title: const Text('Сменить пароль'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _changePassword,
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.logout,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    'Выйти',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) return content;

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: content,
    );
  }
}

class _MotivationSummary extends StatelessWidget {
  final Motivation data;

  const _MotivationSummary({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlocked = data.achievements.where((a) => a.unlocked).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Уровень ${data.level}',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: data.levelProgress,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${data.levelSeconds ~/ 60} / '
                    '${data.levelStepSeconds ~/ 60} мин до следующего уровня',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Column(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: Colors.orange.shade700,
                  size: 28,
                ),
                Text(
                  '${data.streak}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text('дней', style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Открыто ${unlocked.length} из ${data.achievements.length} достижений',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        if (unlocked.isEmpty)
          Text(
            'Первое достижение — за одно завершённое занятие.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final achievement in unlocked.take(6))
                Chip(
                  avatar: const Icon(Icons.emoji_events, size: 16),
                  label: Text(achievement.title),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.onPrimaryContainer.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onPrimaryContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: scheme.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

class _SelectableEmoji extends StatelessWidget {
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableEmoji({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}
