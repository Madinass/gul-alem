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

const normalizeFullName = (value) => String(value || '').trim().replace(/\s+/g, ' ');

const normalizeEmail = (value) => String(value || '').trim().toLowerCase();

const normalizePhone = (value) => String(value || '').replace(/\D/g, '');

const validateFullName = (name) => {
  const value = normalizeFullName(name);
  return (
    value.length >= 2 &&
    value.length <= 80 &&
    /\p{L}/u.test(value) &&
    /^[\p{L}\p{M}\s'.-]+$/u.test(value)
  );
};

const validateEmail = (email) => {
  const value = normalizeEmail(email);
  return value.length <= 254 && /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(value);
};

const validatePhone = (phone) => {
  const digits = normalizePhone(phone);
  return digits.length >= 10 && digits.length <= 11;
};

const normalizePaymentExpiry = ({ expMonth, expYear }, now = new Date()) => {
  const monthText = String(expMonth || '').trim();
  const yearText = String(expYear || '').trim();
  if (!/^\d{1,2}$/.test(monthText) || !/^(\d{2}|\d{4})$/.test(yearText)) {
    return null;
  }

  const month = Number.parseInt(monthText, 10);
  const year =
    yearText.length === 2
      ? 2000 + Number.parseInt(yearText, 10)
      : Number.parseInt(yearText, 10);
  const currentYear = now.getFullYear();
  const currentMonth = now.getMonth() + 1;

  if (!Number.isInteger(month) || month < 1 || month > 12) return null;
  if (!Number.isInteger(year) || year > 2100) return null;
  if (year < currentYear || (year === currentYear && month < currentMonth)) {
    return null;
  }

  return {
    expMonth: String(month).padStart(2, '0'),
    expYear: String(year),
  };
};

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

const normalizeVisionText = (value) =>
  String(value || '')
    .toLowerCase()
    .replace(/ё/g, 'е')
    .replace(/[^\p{L}\p{N}]+/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();

const addVisionTerm = (terms, value) => {
  const normalized = normalizeVisionText(value);
  if (!normalized) return;
  terms.add(normalized);
  normalized
    .split(' ')
    .filter((token) => token.length > 2)
    .forEach((token) => terms.add(token));
};

const extractVisionTerms = (visionPayload = {}) => {
  const annotation = Array.isArray(visionPayload.responses)
    ? visionPayload.responses[0] || {}
    : visionPayload;
  const terms = new Set();

  (annotation.labelAnnotations || []).forEach((item) => addVisionTerm(terms, item.description));
  (annotation.localizedObjectAnnotations || []).forEach((item) => addVisionTerm(terms, item.name));

  const webDetection = annotation.webDetection || {};
  (webDetection.webEntities || []).forEach((item) => addVisionTerm(terms, item.description));
  (webDetection.bestGuessLabels || []).forEach((item) => addVisionTerm(terms, item.label));

  addVisionTerm(terms, annotation.detectedObject);
  addVisionTerm(terms, annotation.description);
  addVisionTerm(terms, annotation.productQuery);

  [
    annotation.terms,
    annotation.labels,
    annotation.objects,
    annotation.flowerTypes,
    annotation.colors,
    annotation.productTypes,
  ].forEach((items) => {
    if (!Array.isArray(items)) return;
    items.forEach((item) => addVisionTerm(terms, item));
  });

  (annotation.catalogMatches || []).forEach((item) => {
    addVisionTerm(terms, item?.name);
  });

  return Array.from(terms);
};

const visionSearchGroups = [
  { key: 'rose', terms: ['rose', 'roses', 'роза', 'розы', 'раушан'] },
  { key: 'tulip', terms: ['tulip', 'tulips', 'тюльпан', 'тюльпаны', 'қызғалдақ'] },
  { key: 'peony', terms: ['peony', 'peonies', 'пион', 'пионы'] },
  { key: 'lily', terms: ['lily', 'lilies', 'лилия', 'лилии'] },
  { key: 'hydrangea', terms: ['hydrangea', 'hydrangeas', 'гортензия', 'гортензии'] },
  { key: 'chrysanthemum', terms: ['chrysanthemum', 'chrysanthemums', 'хризантема', 'хризантемы'] },
  { key: 'bouquet', terms: ['bouquet', 'flower bouquet', 'flower arrangement', 'floral arrangement', 'букет'] },
  { key: 'balloon', terms: ['balloon', 'balloons', 'шар', 'шары'] },
  { key: 'fruit', terms: ['fruit', 'fruits', 'food', 'edible', 'фрукт', 'фрукты', 'жеміс'] },
  { key: 'candy', terms: ['candy', 'sweets', 'sweet', 'chocolate', 'конфеты', 'сладости', 'тәтті'] },
  { key: 'bear', terms: ['bear', 'teddy', 'toy', 'мишка', 'медведь', 'аю'] },
  { key: 'money', terms: ['money', 'cash', 'banknote', 'currency', 'деньги', 'ақша'] },
  { key: 'umbrella', terms: ['umbrella', 'зонт', 'қолшатыр'] },
];

const genericVisionTerms = new Set([
  'flower',
  'flowers',
  'floral',
  'floristry',
  'plant',
  'plants',
  'cut flowers',
]);

const expandVisionTerms = (terms) => {
  const normalizedTerms = new Set();
  (terms || []).forEach((term) => addVisionTerm(normalizedTerms, term));
  const expanded = new Set(normalizedTerms);
  const normalizedList = Array.from(normalizedTerms);

  for (const group of visionSearchGroups) {
    const hasGroupMatch = group.terms.some((term) => {
      const normalizedTerm = normalizeVisionText(term);
      return normalizedList.some(
        (value) => value === normalizedTerm || value.includes(normalizedTerm)
      );
    });
    if (hasGroupMatch) {
      expanded.add(group.key);
      group.terms.forEach((term) => addVisionTerm(expanded, term));
    }
  }

  return Array.from(expanded);
};

const scoreProductForVision = (product, terms) => {
  const expandedTerms = expandVisionTerms(terms);
  const name = normalizeVisionText(product?.name);
  const flowerType = normalizeVisionText(product?.flowerType);
  const imagePath = normalizeVisionText(product?.imagePath);
  const imageUrl = normalizeVisionText(product?.imageUrl);
  const occasionTags = Array.isArray(product?.occasionTags)
    ? product.occasionTags.map(normalizeVisionText).join(' ')
    : '';
  const recipientTags = Array.isArray(product?.recipientTags)
    ? product.recipientTags.map(normalizeVisionText).join(' ')
    : '';
  const haystack = `${name} ${flowerType} ${imagePath} ${imageUrl} ${occasionTags} ${recipientTags}`;
  let score = 0;

  for (const term of expandedTerms) {
    if (term.length < 3) continue;
    const isGeneric = genericVisionTerms.has(term);
    if (flowerType && flowerType === term) {
      score += isGeneric ? 2 : 12;
    } else if (flowerType && (flowerType.includes(term) || term.includes(flowerType))) {
      score += isGeneric ? 1 : 8;
    }
    if (name.includes(term)) score += isGeneric ? 1 : 5;
    if (imagePath.includes(term)) score += isGeneric ? 1 : 4;
    if (imageUrl.includes(term)) score += isGeneric ? 0.5 : 2;
    if (occasionTags.includes(term) || recipientTags.includes(term)) score += isGeneric ? 0.5 : 2;
    if (!isGeneric && haystack.includes(term)) score += 1;
  }

  if (score <= 0) return 0;
  if (product?.inStock !== false) score += 0.5;
  if (product?.popular) score += 0.25;
  return score;
};

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
  const hasAnyKeyword = (keywords) =>
    keywords.some((keyword) => {
      if (/^[a-z0-9 ]+$/i.test(keyword)) {
        return new RegExp(`\\b${escapeRegex(keyword)}\\b`, 'i').test(text);
      }
      return text.includes(keyword);
    });
  const flowerKeywords = [
    'гүл',
    'гүлдер',
    'гуль',
    'цвет',
    'цветы',
    'цветок',
    'букет',
    'букеты',
    'раушан',
    'роз',
    'роза',
    'розы',
    'тюльпан',
    'тюльпаны',
    'қызғалдақ',
    'пион',
    'пионы',
    'лилия',
    'лилии',
    'гортенз',
    'хризантем',
    'орхид',
    'кактус',
    'шар',
    'шары',
    'bouquet',
    'flower',
    'flowers',
    'rose',
    'roses',
    'tulip',
    'tulips',
    'peony',
    'peonies',
    'lily',
    'lilies',
    'hydrangea',
    'chrysanthem',
    'succulent',
    'gift',
    'сыйлық',
    'подарок',
    'подарки',
  ];
  if (hasAnyKeyword(flowerKeywords)) return true;

  const offTopicKeywords = [
    'laptop',
    'phone',
    'computer',
    'notebook',
    'car',
    'game',
    'ноутбук',
    'телефон',
    'компьютер',
    'машина',
    'игра',
  ];
  if (hasAnyKeyword(offTopicKeywords)) return false;

  const shopIntentKeywords = [
    'gul alem',
    'shop',
    'store',
    'delivery',
    'deliver',
    'order',
    'buy',
    'price',
    'cost',
    'payment',
    'pay',
    'card',
    'cash',
    'available',
    'stock',
    'catalog',
    'recommend',
    'choose',
    'custom',
    'pickup',
    'address',
    'hours',
    'hello',
    'hi',
    'гул алем',
    'гүл әлем',
    'доставк',
    'жеткіз',
    'заказ',
    'тапсыр',
    'купить',
    'сатып',
    'цен',
    'сколько',
    'қанша',
    'стоит',
    'оплат',
    'төле',
    'карт',
    'налич',
    'бар ма',
    'каталог',
    'посовет',
    'ұсын',
    'подбер',
    'выбрат',
    'таңда',
    'собрат',
    'индивидуал',
    'самовывоз',
    'адрес',
    'режим',
    'график',
    'привет',
    'сәлем',
  ];
  return hasAnyKeyword(shopIntentKeywords);
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
  if (match(['birthday', 'туған', 'туылған', 'день рождения', 'др', 'мереке', 'шар'])) {
    occasion.push('birthday');
  }
  if (match(['wedding', 'үйлен', 'неке', 'қалыңдық', 'свад', 'невест'])) {
    occasion.push('wedding');
  }
  if (match(['love', 'махаббат', 'ғашық', 'роман', 'любим', 'любов'])) {
    occasion.push('love');
  }
  if (match(['құттық', 'congrat', 'құттықтау', 'поздрав'])) {
    occasion.push('congrats');
  }
  if (match(['мама', 'маме', 'маму', 'мамы', 'анама', 'анаға', 'ана', 'mom', 'mother'])) {
    recipient.push('mom');
  }
  if (match(['қыз', 'қызға', 'қызым', 'девуш', 'любимой', 'girl', 'girlfriend', 'қалыңдық'])) {
    recipient.push('girl');
  }
  if (match(['дос', 'досқа', 'друг', 'друга', 'подруг', 'friend'])) {
    recipient.push('friend');
  }
  if (match(['әріптес', 'әріптеске', 'коллег', 'colleague', 'coworker'])) {
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

const validatePasswordPolicy = (password) => {
  const value = String(password || '');
  return (
    value.length >= 8 &&
    value.length <= 64 &&
    /[A-Z]/.test(value) &&
    /[a-z]/.test(value) &&
    /\d/.test(value) &&
    /[^\w\s]/.test(value) &&
    !/\s/.test(value)
  );
};

module.exports = {
  getPaymentKey,
  encryptField,
  decryptField,
  hashToken,
  normalizeFullName,
  normalizeEmail,
  normalizePhone,
  validateFullName,
  validateEmail,
  validatePhone,
  normalizePaymentExpiry,
  normalizeTagList,
  dedupeTags,
  escapeRegex,
  extractVisionTerms,
  expandVisionTerms,
  scoreProductForVision,
  stripMarkdown,
  isFlowerTopic,
  buildChatTitle,
  mapTagMatches,
  buildAutoTags,
  resolveProductTags,
  validatePasswordPolicy,
};
