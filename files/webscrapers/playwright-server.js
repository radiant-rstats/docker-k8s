const express = require('express');
const { chromium } = require('playwright');

const app = express();
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'ok' });
});

// Execute Playwright script
app.post('/execute', async (req, res) => {
    try {
        const { script } = req.body;
        
        if (!script) {
            return res.status(400).json({ success: false, error: 'No script provided' });
        }

        // Create a safe execution context
        const browser = await chromium.launch({ headless: true });
        
        try {
            // Execute the script with browser available
            const result = await eval(`(async () => {
                ${script}
            })()`);
            
            await browser.close();
            
            res.json({
                success: true,
                result: result
            });
        } catch (scriptError) {
            await browser.close();
            res.json({
                success: false,
                error: scriptError.message
            });
        }
    } catch (error) {
        res.json({
            success: false,
            error: error.message
        });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Playwright server running on port ${PORT}`);
});