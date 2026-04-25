const bcrypt = require('bcrypt');

async function hashPassword(password) {
    if (!password || password.length < 6) {
        throw new Error("Password has at least 6 characters");
    }
    const saltRounds = 10;
    return await bcrypt.hash(password, saltRounds);
}

module.exports = { hashPassword };
