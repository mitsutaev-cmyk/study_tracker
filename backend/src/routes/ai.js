const express = require('express');
const { authenticateToken } = require('../middleware/auth');
const aiService = require('../services/aiService');
const pool = require('../config/db');

const router = express.Router();

router.use(authenticateToken);

// Единая обработка ошибок AI-эндпоинтов
const handleError = (res, err, message) => {
  console.error(err);
  if (err.code === 'AI_NOT_CONFIGURED') {
    return res.status(503).json({ error: 'AI не настроен: задайте OPENAI_API_KEY в .env' });
  }
  if (err.code === 'AI_TIMEOUT') {
    return res.status(504).json({ error: 'AI не успел ответить. Попробуйте ещё раз.' });
  }
  res.status(500).json({ error: message });
};

// Trims strings and limits their length so a huge prompt can't be sent to the model.
const text = (value, maxLength) =>
  typeof value === 'string' ? value.trim().slice(0, maxLength) : '';

// Генерировать учебный план
router.post('/study-plan', async (req, res) => {
  try {
    const goal = text(req.body.goal, 500);
    const subject = text(req.body.subject, 255);
    const currentLevel = text(req.body.currentLevel, 100) || 'Beginner';
    const deadline = Math.min(Math.max(Number(req.body.deadline) || 30, 1), 365);

    if (!goal || !subject) {
      return res.status(400).json({ error: 'Укажите цель и предмет' });
    }

    const studyPlan = await aiService.generateStudyPlan(
      goal,
      subject,
      currentLevel,
      deadline
    );

    // Сохраняем план в БД
    const result = await pool.query(
      'INSERT INTO study_plans (user_id, subject, goal, plan_data) VALUES ($1, $2, $3, $4) RETURNING *',
      [req.userId, subject, goal, JSON.stringify(studyPlan)]
    );

    res.json({
      id: result.rows[0].id,
      plan: studyPlan,
    });
  } catch (err) {
    handleError(res, err, 'Failed to generate study plan');
  }
});

// Анализ статистики и рекомендации
router.get('/analyze-stats', async (req, res) => {
  try {
    // Получаем статистику пользователя
    const statsResult = await pool.query(`
      SELECT
        s.name AS subject,
        COUNT(ss.id)::int AS sessions,
        COALESCE(SUM(ss.duration), 0)::int AS total_seconds,
        COALESCE(ROUND(AVG(ss.duration)), 0)::int AS avg_session
      FROM subjects s
      LEFT JOIN study_sessions ss ON s.id = ss.subject_id AND ss.end_time IS NOT NULL
      WHERE s.user_id = $1
      GROUP BY s.id, s.name
    `, [req.userId]);

    const analysis = await aiService.analyzeStudyStats(statsResult.rows);

    res.json(analysis);
  } catch (err) {
    handleError(res, err, 'Failed to analyze stats');
  }
});

// Проверка работы студента
router.post('/review-work', async (req, res) => {
  try {
    const workType = text(req.body.workType, 64) || 'essay';
    const workContent = text(req.body.workContent, 20000);
    const subject = text(req.body.subject, 255);
    const level = text(req.body.level, 100) || 'intermediate';

    if (!workContent || !subject) {
      return res.status(400).json({ error: 'Укажите предмет и текст работы' });
    }

    const review = await aiService.reviewStudentWork(
      workType,
      workContent,
      subject,
      level
    );

    // Сохраняем отзыв
    const result = await pool.query(
      'INSERT INTO work_reviews (user_id, subject, work_type, review_data) VALUES ($1, $2, $3, $4) RETURNING *',
      [req.userId, subject, workType, JSON.stringify(review)]
    );

    res.json({
      id: result.rows[0].id,
      review,
    });
  } catch (err) {
    handleError(res, err, 'Failed to review work');
  }
});

// Мотивационная цитата
router.post('/motivational-quote', async (req, res) => {
  try {
    const goal = text(req.body.goal, 500) || 'учиться регулярно';
    const subject = text(req.body.subject, 255) || 'любой предмет';
    const quote = await aiService.generateMotivationalQuote(goal, subject);
    res.json(quote);
  } catch (err) {
    handleError(res, err, 'Failed to generate quote');
  }
});

// Рекомендации ресурсов
router.post('/resources', async (req, res) => {
  try {
    const goal = text(req.body.goal, 500);
    const subject = text(req.body.subject, 255);
    const level = text(req.body.level, 100) || 'intermediate';
    const interests = text(req.body.interests, 500) || 'не указаны';
    if (!goal || !subject) {
      return res.status(400).json({ error: 'Укажите цель и предмет' });
    }
    const resources = await aiService.recommendResources(
      goal,
      subject,
      level,
      interests
    );
    res.json(resources);
  } catch (err) {
    handleError(res, err, 'Failed to recommend resources');
  }
});

// Персональные рекомендации на основе прогресса
router.get('/recommendations', async (req, res) => {
  try {
    const statsResult = await pool.query(`
      SELECT
        s.name AS subject,
        COUNT(ss.id)::int AS sessions,
        COALESCE(SUM(ss.duration), 0)::int AS total_seconds,
        MAX(ss.start_time) AS last_session
      FROM subjects s
      LEFT JOIN study_sessions ss ON s.id = ss.subject_id AND ss.end_time IS NOT NULL
      WHERE s.user_id = $1
      GROUP BY s.id, s.name
    `, [req.userId]);

    const recommendations = await aiService.getPersonalizedRecommendations({
      subjects: statsResult.rows,
    });
    res.json(recommendations);
  } catch (err) {
    handleError(res, err, 'Failed to get recommendations');
  }
});

// Сохранённые учебные планы
router.get('/study-plans', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, subject, goal, plan_data, created_at FROM study_plans WHERE user_id = $1 ORDER BY created_at DESC',
      [req.userId]
    );
    res.json({ plans: result.rows });
  } catch (err) {
    handleError(res, err, 'Failed to fetch study plans');
  }
});

module.exports = router;