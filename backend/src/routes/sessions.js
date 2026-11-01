const express = require('express');
const { body, param, query } = require('express-validator');
const { authenticateToken } = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const pool = require('../config/db');

const router = express.Router();

router.use(authenticateToken);

// 1 coin per full minute of study
const COINS_PER_MINUTE = 1;

// List sessions
router.get('/',
  query('limit').optional().isInt({ min: 1, max: 200 }),
  validate,
  async (req, res) => {
    try {
      const limit = Number(req.query.limit) || 50;
      const result = await pool.query(`
        SELECT ss.*, s.name AS subject_name, s.color AS subject_color
        FROM study_sessions ss
        JOIN subjects s ON s.id = ss.subject_id
        WHERE ss.user_id = $1
        ORDER BY ss.start_time DESC
        LIMIT $2
      `, [req.userId, limit]);
      res.json({ sessions: result.rows });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Failed to fetch sessions' });
    }
  }
);

// Currently running session (if any)
router.get('/active', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT ss.*, s.name AS subject_name, s.color AS subject_color
      FROM study_sessions ss
      JOIN subjects s ON s.id = ss.subject_id
      WHERE ss.user_id = $1 AND ss.end_time IS NULL
      ORDER BY ss.start_time DESC
      LIMIT 1
    `, [req.userId]);
    res.json({ session: result.rows[0] || null });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch active session' });
  }
});

// Start session
router.post('/start',
  body('subjectId').isInt({ min: 1 }).withMessage('subjectId обязателен').toInt(),
  validate,
  async (req, res) => {
    try {
      const { subjectId } = req.body;

      // Subject must belong to the current user
      const subject = await pool.query(
        'SELECT id FROM subjects WHERE id = $1 AND user_id = $2',
        [subjectId, req.userId]
      );
      if (subject.rows.length === 0) return res.status(404).json({ error: 'Subject not found' });

      const result = await pool.query(
        'INSERT INTO study_sessions (user_id, subject_id, start_time) VALUES ($1, $2, NOW()) RETURNING *',
        [req.userId, subjectId]
      );
      res.status(201).json({ session: result.rows[0] });
    } catch (err) {
      // Partial unique index guarantees a single active session per user
      if (err.code === '23505') {
        return res.status(409).json({ error: 'У вас уже есть активное занятие' });
      }
      console.error(err);
      res.status(500).json({ error: 'Failed to start session' });
    }
  }
);

// Cancel (discard) an active session without earning coins
router.delete('/:id',
  param('id').isInt({ min: 1 }).withMessage('Некорректный id').toInt(),
  validate,
  async (req, res) => {
    try {
      const result = await pool.query(
        'DELETE FROM study_sessions WHERE id = $1 AND user_id = $2 AND end_time IS NULL',
        [req.params.id, req.userId]
      );
      if (result.rowCount === 0) {
        return res.status(404).json({ error: 'Active session not found' });
      }
      res.json({ message: 'Session cancelled' });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Failed to cancel session' });
    }
  }
);

// End session
router.post('/end/:id',
  param('id').isInt({ min: 1 }).withMessage('Некорректный id').toInt(),
  validate,
  async (req, res) => {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const result = await client.query(`
        UPDATE study_sessions
        SET end_time = NOW(),
            duration = EXTRACT(EPOCH FROM (NOW() - start_time))::int
        WHERE id = $1 AND user_id = $2 AND end_time IS NULL
        RETURNING *
      `, [req.params.id, req.userId]);

      if (result.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Active session not found' });
      }

      const session = result.rows[0];
      const coinsEarned = Math.floor(session.duration / 60) * COINS_PER_MINUTE;
      const user = await client.query(
        'UPDATE users SET coins = coins + $1 WHERE id = $2 RETURNING coins',
        [coinsEarned, req.userId]
      );
      await client.query('COMMIT');

      res.json({ session, coins_earned: coinsEarned, coins: user.rows[0].coins });
    } catch (err) {
      await client.query('ROLLBACK').catch(() => {});
      console.error(err);
      res.status(500).json({ error: 'Failed to end session' });
    } finally {
      client.release();
    }
  }
);

module.exports = router;