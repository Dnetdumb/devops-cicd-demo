require('./tracing'); // Tiêm OTel first
const express = require('express');
const winston = require('winston');
const { hashPassword } = require('./logic');
const { writeDB, readDB } = require('./postgres');   //READ/WRITE Split
const app = express();

// Cấu hình Logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(), // Xuất ra JSON để Loki dễ parse
  transports: [
    new winston.transports.Console(),
  ],
});


// Process hash and save
app.get('/process', async (req, res) => {
//    console.log("Backend - Hashing password: ${req.query.password}");
    logger.info("Backend - Hashing password: ${req.query.password}");
    try {
        const hashed = await hashPassword(req.query.password);
        // Save to DB
        await writeDB.query('INSERT INTO password_logs(original, hashed) VALUES($1, $2)', [req.query.password, hashed]);
        res.json({ hash: hashed, db_status: "Saved to DB" });
    } catch (e) {
//	console.error("Backend - Error in backend:", e.message);
	logger.error("Backend - Error: ${e.message}");
        res.status(500).json({ error: e.message });
    }
});

// query history
app.get('/history', async (req, res) => {
//    console.log("Backend - Fetching history");
    logger.info("Backend - Fetching history");
    try {
        const result = await readDB.query('SELECT * FROM password_logs ORDER BY id DESC LIMIT 10');
        res.json({ history: result.rows });
    } catch (e) {
//	console.error("Backend - Error fetching history:", e.message);
	logger.error("Backend - Error fetching history: ${e.message}");
        res.status(500).json({ error: e.message });
    }
});

// app.listen(5000, () => console.log('Backend on port 5000'));
app.listen(5000, () => logger.info("Backend on port 5000"));
