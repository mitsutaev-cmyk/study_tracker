const express = require('express');
const { authenticateToken } = require('../middleware/auth');
const aiService = require('../services/aiService');
const pool = require('../config/db');

const router = express.Router();

// Генерировать учебный план
router.post('/study-plan', authenticateToken, async (req, res) => {
  try {
    const { goal, subject, currentLevel, deadline } = req.body;

    if (!goal || !subject) {
      return res.status(400).json({ error: 'Goal and subject are required' });
    }

    const studyPlan = await aiService.generateStudyPlan(
      goal,
      subject,
      currentLevel || 'Beginner',
      deadline || 30
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
    console.error(err);
    res.status(500).json({ error: 'Failed to generate study plan' });
  }
});

// Анализ статистики и рекомендации
router.get('/analyze-stats', authenticateToken, async (req, res) => {
  try {
    // Получаем статистику пользователя
    const statsResult = await pool.query(`
      SELECT 
        s.name as subject,
        COUNT(ss.id) as sessions,
        COALESCE(SUM(ss.duration), 0) as total_seconds,
        AVG(ss.duration) as avg_session
      FROM subjects s
      LEFT JOIN study_sessions ss ON s.id = ss.subject_id
      WHERE s.user_id = $1
      GROUP BY s.id, s.name
    `, [req.userId]);

    const analysis = await aiService.analyzeStudyStats(statsResult.rows);

    res.json(analysis);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to analyze stats' });
  }
});

// Проверка работы студента
router.post('/review-work', authenticateToken, async (req, res) => {
  try {
    const { workType, workContent, subject, level } = req.body;

    if (!workContent || !subject) {
      return res.status(400).json({ error: 'Work content and subject are required' });
    }

    const review = await aiService.reviewStudentWork(
      workType || 'essay',
      workContent,
      subject,
      level || 'intermediate'
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
    console.error(err);
    res.status(500).json({ error: 'Failed to review work' });