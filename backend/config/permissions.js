/**
 * Pemetaan role Discord -> kapabilitas yang boleh diakses di app mobile.
 *
 * Nama role di sini HARUS sama persis (case-insensitive) dengan nama role
 * di server Discord kamu. Kalau nama role di Discord diganti, update juga
 * di sini (atau di .env kalau kamu pakai env var, lihat bawah).
 *
 * Member bisa punya lebih dari satu role — kapabilitasnya digabung (union).
 * "Administrator" permission Discord otomatis dapat SEMUA kapabilitas,
 * apa pun nama role-nya (safety net).
 */

const CAPABILITIES = {
  MODERATE_WARN: 'moderate:warn',
  MODERATE_MUTE: 'moderate:mute',
  MODERATE_KICK: 'moderate:kick',
  MODERATE_BAN: 'moderate:ban',
  MODERATE_CLEAR_WARNINGS: 'moderate:clear_warnings',
  EVENTS_CREATE: 'events:create',
  EVENTS_DELETE: 'events:delete',
  DASHBOARD_VIEW: 'dashboard:view',
};

// Nama role diambil dari .env supaya gampang disesuaikan tanpa ubah kode.
// Kalau env var tidak diisi, fallback ke nama default di bawah.
const ROLE_NAMES = {
  OWNER: process.env.ROLE_NAME_OWNER || 'Owner',
  DEVELOPER: process.env.ROLE_NAME_DEVELOPER || 'Developer',
  EVENT_ORGANIZER: process.env.ROLE_NAME_EVENT_ORGANIZER || 'Event Organizer',
  BRAND_AMBASSADOR: process.env.ROLE_NAME_BRAND_AMBASSADOR || 'Brand Ambassador',
  SUPPORTER: process.env.ROLE_NAME_SUPPORTER || 'Supporter',
};

const ROLE_CAPABILITIES = {
  [ROLE_NAMES.OWNER]: [
    CAPABILITIES.MODERATE_WARN, CAPABILITIES.MODERATE_MUTE, CAPABILITIES.MODERATE_KICK,
    CAPABILITIES.MODERATE_BAN, CAPABILITIES.MODERATE_CLEAR_WARNINGS,
    CAPABILITIES.EVENTS_CREATE, CAPABILITIES.EVENTS_DELETE, CAPABILITIES.DASHBOARD_VIEW,
  ],
  [ROLE_NAMES.DEVELOPER]: [
    CAPABILITIES.MODERATE_WARN, CAPABILITIES.MODERATE_MUTE, CAPABILITIES.MODERATE_KICK,
    CAPABILITIES.MODERATE_BAN, CAPABILITIES.MODERATE_CLEAR_WARNINGS,
    CAPABILITIES.EVENTS_CREATE, CAPABILITIES.EVENTS_DELETE, CAPABILITIES.DASHBOARD_VIEW,
  ],
  [ROLE_NAMES.EVENT_ORGANIZER]: [
    CAPABILITIES.EVENTS_CREATE, CAPABILITIES.EVENTS_DELETE, CAPABILITIES.DASHBOARD_VIEW,
  ],
  [ROLE_NAMES.BRAND_AMBASSADOR]: [
    CAPABILITIES.DASHBOARD_VIEW,
  ],
  [ROLE_NAMES.SUPPORTER]: [
    CAPABILITIES.MODERATE_WARN, CAPABILITIES.MODERATE_MUTE, CAPABILITIES.DASHBOARD_VIEW,
  ],
};

/**
 * Hitung kapabilitas gabungan dari semua role yang dipunyai seorang member.
 * @param {import('discord.js').GuildMember} member
 * @returns {string[]} daftar kapabilitas unik
 */
function getCapabilitiesForMember(member) {
  // Administrator Discord = akses penuh, apa pun nama role-nya (safety net)
  if (member.permissions.has('Administrator')) {
    return Object.values(CAPABILITIES);
  }

  const memberRoleNames = member.roles.cache.map(r => r.name.toLowerCase());
  const capabilitySet = new Set();

  for (const [roleName, caps] of Object.entries(ROLE_CAPABILITIES)) {
    if (memberRoleNames.includes(roleName.toLowerCase())) {
      caps.forEach(c => capabilitySet.add(c));
    }
  }

  return [...capabilitySet];
}

module.exports = { CAPABILITIES, ROLE_NAMES, ROLE_CAPABILITIES, getCapabilitiesForMember };
