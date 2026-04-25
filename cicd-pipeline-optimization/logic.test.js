const { hashPassword } = require('./logic');

describe('Test hash passwd func', () => {

    test('Case 1: Hash success with valid passwd', async () => {
        const pass = "admin123";
        const result = await hashPassword(pass);

        expect(result).toBeDefined();
        expect(result).not.toBe(pass); // Make sure passwd has to be encrypt
        expect(result.length).toBeGreaterThan(20);
    });

    test('Case 2: Throw error if passwd is short', async () => {
        const shortPass = "12345";
        // Throw error message
        await expect(hashPassword(shortPass))
            .rejects
            .toThrow("Password has at least 6 characters");
    });
});
