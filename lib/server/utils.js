const crypto = require('crypto');

const getPaymentKey = (paymentEncKey = process.env.PAYMENT_ENC_KEY || '') => {
  if (!paymentEncKey) {
    throw new Error('PAYMENT_ENC_KEY missing');
  }
  const key = Buffer.from(paymentEncKey, 'base64');
  if (key.length !== 32) {
    throw new Error('PAYMENT_ENC_KEY must be 32 bytes (base64)');
  }
  return key;
};

const encryptField = (value, paymentEncKey) => {
  const key = getPaymentKey(paymentEncKey);
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
  const encrypted = Buffer.concat([cipher.update(String(value), 'utf8'), cipher.final()]);
  const tag = cipher.getAuthTag();
  return {
    iv: iv.toString('base64'),
    tag: tag.toString('base64'),
    data: encrypted.toString('base64'),
  };
};

const decryptField = (payload, paymentEncKey) => {
  const key = getPaymentKey(paymentEncKey);
  const iv = Buffer.from(payload.iv, 'base64');
  const tag = Buffer.from(payload.tag, 'base64');
  const data = Buffer.from(payload.data, 'base64');
  const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
  decipher.setAuthTag(tag);
  const decrypted = Buffer.concat([decipher.update(data), decipher.final()]);
  return decrypted.toString('utf8');
};

const hashToken = (value) => crypto.createHash('sha256').update(String(value)).digest('hex');

const normalizeTagList = (value) => {
  if (!value) return [];
  if (Array.isArray(value)) {
    return value.map((item) => String(item).trim()).filter(Boolean);
  }
  if (typeof value === 'string') {
    return value
      .split(',')
      .map((item) => item.trim())
      .filter(Boolean);
  }
  return [];
};

const dedupeTags = (tags) => Array.from(new Set(tags));

const hasKeyword = (text, keywords) => keywords.some((keyword) => text.includes(keyword));

const escapeRegex = (value) => String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const stripMarkdown = (value) => {
  if (!value) return '';
  let text = String(value);
  text = text.replace(/[`*_]/g, '');
  text = text.replace(/^\s*[-+•]\s+/gm, '');
  text = text.replace(/^\s*#{1,6}\s+/gm, '');
  text = text.replace(/>\s?/g, '');
  text = text.replace(/\s{2,}/g, ' ');
  return text.trim();
};

const isFlowerTopic = (value) => {
  const text = String(value || '').toLowerCase();
  const keywords = [
    'гүл',
    'гуль',
    'цвет',
    'букет',
    'раушан',
    'роз',
    'роза',
    'тюльпан',
    'қызғалдақ',
    'пион',
    'лилия',
    'гортенз',
    'хризантем',
    'орхид',
    'кактус',
    'шар',
    'bouquet',
    'flower',
    'rose',
    'tulip',
    'peony',
    'lily',
    'hydrangea',
    'chrysanthem',
    'succulent',
    'gift',
    'сыйлық',
  ];
  return keywords.some((keyword) => text.includes(keyword));
};

const buildChatTitle = (message) => {
  const text = String(message || '').trim();
  if (!text) return 'Жаңа чат';
  return text.length > 40 ? `${text.slice(0, 40)}…` : text;
};

const mapTagMatches = (text) => {
  const match = (terms) => terms.some((term) => text.includes(term));
  const occasion = [];
  const recipient = [];
  if (match(['birthday', 'туған', 'день рождения', 'мереке', 'шар'])) {
    occasion.push('birthday');
  }
  if (match(['wedding', 'үйлен', 'неке', 'свад'])) {
    occasion.push('wedding');
  }
  if (match(['love', 'махаббат', 'роман'])) {
    occasion.push('love');
  }
  if (match(['құттық', 'congrat', 'құттықтау'])) {
    occasion.push('congrats');
  }
  if (match(['мама', 'ана', 'mom'])) {
    recipient.push('mom');
  }
  if (match(['қыз', 'girl', 'қалыңдық'])) {
    recipient.push('girl');
  }
  if (match(['дос', 'friend'])) {
    recipient.push('friend');
  }
  if (match(['әріптес', 'colleague'])) {
    recipient.push('colleague');
  }
  return { occasion: dedupeTags(occasion), recipient: dedupeTags(recipient) };
};

const buildAutoTags = (name) => {
  const text = String(name || '').toLowerCase();
  const occasion = new Set();
  const recipient = new Set();

  if (hasKeyword(text, ['туған', 'birthday', 'мереке', 'шар'])) {
    occasion.add('birthday');
    occasion.add('congrats');
  }

  if (hasKeyword(text, ['махаббат', 'роман', 'раушан', 'пион', 'қызғалдақ'])) {
    occasion.add('love');
    recipient.add('girl');
  }

  if (
    hasKeyword(text, ['үйлен', 'неке', 'свад', 'wedding']) ||
    (hasKeyword(text, ['ақ']) && hasKeyword(text, ['раушан', 'пион']))
  ) {
    occasion.add('wedding');
  }

  if (hasKeyword(text, ['құттық', 'congrat', 'сыйлық', 'ақша', 'шар'])) {
    occasion.add('congrats');
  }

  if (hasKeyword(text, ['ақша'])) {
    recipient.add('colleague');
  }

  if (hasKeyword(text, ['тәтті', 'жеміс'])) {
    recipient.add('friend');
  }

  if (hasKeyword(text, ['лилия', 'гортензия', 'хризантема'])) {
    recipient.add('mom');
  }

  if (hasKeyword(text, ['аю'])) {
    recipient.add('girl');
  }

  if (occasion.size === 0) occasion.add('no_reason');
  if (recipient.size === 0) recipient.add('universal');
  recipient.add('universal');

  return {
    occasionTags: Array.from(occasion),
    recipientTags: Array.from(recipient),
  };
};

const resolveProductTags = ({ occasionTags, recipientTags, name }) => {
  const normalizedOccasion = normalizeTagList(occasionTags);
  const normalizedRecipient = normalizeTagList(recipientTags);
  const auto = buildAutoTags(name);

  return {
    occasionTags: normalizedOccasion.length > 0 ? dedupeTags(normalizedOccasion) : auto.occasionTags,
    recipientTags:
      normalizedRecipient.length > 0 ? dedupeTags(normalizedRecipient) : auto.recipientTags,
  };
};

module.exports = {
  getPaymentKey,
  encryptField,
  decryptField,
  hashToken,
  normalizeTagList,
  dedupeTags,
  escapeRegex,
  stripMarkdown,
  isFlowerTopic,
  buildChatTitle,
  mapTagMatches,
  buildAutoTags,
  resolveProductTags,
};
