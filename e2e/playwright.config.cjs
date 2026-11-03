const path = require('path');
const { defineConfig } = require('@playwright/test');

module.exports = defineConfig({
  testDir: './tests',
  timeout: 90000,
  use: {
    baseURL: 'http://127.0.0.1:7357',
    viewport: { width: 390, height: 844 },
    screenshot: 'only-on-failure',
    trace: 'retain-on-failure',
  },
  webServer: {
    command: 'flutter run -d web-server --web-hostname=127.0.0.1 --web-port=7357',
    cwd: path.resolve(__dirname, '../frontend'),
    url: 'http://127.0.0.1:7357',
    reuseExistingServer: !process.env.CI,
    timeout: 180000,
  },
});
