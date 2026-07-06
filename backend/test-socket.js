const { io } = require('socket.io-client');

async function testSocket() {
  console.log('--- Test Socket Tanpa Token ---');
  const socket1 = io('http://localhost:3000', {
    transports: ['websocket'],
    reconnection: false
  });
  
  await new Promise((resolve) => {
    socket1.on('connect_error', (err) => {
      console.log('Ditolak (Benar):', err.message);
      socket1.close();
      resolve();
    });
    socket1.on('connect', () => {
      console.log('Diterima (Salah)');
      socket1.close();
      resolve();
    });
  });

  console.log('\n--- Test Socket Token Invalid ---');
  const socket2 = io('http://localhost:3000', {
    transports: ['websocket'],
    auth: { token: 'token_asal_asalan' },
    reconnection: false
  });

  await new Promise((resolve) => {
    socket2.on('connect_error', (err) => {
      console.log('Ditolak (Benar):', err.message);
      socket2.close();
      resolve();
    });
    socket2.on('connect', () => {
      console.log('Diterima (Salah)');
      socket2.close();
      resolve();
    });
  });
}

testSocket();
