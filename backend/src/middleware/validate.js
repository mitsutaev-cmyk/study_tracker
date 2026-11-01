const { validationResult } = require('express-validator');

// Returns 400 with the first validation message if express-validator found errors.
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (errors.isEmpty()) return next();

  const list = errors.array();
  return res.status(400).json({ error: list[0].msg, errors: list });
};

module.exports = { validate };
