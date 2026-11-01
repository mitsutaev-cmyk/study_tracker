const path = require('path');

// Load beckend/.env regardless of the current working directory.
require('dotenv').config({ path: path.join(__dirname, '..', '..', '.env') });

if (!process.env.JWT_SECRET) {
  console.error('JWT_SECRET is not set. Copy .env.example to .env and fill it in.');
  process.exit(1);
}

module.exports = process.env;
