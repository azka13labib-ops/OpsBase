const { Client, GatewayIntentBits } = require('discord.js');
require('dotenv').config();

const client = new Client({ intents: [GatewayIntentBits.Guilds] });

client.login(process.env.TOKEN).then(() => {
    console.log("Token is VALID. Logged in as " + client.user.tag);
    process.exit(0);
}).catch(err => {
    console.error("LOGIN FAILED:", err.message);
    process.exit(1);
});
