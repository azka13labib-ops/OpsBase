const request = require('supertest');
const http = require('http');

async function testCORS() {
  console.log('--- Test CORS ---');
  return new Promise((resolve) => {
    const req1 = http.request({
      hostname: 'localhost',
      port: 3000,
      path: '/health',
      method: 'GET',
      headers: { 'Origin': 'http://evil.com' }
    }, (res) => {
      console.log('CORS http://evil.com -> Status:', res.statusCode);
      
      const req2 = http.request({
        hostname: 'localhost',
        port: 3000,
        path: '/health',
        method: 'GET',
        headers: { 'Origin': 'http://localhost:3000' }
      }, (res2) => {
        console.log('CORS http://localhost:3000 -> Status:', res2.statusCode);
        resolve();
      });
      req2.end();
    });
    req1.on('error', (e) => console.error(e));
    req1.end();
  });
}

async function testRateLimit() {
  console.log('\n--- Test Rate Limit (/api/moderation/warn) ---');
  let successCount = 0;
  let limitedCount = 0;
  
  for(let i=1; i<=12; i++) {
    await new Promise((resolve) => {
      const req = http.request({
        hostname: 'localhost',
        port: 3000,
        path: '/api/moderation/warn',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer fake_token'
        }
      }, (res) => {
        // Karena fake token, expect 401 jika rate limit belum kena
        // Jika rate limit kena, expect 429
        if (res.statusCode === 429) limitedCount++;
        else successCount++;
        resolve();
      });
      req.write(JSON.stringify({ userId: "123", reason: "test" }));
      req.end();
    });
  }
  console.log(`Requests processed (401 expected): ${successCount}`);
  console.log(`Requests rate limited (429 expected): ${limitedCount}`);
}

async function run() {
  await testCORS();
  await testRateLimit();
}
run();
