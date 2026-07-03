const { Client, GatewayIntentBits } = require('discord.js');
require('dotenv').config();

const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.GuildModeration,
    GatewayIntentBits.GuildMembers,
    GatewayIntentBits.GuildPresences,
  ],
});

client.once('ready', async () => {
  const guild = client.guilds.cache.first();
  console.log('Guild ID:', guild.id);
  console.log('Member Count:', guild.memberCount);
  console.log('Text Channels:', guild.channels.cache.filter(c => c.type === 0 || c.type === 5).size);
  console.log('Voice Channels:', guild.channels.cache.filter(c => c.type === 2 || c.type === 13).size);
  console.log('Roles:', guild.roles.cache.size);
  console.log('Boosts:', guild.premiumSubscriptionCount);
  console.log('Ping:', client.ws.ping);
  process.exit(0);
});

client.login(process.env.TOKEN);
