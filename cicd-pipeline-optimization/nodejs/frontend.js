require('./tracing'); // Tiêm OTel first
const express = require('express');
const axios = require('axios');
const app = express();

const BACKEND_URL = process.env.BACKEND_URL || "http://backend-service:5000";

// Main page to type password
app.get('/', (req, res) => {
    console.log("Frontend - Accessing main page");
    res.send(`
        <h1>DevOps Portal</h1>
        <form action="/hash-me">
            Type your password here: <input type="text" name="pass">
            <button type="submit">Hash & Save</button>
        </form>
        <br><a href="/history">Check history</a>
    `);
});

// Call Backend to hash password
app.get('/hash-me', async (req, res) => {
    console.log("Frontend - Hashing password");
    try {
        const response = await axios.get(`${BACKEND_URL}/process?password=${req.query.pass}`);
        res.send(`<h2>Result: ${response.data.hash}</h2><p>${response.data.db_status}</p><a href="/">Back</a>`);
    } catch (e) {
	console.error("Frontend - Error connecting to Backend:", e.message);
        res.status(500).send("Error connecting to Backend!");
    }
});

// Check history
app.get('/history', async (req, res) => {
    console.log("Frontend - Fetching history");
    try {
        const response = await axios.get(`${BACKEND_URL}/history`);
        let rows = response.data.history.map(h => `<tr><td>${h.original}</td><td>${h.hashed}</td></tr>`).join('');
        res.send(`<h1>Hash history</h1><table border="1"><tr><th>Original</th><th>Hashed</th></tr>${rows}</table><a href="/">Back</a>`);
    } catch (e) {
	console.error("Frontend - Error fetching history:", e.message);
        res.status(500).send("Error to get history from backend!");
    }
});

app.listen(3000, () => console.log('Frontend on port 3000'));
