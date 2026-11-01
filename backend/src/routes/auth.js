const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body } = require('express-validator');
const pool = require('../config/db');
const { authenticateToken } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();

const signToken = (userId) =>
  jwt.sign({ userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });

const publicUser = (u) => ({
  id: u.id,
  email: u.email,
  name: u.name,
  coins: u.coins ?? 0,
  avatar: u.avatar ?? '🎓',
  bio: u.bio ?? '',
  daily_goal_minutes: u.daily_goal_minutes ?? 60,
  accent_color: u.accent_color ?? '#4F46E5',
  theme_mode: u.theme_mode ?? 'system',
});

const USER_COLUMNS =
  'id, email, name, coins, avatar, bio, daily_goal_minutes, accent_color, theme_mode';

// Register
router.post('/register',
  body('email').isEmail().withMessage('Некорректный email').normalizeEmail(),
  body('password').isLength({ min: 6 }).withMessage('Пароль должен быть не короче 6 символов'),
  body('name').optional().trim().isLength({ max: 255 }),
  validate,
  async (req, res) => {
    try {
      const { email, password, name } = req.body;
      const hashedPassword = await bcrypt.hash(password, 10);

      const result = await pool.query(
        `INSERT INTO users (email, password, name) VALUES ($1, $2, $3) RETURNING ${USER_COLUMNS}`,
        [email, hashedPassword, name || null]
      );

      const user = result.rows[0];
      res.status(201).json({ user: publicUser(user), token: signToken(user.id) });
    } catch (err) {
      if (err.code === '23505') {
        return res.status(409).json({ error: 'Пользователь с таким email уже существует' });
      }
      console.error(err);
      res.status(500).json({ error: 'Registration failed' });
    }
  }
);

// Login
router.post('/login',
  body('email').isEmail().withMessage('Некорректный email').normalizeEmail(),
  body('password').notEmpty().withMessage('Введите пароль'),
  validate,
  async (req, res) => {
    try {
      const { email, password } = req.body;
      const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
      const user = result.rows[0];

      // Same message for both cases so emails can't be enumerated
      if (!user || !(await bcrypt.compare(password, user.password))) {
        return res.status(401).json({ error: 'Неверный email или пароль' });
      }

      res.json({ user: publicUser(user), token: signToken(user.id) });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Login failed' });
    }
  }
);

// Validate token / current user
const me = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT ${USER_COLUMNS} FROM users WHERE id = $1`,
      [req.userId]
    );
    if (result.rows.length === 0) return res.status(401).json({ error: 'User not found' });
    res.json({ user: publicUser(result.rows[0]) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch user' });
  }
};
router.get('/validate', authenticateToken, me);
router.get('/me', authenticateToken, me);

// Update profile customisation
router.patch('/profile',
  authenticateToken,
  body('name').optional().trim().isLength({ min: 1, max: 255 })
    .withMessage('Имя должно быть от 1 до 255 символов'),
  body('bio').optional().isString().isLength({ max: 500 })
    .withMessage('Био не длиннее 500 символов'),
  body('avatar').optional().isString().isLength({ max: 16 })
    .withMessage('Некорректный аватар'),
  body('daily_goal_minutes').optional().isInt({ min: 5, max: 720 })
    .withMessage('Цель дня должна быть от 5 до 720 минут').toInt(),
  body('accent_color').optional().matches(/^#[0-9A-Fa-f]{6}$/)
    .withMessage('Цвет должен быть в формате #RRGGBB'),
  body('theme_mode').optional().isIn(['system', 'light', 'dark'])
    .withMessage('Некорректная тема'),
  validate,
  async (req, res) => {
    try {
      const fields = [];
      const values = [];
      const set = (column, value) => {
        values.push(value);
        fields.push(`${column} = $${values.length}`);
      };

      const {
        name,
        bio,
        avatar,
        daily_goal_minutes: dailyGoalMinutes,
        accent_color: accentColor,
        theme_mode: themeMode,
      } = req.body;

      if (name !== undefined) set('name', name);
      if (bio !== undefined) set('bio', bio);
      if (avatar !== undefined) set('avatar', avatar);
      if (dailyGoalMinutes !== undefined) set('daily_goal_minutes', dailyGoalMinutes);
      if (accentColor !== undefined) set('accent_color', accentColor);
      if (themeMode !== undefined) set('theme_mode', themeMode);

      if (fields.length === 0) {
        return res.status(400).json({ error: 'Нет данных для обновления' });
      }

      values.push(req.userId);
      const result = await pool.query(
        `UPDATE users SET ${fields.join(', ')} WHERE id = $${values.length}
         RETURNING ${USER_COLUMNS}`,
        values
      );

      res.json({ user: publicUser(result.rows[0]) });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Failed to update profile' });
    }
  }
);

// JWT is stateless: the client just drops the token
router.post('/logout', authenticateToken, (req, res) => {
  res.json({ message: 'Logged out' });
});

// Change password
router.post('/change-password',
  authenticateToken,
  body('old_password').notEmpty().withMessage('Введите текущий пароль'),
  body('new_password').isLength({ min: 6 }).withMessage('Новый пароль должен быть не короче 6 символов'),
  validate,
  async (req, res) => {
    try {
      const { old_password: oldPassword, new_password: newPassword } = req.body;
      const result = await pool.query('SELECT password FROM users WHERE id = $1', [req.userId]);
      const user = result.rows[0];

      if (!user || !(await bcrypt.compare(oldPassword, user.password))) {
        return res.status(400).json({ error: 'Текущий пароль неверен' });
      }

      const hashed = await bcrypt.hash(newPassword, 10);
      await pool.query('UPDATE users SET password = $1 WHERE id = $2', [hashed, req.userId]);
      res.json({ message: 'Password changed' });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Failed to change password' });
    }
  }
);

module.exports = router;