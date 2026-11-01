const express = require('express');
const { authenticateToken } = require('../middleware/auth');
const pool = require('../config/db');

const router = express.Router();

// Get stats by subject
router.get('/', authenticateToken, async (req, res) => {
  try {
    const [bySubject, totals, daily] = await Promise.all([
      pool.query(`
        SELECT
          s.id, s.name, s.color,
          COUNT(ss.id)::int AS session_count,
          COALESCE(SUM(ss.duration), 0)::int AS total_seconds
        FROM subjects s
        LEFT JOIN study_sessions ss ON s.id = ss.subject_id AND ss.end_time IS NOT NULL
        WHERE s.user_id = $1
        GROUP BY s.id
        ORDER BY total_seconds DESC
      `, [req.userId]),
      pool.query(`
        SELECT
          COALESCE(SUM(duration), 0)::int AS total_seconds,
          COALESCE(SUM(duration) FILTER (WHERE start_time >= date_trunc('day', NOW())), 0)::int AS today_seconds,
          COALESCE(SUM(duration) FILTER (WHERE start_time >= NOW() - INTERVAL '7 days'), 0)::int AS week_seconds,
          COUNT(*)::int AS session_count,
          (SELECT coins FROM users WHERE id = $1) AS coins
        FROM study_sessions
        WHERE user_id = $1 AND end_time IS NOT NULL
      `, [req.userId]),
      pool.query(`
        SELECT
          to_char(d.day, 'YYYY-MM-DD') AS date,
          COALESCE(SUM(ss.duration), 0)::int AS seconds
        FROM generate_series(
          date_trunc('day', NOW()) - INTERVAL '6 days',
          date_trunc('day', NOW()),
          INTERVAL '1 day'
        ) AS d(day)
        LEFT JOIN study_sessions ss
          ON ss.user_id = $1
         AND ss.end_time IS NOT NULL
         AND ss.start_time >= d.day
         AND ss.start_time < d.day + INTERVAL '1 day'
        GROUP BY d.day
        ORDER BY d.day
      `, [req.userId]),
    ]);

    res.json({
      ...totals.rows[0],
      subjects: bySubject.rows.map((row) => ({
        ...row,
        total_hours: Number((row.total_seconds / 3600).toFixed(2)),
      })),
      daily: daily.rows,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch statistics' });
  }
});

module.exports = router;