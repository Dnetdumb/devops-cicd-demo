const { Pool } = require('pg');

// Split Read/Write

// WRITE (primary)
const writeDB = new Pool({
  host: process.env.DB_HOST_RW || 'pg-cluster-rw',
  port: process.env.DB_PORT || 5432,
  user: process.env.DB_USER || 'app',
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || 'mydb',
  max: 10
});

// READ (replica)
const readDB = new Pool({
  host: process.env.DB_HOST_RO || 'pg-cluster-ro',
  port: process.env.DB_PORT || 5432,
  user: process.env.DB_USER || 'app',
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || 'mydb',
  max: 20
});

module.exports = {
  writeDB,
  readDB
};
