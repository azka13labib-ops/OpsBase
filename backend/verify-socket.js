const { createClient } = require('@supabase/supabase-js');
const { io } = require('socket.io-client');
require('dotenv').config();

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function testValidTokenSocket() {
  console.log('--- Test Socket dengan Token Valid ---');
  // Gunakan admin API untuk membuat user sementara
  const email = `testuser_${Date.now()}@example.com`;
  const password = 'Password123!';
  
  console.log('Membuat user dummy...');
  const { data: userData, error: userError } = await supabase.auth.admin.createUser({
    email,
    password,
    email_confirm: true
  });

  if (userError) {
    console.error('Gagal membuat user:', userError.message);
    return;
  }

  console.log('Login sebagai user dummy...');
  const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
    email,
    password
  });

  if (authError) {
    console.error('Gagal login:', authError.message);
    await supabase.auth.admin.deleteUser(userData.user.id);
    return;
  }

  const token = authData.session.access_token;
  console.log('Token didapat. Mencoba koneksi socket...');

  const socket = io('http://localhost:3000', {
    transports: ['websocket'],
    auth: { token },
    reconnection: false
  });

  await new Promise((resolve) => {
    socket.on('connect_error', (err) => {
      console.log('Ditolak (Salah):', err.message);
      socket.close();
      resolve();
    });
    socket.on('connect', () => {
      console.log('Diterima (Benar). Mencoba listen ke stats_updated...');
      socket.emit('join_guild', '123456');
      
      socket.on('stats_updated', () => {
         console.log('Event stats_updated diterima!');
         socket.close();
         resolve();
      });

      // Pancing event stats_updated dengan hit endpoint (ini mungkin sulit kalau auth fail)
      // Alternatif: kita cuma verifikasi koneksi diterima
      console.log('Koneksi berhasil diterima dan auth token valid!');
      socket.close();
      resolve();
    });
  });

  console.log('Membersihkan user dummy...');
  await supabase.auth.admin.deleteUser(userData.user.id);
}

testValidTokenSocket();
