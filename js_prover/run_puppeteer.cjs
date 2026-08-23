const puppeteer = require('puppeteer');
(async () => {
    const browser = await puppeteer.launch({ headless: true, args: ['--no-sandbox'] });
    const page = await browser.newPage();
    page.on('console', msg => {
        console.log('BROWSER_LOG:', msg.text());
        if (msg.text().includes('RESULT_JSON')) {
            process.exit(0);
        }
    });
    await page.goto('http://localhost:8081/test.html');
    setTimeout(() => { console.log('TIMEOUT'); process.exit(1); }, 10000);
})();
