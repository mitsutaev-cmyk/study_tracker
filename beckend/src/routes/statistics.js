const express = require('express');
const { authenticateToken } = require('../middleware/auth');
const pool = require('../config/db');

const router = express.Router();

// Get stats by subject
router.get('/', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        s.id, s.name,
        COUNT(ss.id) as session_count,
        COALESCE(SUM(ss.duration), 0) as total_seconds
      FROM subjects s
      LEFT JOIN study_sessions ss ON s.id = ss.subject_id
      WHERE s.user_id = $1
      GROUP BY s.id, s.name
    `, [req.userId]);
    
    res.json(result.rows.map(row => ({
      ...row,
      total_hours: (row.total_seconds / 3600).toFixed(2)
    })));
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch statistics' });
  }
});

module.exports = router;