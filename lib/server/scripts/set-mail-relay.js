const path = require('path');

require('dotenv').config({ path: path.resolve(__dirname, '..', '.env') });

const [relayUrl, login, password, baseUrlArg] = process.argv.slice(2);
const defaultBaseUrl = 'https://gul-alem.onrender.com';
const baseUrl = String(
  baseUrlArg || process.env.SET_MAIL_RELAY_BASE_URL || process.env.RENDER_BASE_URL || defaultBaseUrl
)
  .trim()
  .replace(/\/+$/, '');
const relayToken = String(process.env.MAIL_RELAY_TOKEN || '').trim();

const usage = () => {
  console.error(
    'Usage: npm run set-mail-relay -- <ngrok-url> <super-admin-email> <password> [base-url]'
  );
};

const postJson = async (url, body, token) => {
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;
  let response;
  try {
    response = await fetch(url, {
      method: 'POST',
      headers,
      body: JSON.stringify(body),
    });
  } catch (error) {
    const reason = error?.cause?.code || error?.message || 'request failed';
    throw new Error(`${url} request failed: ${reason}`);
  }
  const text = await response.text();
  let data = {};
  try {
    data = text ? JSON.parse(text) : {};
  } catch (_) {
    data = { raw: text };
  }
  if (!response.ok) {
    throw new Error(`${url} failed (${response.status}): ${data.message || text}`);
  }
  return data;
};

(async () => {
  if (!relayUrl || !login || !password) {
    usage();
    process.exit(1);
  }
  if (!relayToken) {
    throw new Error('MAIL_RELAY_TOKEN is missing in lib/server/.env');
  }
  if (typeof fetch !== 'function') {
    throw new Error('This script needs Node.js with global fetch support');
  }

  const loginData = await postJson(`${baseUrl}/auth/login`, { login, password });
  if (!loginData.token) {
    throw new Error('Login succeeded but token was missing');
  }

  const relayData = await postJson(
    `${baseUrl}/mail-relay`,
    { url: relayUrl, token: relayToken },
    loginData.token
  );

  console.log(
    JSON.stringify(
      {
        saved: true,
        baseUrl,
        relayUrl: relayData.url,
        source: relayData.source,
        hasToken: relayData.hasToken,
        tokenPreview: relayData.tokenPreview,
      },
      null,
      2
    )
  );
})().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
