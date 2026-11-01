const jwt = require('jsonwebtoken');

const authenticateToken = (req, res, next) => {
  const header = req.headers['authorization'] || '';
  const [scheme, token] = header.split(' ');

  if (scheme !== 'Bearer' || !token) {
    return res.status(401).json({ error: 'No token provided' });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
    // 401 so the client knows it must log in again
    if (err) return res.status(401).json({ error: 'Invalid or expired token' });
    req.userId = decoded.userId;
    next();
  });
};

module.exports = { authenticateToken };