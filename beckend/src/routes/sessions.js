const express = require('express');
const { authenticateToken } = require('../middleware/auth');
const pool = require('../config/db');

const router = express.Router();

// Start session
router.post('/start', authenticateToken, async (req, res) => {
  try {
    const { subjectId } = req.body;
    const result = await pool.query(
      'INSERT INTO study_sessions (user_id, subject_id, start_time) VALUES ($1, $2, NOW()) RETURNING *',
      [req.userId, subjectId]
    );
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to start session' });
  }
});

// End session
router.post('/end/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      'UPDATE study_sessions SET end_time = NOW(), duration = EXTRACT(EPOCH FROM (NOW() - start_time)) WHERE id = $1 RETURNING *',
      [id]
    );
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to end session' });
  }
});

module.exports = router;