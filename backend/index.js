require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { Client, GatewayIntentBits, Collection, Partials } = require('discord.js');
const { createApiServer } = require('./api/server');
const { initFirebase } = require('./services/push');

const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.GuildModeration,
    GatewayIntentBits.GuildMembers,
    GatewayIntentBits.GuildPresences,
    GatewayIntentBits.GuildScheduledEvents,
  ],
  partials: [Partials.Message, Partials.Channel, Partials.GuildMember, Partials.GuildScheduledEvent],
});

// ----- Load Commands -----
client.commands = new Collection();
const commandsPath = path.join(__dirname, 'commands');

for (const folder of fs.readdirSync(commandsPath)) {
  const folderPath = path.join(commandsPath, folder);
  const commandFiles = fs.readdirSync(folderPath).filter(f => f.endsWith('.js'));

  for (const file of commandFiles) {
    const command = require(path.join(folderPath, file));
    if ('data' in command && 'execute' in command) {
      client.commands.set(command.data.name, command);
    }
  }
}

// ----- Load Events -----
const eventsPath = path.join(__dirname, 'events');
const eventFiles = fs.readdirSync(eventsPath).filter(f => f.endsWith('.js'));

for (const file of eventFiles) {
  const event = require(path.join(eventsPath, file));
  if (event.once) {
    client.once(event.name, (...args) => event.execute(...args, client));
  } else {
    client.on(event.name, (...args) => event.execute(...args, client));
  }
}

initFirebase();

client.login(process.env.TOKEN).then(() => {
  const { app, server, io } = createApiServer(client);
  client.io = io;
  const port = process.env.API_PORT || 3000;
  server.listen(port, () => {
    console.log(`🌐 API server & WebSockets jalan di port ${port}`);
  });

  // Broadcast event real-time ke aplikasi mobile
  const broadcastStats = (guildId) => {
    io.to(`guild_${guildId}`).emit('stats_updated');
  };

  client.on('guildMemberAdd', (member) => broadcastStats(member.guild.id));
  client.on('guildMemberRemove', (member) => broadcastStats(member.guild.id));
  client.on('presenceUpdate', (oldP, newP) => {
    if (!newP) return;
    if (oldP?.status !== newP.status) broadcastStats(newP.guild.id);
  });
  client.on('channelCreate', (channel) => broadcastStats(channel.guild.id));
  client.on('channelDelete', (channel) => broadcastStats(channel.guild.id));
  client.on('roleCreate', (role) => broadcastStats(role.guild.id));
  client.on('roleDelete', (role) => broadcastStats(role.guild.id));
  client.on('guildUpdate', (oldG, newG) => {
    if (oldG.premiumSubscriptionCount !== newG.premiumSubscriptionCount) broadcastStats(newG.id);
  });
});
