const express = require('express');
const { body, param } = require('express-validator');
const { authenticateToken } = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const pool = require('../config/db');

const router = express.Router();

router.use(authenticateToken);

// Get all subjects for user (with total studied time)
router.get('/', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT s.id, s.name, s.color, s.created_at,
             COALESCE(SUM(ss.duration), 0)::int AS total_seconds
      FROM subjects s
      LEFT JOIN study_sessions ss ON ss.subject_id = s.id AND ss.end_time IS NOT NULL
      WHERE s.user_id = $1
      GROUP BY s.id
      ORDER BY s.created_at DESC
    `, [req.userId]);
    res.json({ subjects: result.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch subjects' });
  }
});

// Create subject
router.post('/',
  body('name').trim().notEmpty().withMessage('Введите название предмета').isLength({ max: 255 }),
  body('color').optional().matches(/^#[0-9A-Fa-f]{6}$/).withMessage('Цвет должен быть в формате #RRGGBB'),
  validate,
  async (req, res) => {
    try {
      const { name, color } = req.body;
      const result = await pool.query(
        'INSERT INTO subjects (user_id, name, color) VALUES ($1, $2, $3) RETURNING id, name, color, created_at',
        [req.userId, name, color || '#2196F3']
      );
      res.status(201).json({ subject: { ...result.rows[0], total_seconds: 0 } });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Failed to create subject' });
    }
  }
);

// Delete subject
router.delete('/:id',
  param('id').isInt({ min: 1 }).withMessage('Некорректный id').toInt(),
  validate,
  async (req, res) => {
    try {
      const result = await pool.query(
        'DELETE FROM subjects WHERE id = $1 AND user_id = $2',
        [req.params.id, req.userId]
      );
      if (result.rowCount === 0) return res.status(404).json({ error: 'Subject not found' });
      res.json({ message: 'Subject deleted' });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Failed to delete subject' });
    }
  }
);

module.exports = router;