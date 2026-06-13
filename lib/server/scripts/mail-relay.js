const express = require('express');
const path = require('path');
const nodemailer = require('nodemailer');

require('dotenv').config({ path: path.resolve(__dirname, '..', '.env') });

const port = Number.parseInt(process.env.MAIL_RELAY_PORT || '8787', 10);
const relayToken = String(process.env.MAIL_RELAY_TOKEN || '').trim();
const smtpService = String(process.env.SMTP_SERVICE || process.env.GMAIL_SERVICE || 'gmail').trim();
const smtpUser = String(process.env.SMTP_USER || process.env.GMAIL_USER || '').trim();
const smtpPass = String(process.env.SMTP_PASS || process.env.GMAIL_APP_PASSWORD || '').replace(
  /\s/g,
  ''
);
const smtpFrom = String(process.env.SMTP_FROM || process.env.GMAIL_FROM || smtpUser).trim();
const smtpHost = String(process.env.SMTP_HOST || '').trim();
const smtpPort = Number.parseInt(process.env.SMTP_PORT || '', 10);
const smtpSecure = String(process.env.SMTP_SECURE || '').toLowerCase() === 'true';
const resetCodeTtlMin = Number.parseInt(process.env.RESET_CODE_TTL_MIN || '10', 10);

const normalizeEmail = (value) => String(value || '').trim().toLowerCase();
const validateEmail = (email) =>
  email.length <= 254 && /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email);

if (!relayToken) {
  console.error('MAIL_RELAY_TOKEN is required in lib/server/.env');
  process.exit(1);
}

if (!smtpUser || !smtpPass) {
  console.error('SMTP_USER and SMTP_PASS are required in lib/server/.env');
  process.exit(1);
}

const buildTransportCandidates = () => {
  const auth = {
    user: smtpUser,
    pass: smtpPass,
  };
  const service = smtpService || 'gmail';
  const isGmail =
    service.toLowerCase().includes('gmail') || smtpHost.toLowerCase().includes('gmail');
  const candidates = [];
  const names = new Set();
  const addCandidate = (name, options) => {
    if (names.has(name)) return;
    names.add(name);
    candidates.push({ name, options });
  };

  if (smtpHost) {
    addCandidate(`host:${smtpHost}:${Number.isInteger(smtpPort) ? smtpPort : 587}`, {
      host: smtpHost,
      port: Number.isInteger(smtpPort) ? smtpPort : 587,
      secure: smtpSecure,
      auth,
    });
  }

  if (isGmail) {
    addCandidate('gmail:smtp-587-starttls', {
      host: 'smtp.gmail.com',
      port: 587,
      secure: false,
      auth,
    });
  }

  if (!smtpHost) {
    addCandidate(`service:${service}`, {
      service,
      auth,
    });
  }

  if (isGmail) {
    addCandidate('gmail:smtp-465-ssl', {
      host: 'smtp.gmail.com',
      port: 465,
      secure: true,
      auth,
    });
  }

  return candidates;
};

const sendMailWithFallback = async (message) => {
  const candidates = buildTransportCandidates();
  let lastError = null;

  for (const candidate of candidates) {
    try {
      const transporter = nodemailer.createTransport(candidate.options);
      return await transporter.sendMail(message);
    } catch (error) {
      lastError = error;
      console.error(
        JSON.stringify({
          smtpTransport: candidate.name,
          message: error.message,
          code: error.code,
          command: error.command,
          responseCode: error.responseCode,
        })
      );
    }
  }

  throw lastError || new Error('No SMTP transport candidates available');
};

const requireRelayAuth = (req, res, next) => {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7).trim() : '';
  if (token !== relayToken) {
    return res.status(401).json({ message: 'Unauthorized' });
  }
  return next();
};

const app = express();
app.use(express.json({ limit: '32kb' }));

app.get('/health', (req, res) => {
  res.json({ ok: true });
});

app.post('/send-reset-code', requireRelayAuth, async (req, res) => {
  const email = normalizeEmail(req.body?.email);
  const code = String(req.body?.code || '').trim();

  if (!validateEmail(email)) {
    return res.status(400).json({ message: 'Invalid email' });
  }
  if (!/^\d{6}$/.test(code)) {
    return res.status(400).json({ message: 'Invalid reset code' });
  }

  try {
    const result = await sendMailWithFallback({
      from: smtpFrom,
      to: email,
      subject: 'Gul alem password reset code',
      text: `Your Gul alem password reset code is ${code}. It expires in ${resetCodeTtlMin} minutes.`,
      html: `<p>Your Gul alem password reset code is <b>${code}</b>.</p><p>It expires in ${resetCodeTtlMin} minutes.</p>`,
    });
    console.log(
      JSON.stringify({
        sent: true,
        to: email,
        messageId: result.messageId,
        accepted: result.accepted,
        rejected: result.rejected,
      })
    );
    return res.json({ sent: true });
  } catch (error) {
    console.error(
      JSON.stringify({
        sent: false,
        to: email,
        message: error.message,
        code: error.code,
        command: error.command,
        responseCode: error.responseCode,
      })
    );
    return res.status(502).json({ message: 'SMTP send failed' });
  }
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Gul Alem mail relay listening on http://127.0.0.1:${port}`);
});
