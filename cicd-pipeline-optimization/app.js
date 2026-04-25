const express = require('express');
const bcrypt = require('bcrypt'); // heavy lib, need glibc to compile
const { Client } = require('pg'); // Ready for Database .
const { hashPassword } = require('./logic');

const app = express();
const port = process.env.PORT || 3000;

app.get('/hash', async (req, res) => {
    try {
        const password = req.query.password || "devops_pro";
        const hashed = await hashPassword(password);
        res.json({ original: password, hash: hashed });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// check health for K8s
app.get('/health', (req, res) => {
    res.status(200).send('OK');
});

if (process.env.NODE_ENV !== 'test') {
    app.listen(port, () => console.log(`App listening at http://localhost:${port}`));
}

module.exports = app;
// Edited here
//Edit some code
