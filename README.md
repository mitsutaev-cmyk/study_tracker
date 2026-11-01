# Study Tracker

Мобильное приложение для учёта времени учёбы: таймер занятий по предметам,
календарь задач, статистика, мотивация с достижениями, настройка профиля и
AI-помощник (учебные планы, разбор статистики, проверка работ, мотивация).

Клиент — Flutter, бэкенд — Node.js + Express + PostgreSQL.

## Возможности

- Регистрация и вход по JWT, смена пароля.
- Предметы с цветовой меткой; время по каждому предмету.
- Таймер занятия с сохранением на сервере: занятие не теряется при перезапуске
  приложения, активное занятие можно завершить или отменить.
- Календарь задач: планирование «что сделать к какому дню», отметка выполнения,
  просроченные задачи, добавление и редактирование.
- Статистика: всего / сегодня / за 7 дней, график по дням, разбивка по предметам
  и AI-разбор статистики прямо на экране.
- Мотивация: серия дней подряд, лучшая серия, дневная цель, уровень и 12
  достижений с прогрессом.
- Кастомизация профиля: имя, био, эмодзи-аватар, дневная цель, акцентный цвет
  и тема (системная / светлая / тёмная).
- Монеты: 1 монета за каждую полную минуту занятия.
- AI-функции: учебный план, анализ статистики, персональные рекомендации,
  проверка работы, мотивационная цитата.

## Структура проекта

```
lib/
  app.dart              MaterialApp, тема, маршруты
  main.dart             точка входа, DI через provider
  config/               адрес API
  models/               User, Subject, StudySession, Task, Statistics, Motivation
  providers/            AuthProvider, StudyProvider, CalendarProvider,
                        MotivationProvider
  services/             ApiClient, AuthService, ApiService, AIService
  screens/              auth, home, study, calendar, stats, ai, motivation, profile
  utils/                форматирование времени, цвета, валидация, опции профиля
  widgets/              общие виджеты, рендер AI-ответов, смена пароля
beckend/                Node.js API
  src/routes/           auth, subjects, sessions, statistics, tasks, motivation, ai
  src/services/         интеграция с OpenAI
  schema.sql            схема БД
test/                   unit- и widget-тесты
```

## Запуск бэкенда

Требования: Node.js 18+, PostgreSQL 14+.

1. Создайте базу данных:

   ```sql
   CREATE DATABASE study_tracker;
   ```

2. Примените схему:

   ```bash
   psql -U postgres -d study_tracker -f beckend/schema.sql
   ```

   Файл идемпотентен: его можно запускать повторно на существующей базе —
   новые таблицы и колонки профиля добавятся без потери данных.

3. Настройте окружение:

   ```bash
   cp beckend/.env.example beckend/.env
   ```

   Заполните `DB_*`, `JWT_SECRET` (длинная случайная строка) и, если нужны
   AI-функции, `OPENAI_API_KEY`.

4. Установите зависимости и запустите сервер:

   ```bash
   cd beckend
   npm install
   npm start
   ```

   Сервер слушает `0.0.0.0:5000`, health-check: `GET /api/health`.

## Запуск приложения

```bash
flutter pub get
flutter run
```

Адрес API выбирается в `lib/config/api_config.dart`:

- Android-эмулятор — `http://10.0.2.2:5000/api`;
- остальные платформы — `http://localhost:5000/api`;
- свой адрес можно передать при запуске:

  ```bash
  flutter run --dart-define=API_URL=http://192.168.1.10:5000/api
  ```

Для реального устройства укажите IP компьютера в локальной сети и убедитесь,
что порт 5000 открыт. HTTP разрешён только для локальной разработки: перед
публикацией переведите бэкенд на HTTPS и уберите `usesCleartextTraffic` из
Android-манифеста.

## AI

Ключ OpenAI хранится только на сервере (`beckend/.env`). Если ключ не задан,
AI-экраны показывают понятное сообщение, остальное приложение работает.
Модель задаётся через `OPENAI_MODEL` (по умолчанию `gpt-4o-mini`), таймаут —
`AI_TIMEOUT_MS`.

## API

| Метод | Путь | Описание |
| --- | --- | --- |
| POST | `/api/auth/register` | Регистрация |
| POST | `/api/auth/login` | Вход |
| GET | `/api/auth/me` | Текущий пользователь |
| POST | `/api/auth/change-password` | Смена пароля |
| PATCH | `/api/auth/profile` | Имя, био, аватар, цель дня, тема, цвет |
| GET/POST | `/api/subjects` | Список / создание предмета |
| DELETE | `/api/subjects/:id` | Удаление предмета |
| GET | `/api/sessions` | История занятий |
| GET | `/api/sessions/active` | Активное занятие |
| POST | `/api/sessions/start` | Начать занятие |
| POST | `/api/sessions/end/:id` | Завершить занятие и начислить монеты |
| DELETE | `/api/sessions/:id` | Отменить активное занятие |
| GET | `/api/statistics` | Сводная статистика и график за 7 дней |
| GET | `/api/tasks?from=&to=` | Задачи за период |
| POST | `/api/tasks` | Создать задачу (`title`, `dueDate`, `notes`) |
| PATCH | `/api/tasks/:id` | Изменить задачу или отметить выполненной |
| DELETE | `/api/tasks/:id` | Удалить задачу |
| GET | `/api/motivation` | Серия, уровень, цель дня, достижения |
| POST | `/api/ai/study-plan` | Учебный план |
| GET | `/api/ai/study-plans` | Сохранённые планы |
| GET | `/api/ai/analyze-stats` | Анализ статистики |
| GET | `/api/ai/recommendations` | Персональные рекомендации |
| POST | `/api/ai/review-work` | Проверка работы |
| POST | `/api/ai/motivational-quote` | Мотивационная цитата |
| POST | `/api/ai/resources` | Подбор ресурсов |

Все эндпоинты, кроме `/api/auth/register`, `/api/auth/login` и `/api/health`,
требуют заголовок `Authorization: Bearer <token>`.

## Проверка

```bash
flutter analyze
flutter test
```

Тесты не обращаются к сети: `SharedPreferences` подменяется mock-значениями,
проверяются экран входа, валидация формы и парсинг моделей.

