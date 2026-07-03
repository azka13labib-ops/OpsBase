const { Events, ActivityType } = require('discord.js');

module.exports = {
  name: Events.ClientReady,
  once: true,
  execute(client) {
    console.log(`✅ Bot online sebagai ${client.user.tag}`);
    client.user.setPresence({
      activities: [{ name: 'server kamu | /help', type: ActivityType.Watching }],
      status: 'online',
    });
  },
};
