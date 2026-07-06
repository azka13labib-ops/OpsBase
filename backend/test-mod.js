const express = require('express');
const request = require('supertest');
const proxyquire = require('proxyquire');

const app = express();
app.use(express.json());

// Mock requireCapability to always pass
const moderation = proxyquire('./api/routes/moderation', {
  '../middleware/requireCapability': {
    requireCapability: () => (req, res, next) => {
      req.auth = { guildId: '123', userId: '456', username: 'Test' };
      next();
    }
  }
});

app.use('/api/moderation', moderation);

async function runTests() {
  console.log('--- Test POST /api/moderation/warn dengan userId invalid ---');
  const res = await request(app)
    .post('/api/moderation/warn')
    .send({ userId: 'abc123', userTag: 'test#1234', reason: 'test reason' });
  
  console.log('Status Code:', res.statusCode);
  console.log('Response:', res.body);
}
runTests();
