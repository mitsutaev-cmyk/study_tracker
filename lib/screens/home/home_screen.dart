import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/motivation_provider.dart';
import '../../providers/study_provider.dart';
import '../../widgets/change_password_dialog.dart';
import '../calendar/calendar_screen.dart';
import '../profile/profile_screen.dart';
import '../stats/statistics_screen.dart';
import '../study/subject_list_screen.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _titles = [
    'Главная',
    'Предметы',
    'Календарь',
    'Статистика',
    'Профиль',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StudyProvider>().refreshAll();
      context.read<AuthProvider>().refreshUser();
      context.read<MotivationProvider>().load();
      context.read<CalendarProvider>().load();
    });
  }

  Future<void> _refresh() async {
    await context.read<StudyProvider>().refreshAll();
    if (!mounted) return;
    await context.read<MotivationProvider>().load();
    if (!mounted) return;
    await context.read<CalendarProvider>().load();
    if (!mounted) return;
    await context.read<AuthProvider>().refreshUser();
  }

  void _selectTab(int index) {
    Navigator.of(context).pop();
    setState(() => _index = index);
  }

  void _open(String route) {
    Navigator.of(context).pop();
    Navigator.pushNamed(context, route);
  }

  Future<void> _openChangePassword() async {
    Navigator.of(context).pop();
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
    Navigator.of(context).pop();
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

    context.read<StudyProvider>().reset();
    context.read<CalendarProvider>().reset();
    context.read<MotivationProvider>().reset();
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Chip(
              avatar: Icon(
                Icons.monetization_on_outlined,
                size: 18,
                color: Colors.amber.shade800,
              ),
              label: Text('${auth.coins}'),
              visualDensity: VisualDensity.compact,
            ),
          ),
          IconButton(
            tooltip: 'Обновить',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: scheme.primaryContainer),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: scheme.primary,
                    child: Text(
                      auth.user?.avatar ?? '🎓',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    auth.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    auth.user?.email ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.monetization_on,
                        size: 16,
                        color: Colors.amber.shade800,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${auth.coins} монет',
                        style: TextStyle(color: scheme.onPrimaryContainer),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _DrawerItem(
              icon: Icons.dashboard_outlined,
              title: 'Главная',
              selected: _index == 0,
              onTap: () => _selectTab(0),
            ),
            _DrawerItem(
              icon: Icons.menu_book_outlined,
              title: 'Предметы',
              selected: _index == 1,
              onTap: () => _selectTab(1),
            ),
            _DrawerItem(
              icon: Icons.calendar_month_outlined,
              title: 'Календарь',
              selected: _index == 2,
              onTap: () => _selectTab(2),
            ),
            _DrawerItem(
              icon: Icons.bar_chart_rounded,
              title: 'Статистика',
              selected: _index == 3,
              onTap: () => _selectTab(3),
            ),
            _DrawerItem(
              icon: Icons.person_outline,
              title: 'Профиль',
              selected: _index == 4,
              onTap: () => _selectTab(4),
            ),
            const Divider(),
            _DrawerItem(
              icon: Icons.local_fire_department_outlined,
              title: 'Мотивация и достижения',
              onTap: () => _open('/motivation'),
            ),
            _DrawerItem(
              icon: Icons.auto_awesome,
              title: 'Учебный план',
              onTap: () => _open('/study-plans'),
            ),
            _DrawerItem(
              icon: Icons.insights,
              title: 'AI-рекомендации',
              onTap: () => _open('/ai-recommendations'),
            ),
            _DrawerItem(
              icon: Icons.rate_review_outlined,
              title: 'Проверка работы',
              onTap: () => _open('/work-review'),
            ),
            _DrawerItem(
              icon: Icons.format_quote,
              title: 'Мотивационная цитата',
              onTap: () => _open('/motivational-quote'),
            ),
            const Divider(),
            _DrawerItem(
              icon: Icons.password,
              title: 'Сменить пароль',
              onTap: _openChangePassword,
            ),
            _DrawerItem(
              icon: Icons.logout,
              title: 'Выйти',
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardScreen(embedded: true),
          SubjectListScreen(embedded: true),
          CalendarScreen(embedded: true),
          StatisticsScreen(embedded: true),
          ProfileScreen(embedded: true),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Предметы',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Календарь',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Статистика',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: selected,
      onTap: onTap,
    );
  }
}
