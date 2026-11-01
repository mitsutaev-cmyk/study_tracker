const express = require('express');
const { authenticateToken } = require('../middleware/auth');
const pool = require('../config/db');

const router = express.Router();

router.use(authenticateToken);

const HOUR = 3600;
const LEVEL_STEP_SECONDS = 5 * HOUR;

const LEVEL_TITLES = [
  'Новичок',
  'Ученик',
  'Практик',
  'Знаток',
  'Эксперт',
  'Мастер',
  'Гуру',
  'Легенда',
];

// Longest run of consecutive days inside a sorted (descending) list of dates.
function longestStreak(days) {
  if (days.length === 0) return 0;

  const sorted = [...days].sort();
  let best = 1;
  let current = 1;

  for (let i = 1; i < sorted.length; i += 1) {
    const prev = new Date(`${sorted[i - 1]}T00:00:00Z`);
    const next = new Date(`${sorted[i]}T00:00:00Z`);
    const diff = Math.round((next - prev) / 86400000);
    if (diff === 1) {
      current += 1;
      best = Math.max(best, current);
    } else if (diff > 1) {
      current = 1;
    }
  }
  return best;
}

// Streak that is still alive: counts back from today (or yesterday, so the
// streak does not break before the user has had a chance to study today).
function currentStreak(daySet, todayKey) {
  const cursor = new Date(`${todayKey}T00:00:00Z`);
  const key = (date) => date.toISOString().slice(0, 10);

  if (!daySet.has(key(cursor))) {
    cursor.setUTCDate(cursor.getUTCDate() - 1);
    if (!daySet.has(key(cursor))) return 0;
  }

  let streak = 0;
  while (daySet.has(key(cursor))) {
    streak += 1;
    cursor.setUTCDate(cursor.getUTCDate() - 1);
  }
  return streak;
}

function buildAchievements({
  totalSeconds,
  sessionCount,
  streak,
  completedTasks,
  todaySeconds,
  dailyGoalSeconds,
}) {
  const goalsReached = dailyGoalSeconds > 0 && todaySeconds >= dailyGoalSeconds;

  return [
    {
      id: 'first_session',
      title: 'Первый шаг',
      description: 'Завершите первое занятие',
      icon: 'play',
      progress: Math.min(sessionCount, 1),
      target: 1,
      unlocked: sessionCount >= 1,
    },
    {
      id: 'hour_1',
      title: 'Час за книгой',
      description: 'Позанимайтесь 1 час',
      icon: 'hourglass',
      progress: Math.min(totalSeconds, HOUR),
      target: HOUR,
      unlocked: totalSeconds >= HOUR,
    },
    {
      id: 'hours_10',
      title: 'Десять часов',
      description: 'Накопите 10 часов учёбы',
      icon: 'auto_stories',
      progress: Math.min(totalSeconds, 10 * HOUR),
      target: 10 * HOUR,
      unlocked: totalSeconds >= 10 * HOUR,
    },
    {
      id: 'hours_50',
      title: 'Полсотни часов',
      description: 'Накопите 50 часов учёбы',
      icon: 'workspace_premium',
      progress: Math.min(totalSeconds, 50 * HOUR),
      target: 50 * HOUR,
      unlocked: totalSeconds >= 50 * HOUR,
    },
    {
      id: 'streak_3',
      title: 'Три дня подряд',
      description: 'Занимайтесь 3 дня без пропусков',
      icon: 'local_fire_department',
      progress: Math.min(streak, 3),
      target: 3,
      unlocked: streak >= 3,
    },
    {
      id: 'streak_7',
      title: 'Неделя силы',
      description: 'Занимайтесь 7 дней без пропусков',
      icon: 'whatshot',
      progress: Math.min(streak, 7),
      target: 7,
      unlocked: streak >= 7,
    },
    {
      id: 'streak_30',
      title: 'Месяц дисциплины',
      description: 'Занимайтесь 30 дней без пропусков',
      icon: 'military_tech',
      progress: Math.min(streak, 30),
      target: 30,
      unlocked: streak >= 30,
    },
    {
      id: 'sessions_10',
      title: 'Десять занятий',
      description: 'Завершите 10 занятий',
      icon: 'checklist',
      progress: Math.min(sessionCount, 10),
      target: 10,
      unlocked: sessionCount >= 10,
    },
    {
      id: 'sessions_50',
      title: 'Пятьдесят занятий',
      description: 'Завершите 50 занятий',
      icon: 'emoji_events',
      progress: Math.min(sessionCount, 50),
      target: 50,
      unlocked: sessionCount >= 50,
    },
    {
      id: 'tasks_5',
      title: 'Планировщик',
      description: 'Выполните 5 задач из календаря',
      icon: 'task_alt',
      progress: Math.min(completedTasks, 5),
      target: 5,
      unlocked: completedTasks >= 5,
    },
    {
      id: 'tasks_20',
      title: 'Хозяин своего времени',
      description: 'Выполните 20 задач из календаря',
      icon: 'event_available',
      progress: Math.min(completedTasks, 20),
      target: 20,
      unlocked: completedTasks >= 20,
    },
    {
      id: 'daily_goal',
      title: 'Цель дня',
      description: 'Выполните дневную цель учёбы',
      icon: 'flag',
      progress: goalsReached ? 1 : 0,
      target: 1,
      unlocked: goalsReached,
    },
  ];
}

function buildMessage({ todaySeconds, dailyGoalSeconds, streak, completedToday }) {
  if (dailyGoalSeconds > 0 && todaySeconds >= dailyGoalSeconds) {
    return 'Цель дня выполнена. Отличная работа!';
  }
  if (todaySeconds > 0) {
    const left = Math.max(dailyGoalSeconds - todaySeconds, 0);
    return `Осталось ${Math.ceil(left / 60)} мин до цели дня. Продолжайте!`;
  }
  if (streak > 0) {
    return `Серия ${streak} дн. Не разрывайте её — начните занятие сегодня.`;
  }
  if (completedToday > 0) {
    return 'Задачи на сегодня выполнены. Можно и позаниматься!';
  }
  return 'Начните занятие или отметьте задачу в календаре — с чего-нибудь одного.';
}

router.get('/', async (req, res) => {
  try {
    const [totals, days, tasks, user, today] = await Promise.all([
      pool.query(`
        SELECT
          COALESCE(SUM(duration), 0)::int AS total_seconds,
          COALESCE(SUM(duration) FILTER (WHERE start_time >= date_trunc('day', NOW())), 0)::int AS today_seconds,
          COUNT(*)::int AS session_count
        FROM study_sessions
        WHERE user_id = $1 AND end_time IS NOT NULL
      `, [req.userId]),
      pool.query(`
        SELECT DISTINCT to_char(start_time, 'YYYY-MM-DD') AS day
        FROM study_sessions
        WHERE user_id = $1 AND end_time IS NOT NULL
        ORDER BY day
      `, [req.userId]),
      pool.query(`
        SELECT
          COUNT(*)::int AS total_tasks,
          COUNT(*) FILTER (WHERE completed)::int AS completed_tasks,
          COUNT(*) FILTER (WHERE completed AND completed_at::date = CURRENT_DATE)::int AS completed_today
        FROM tasks
        WHERE user_id = $1
      `, [req.userId]),
      pool.query(
        'SELECT daily_goal_minutes FROM users WHERE id = $1',
        [req.userId]
      ),
      pool.query("SELECT to_char(NOW(), 'YYYY-MM-DD') AS today"),
    ]);

    const totalSeconds = totals.rows[0].total_seconds;
    const todaySeconds = totals.rows[0].today_seconds;
    const sessionCount = totals.rows[0].session_count;
    const dailyGoalMinutes = user.rows[0]?.daily_goal_minutes ?? 60;
    const dailyGoalSeconds = dailyGoalMinutes * 60;

    const dayList = days.rows.map((row) => row.day);
    const daySet = new Set(dayList);
    const todayKey = today.rows[0].today;
    const streak = currentStreak(daySet, todayKey);
    const bestStreak = longestStreak(dayList);

    const completedTasks = tasks.rows[0].completed_tasks;
    const completedToday = tasks.rows[0].completed_today;
    const totalTasks = tasks.rows[0].total_tasks;

    const levelIndex = Math.floor(totalSeconds / LEVEL_STEP_SECONDS);
    const level = levelIndex + 1;
    const levelSeconds = totalSeconds % LEVEL_STEP_SECONDS;

    res.json({
      total_seconds: totalSeconds,
      today_seconds: todaySeconds,
      session_count: sessionCount,
      daily_goal_minutes: dailyGoalMinutes,
      daily_goal_seconds: dailyGoalSeconds,
      daily_goal_progress: dailyGoalSeconds === 0
        ? 0
        : Math.min(todaySeconds / dailyGoalSeconds, 1),
      streak,
      best_streak: bestStreak,
      level,
      level_title: LEVEL_TITLES[Math.min(levelIndex, LEVEL_TITLES.length - 1)],
      level_seconds: levelSeconds,
      level_step_seconds: LEVEL_STEP_SECONDS,
      level_progress: levelSeconds / LEVEL_STEP_SECONDS,
      total_tasks: totalTasks,
      completed_tasks: completedTasks,
      completed_today: completedToday,
      message: buildMessage({
        todaySeconds,
        dailyGoalSeconds,
        streak,
        completedToday,
      }),
      achievements: buildAchievements({
        totalSeconds,
        sessionCount,
        streak,
        completedTasks,
        todaySeconds,
        dailyGoalSeconds,
      }),
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch motivation' });
  }
});

module.exports = router;
