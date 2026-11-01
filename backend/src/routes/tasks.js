const express = require('express');
const { body, param, query } = require('express-validator');
const { authenticateToken } = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const pool = require('../config/db');

const router = express.Router();

router.use(authenticateToken);

// `to_char` keeps DATE values as plain strings, so no timezone shift can move
// a task to the previous day when it is serialised to JSON.
const TASK_COLUMNS =
  "id, title, notes, to_char(due_date, 'YYYY-MM-DD') AS due_date, " +
  'completed, completed_at, created_at';

const isDate = (value) => /^\d{4}-\d{2}-\d{2}$/.test(value || '');

// Tasks for a date range (defaults to the current month)
router.get('/',
  query('from').optional().custom(isDate).withMessage('Некорректная дата начала'),
  query('to').optional().custom(isDate).withMessage('Некорректная дата конца'),
  validate,
  async (req, res) => {
    try {
      const from = req.query.from || null;
      const to = req.query.to || null;

      const result = await pool.query(`
        SELECT ${TASK_COLUMNS}
        FROM tasks
        WHERE user_id = $1
          AND ($2::date IS NULL OR due_date >= $2::date)
          AND ($3::date IS NULL OR due_date <= $3::date)
        ORDER BY due_date ASC, completed ASC, id ASC
      `, [req.userId, from, to]);

      res.json({ tasks: result.rows });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Failed to fetch tasks' });
    }
  }
);

// Create task
router.post('/',
  body('title').trim().notEmpty().withMessage('Введите задачу')
    .isLength({ max: 255 }),
  body('notes').optional().isString().isLength({ max: 1000 }),
  body('dueDate').custom(isDate).withMessage('Укажите дату в формате YYYY-MM-DD'),
  validate,
  async (req, res) => {
    try {
      const { title, notes, dueDate } = req.body;
      const result = await pool.query(
        `INSERT INTO tasks (user_id, title, notes, due_date)
         VALUES ($1, $2, $3, $4)
         RETURNING ${TASK_COLUMNS}`,
        [req.userId, title, notes || '', dueDate]
      );
      res.status(201).json({ task: result.rows[0] });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Failed to create task' });
    }
  }
);

// Update task (title, notes, due date, completion)
router.patch('/:id',
  param('id').isInt({ min: 1 }).withMessage('Некорректный id').toInt(),
  body('title').optional().trim().notEmpty().withMessage('Введите задачу')
    .isLength({ max: 255 }),
  body('notes').optional().isString().isLength({ max: 1000 }),
  body('dueDate').optional().custom(isDate).withMessage('Некорректная дата'),
  body('completed').optional().isBoolean().withMessage('Некорректный статус').toBoolean(),
  validate,
  async (req, res) => {
    try {
      const fields = [];
      const values = [];
      const set = (column, value) => {
        values.push(value);
        fields.push(`${column} = $${values.length}`);
      };

      if (req.body.title !== undefined) set('title', req.body.title);
      if (req.body.notes !== undefined) set('notes', req.body.notes);
      if (req.body.dueDate !== undefined) set('due_date', req.body.dueDate);
      if (req.body.completed !== undefined) {
        set('completed', req.body.completed);
        set('completed_at', req.body.completed ? new Date() : null);
      }

      if (fields.length === 0) {
        return res.status(400).json({ error: 'Нет данных для обновления' });
      }

      values.push(req.params.id, req.userId);
      const result = await pool.query(
        `UPDATE tasks SET ${fields.join(', ')}
         WHERE id = $${values.length - 1} AND user_id = $${values.length}
         RETURNING ${TASK_COLUMNS}`,
        values
      );

      if (result.rowCount === 0) {
        return res.status(404).json({ error: 'Задача не найдена' });
      }
      res.json({ task: result.rows[0] });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Failed to update task' });
    }
  }
);

// Delete task
router.delete('/:id',
  param('id').isInt({ min: 1 }).withMessage('Некорректный id').toInt(),
  validate,
  async (req, res) => {
    try {
      const result = await pool.query(
        'DELETE FROM tasks WHERE id = $1 AND user_id = $2',
        [req.params.id, req.userId]
      );
      if (result.rowCount === 0) {
        return res.status(404).json({ error: 'Задача не найдена' });
      }
      res.json({ message: 'Task deleted' });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Failed to delete task' });
    }
  }
);

module.exports = router;
