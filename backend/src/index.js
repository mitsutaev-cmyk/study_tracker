require('./config/env');
const express = require('express');
const cors = require('cors');
const pool = require('./config/db');

const app = express();

// Middleware
app.use(cors());
app.use(express.json({ limit: '1mb' }));

// Test DB connection
pool.query('SELECT NOW()')
  .then((res) => console.log('DB connected:', res.rows[0].now))
  .catch((err) => console.error('DB connection failed:', err.message));

// Routes
app.get('/api/health', (req, res) => res.json({ status: 'ok' }));
app.use('/api/auth', require('./routes/auth'));
app.use('/api/subjects', require('./routes/subjects'));
app.use('/api/sessions', require('./routes/sessions'));
app.use('/api/statistics', require('./routes/statistics'));
app.use('/api/ai', require('./routes/ai'));
app.use('/api/tasks', require('./routes/tasks'));
app.use('/api/motivation', require('./routes/motivation'));

// 404
app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// Error handling
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  console.error(err);
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({ error: 'Invalid JSON' });
  }
  res.status(500).json({ error: 'Internal server error' });
});

const PORT = process.env.PORT || 5000;
// 0.0.0.0 so a phone/emulator on the same network can reach the server
app.listen(PORT, '0.0.0.0', () => console.log(`Server running on port ${PORT}`));