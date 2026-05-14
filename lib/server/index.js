const express = require('express');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '.env') });
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const crypto = require('crypto');
const nodemailer = require('nodemailer');
const multer = require('multer');
const { v2: cloudinary } = require('cloudinary');
const {
  getPaymentKey: getPaymentKeyFromEnv,
  encryptField: encryptFieldWithKey,
  decryptField: decryptFieldWithKey,
  hashToken,
  normalizeTagList,
  escapeRegex,
  stripMarkdown,
  isFlowerTopic,
  buildChatTitle,
  mapTagMatches,
  resolveProductTags,
  extractVisionTerms,
  expandVisionTerms,
  scoreProductForVision,
} = require('./utils');

const app = express();
app.use(express.json({ limit: '8mb' }));
app.use(cors());
app.use((req, res, next) => {
  const queryIndex = req.url.indexOf('?');
  const pathPart = queryIndex === -1 ? req.url : req.url.slice(0, queryIndex);
  const queryPart = queryIndex === -1 ? '' : req.url.slice(queryIndex);
  const normalizedPath = pathPart.replace(/\/{2,}/g, '/');
  req.url = `${normalizedPath}${queryPart}`;
  next();
});

const PORT = process.env.PORT || 3000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/gul_alem_db';
const IS_PRODUCTION = process.env.NODE_ENV === 'production';
const requiredInProduction = (name, fallback = '') => {
  const value = String(process.env[name] || '').trim();
  if (IS_PRODUCTION && !value) {
    throw new Error(`${name} is required in production`);
  }
  return value || fallback;
};
const JWT_SECRET = requiredInProduction('JWT_SECRET', 'gul-alem-dev-secret');
const SUPER_ADMIN_EMAIL = requiredInProduction('SUPER_ADMIN_EMAIL', '').toLowerCase();
const PAYMENT_ENC_KEY = requiredInProduction('PAYMENT_ENC_KEY', '');
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';
const GEMINI_MODEL = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
const GMAIL_SERVICE = process.env.GMAIL_SERVICE || 'gmail';
const GMAIL_USER = process.env.GMAIL_USER || '';
const GMAIL_APP_PASSWORD = process.env.GMAIL_APP_PASSWORD || '';
const GMAIL_FROM = process.env.GMAIL_FROM || GMAIL_USER;
const RESET_CODE_TTL_MIN = Number.parseInt(process.env.RESET_CODE_TTL_MIN || '10', 10);
const RESET_TOKEN_TTL_MIN = Number.parseInt(process.env.RESET_TOKEN_TTL_MIN || '30', 10);
const CLOUDINARY_CLOUD_NAME = process.env.CLOUDINARY_CLOUD_NAME || '';
const CLOUDINARY_API_KEY = process.env.CLOUDINARY_API_KEY || '';
const CLOUDINARY_API_SECRET = process.env.CLOUDINARY_API_SECRET || '';
const MAX_CUSTOM_FLOWERS = 100;
const MAX_GEMINI_CATALOG_IMAGES = 16;
const GEMINI_CATALOG_IMAGE_TIMEOUT_MS = 3500;
const GEMINI_CATALOG_IMAGE_MAX_BYTES = 2 * 1024 * 1024;
const ORDER_STATUSES = ['pending', 'processing', 'completed', 'cancelled'];
const CHAT_RETENTION_DAYS = Math.min(
  Math.max(Number.parseInt(process.env.CHAT_RETENTION_DAYS || '14', 10), 1),
  365
);
const CHAT_RETENTION_SECONDS = CHAT_RETENTION_DAYS * 24 * 60 * 60;
const CHAT_CONTEXT_MESSAGES = Math.min(
  Math.max(Number.parseInt(process.env.CHAT_CONTEXT_MESSAGES || '6', 10), 2),
  12
);
const CHAT_MAX_STORED_MESSAGES = Math.min(
  Math.max(Number.parseInt(process.env.CHAT_MAX_STORED_MESSAGES || '20', 10), 4),
  80
);
const CHAT_MAX_MESSAGE_CHARS = Math.min(
  Math.max(Number.parseInt(process.env.CHAT_MAX_MESSAGE_CHARS || '1200', 10), 200),
  4000
);

cloudinary.config({
  cloud_name: CLOUDINARY_CLOUD_NAME,
  api_key: CLOUDINARY_API_KEY,
  api_secret: CLOUDINARY_API_SECRET,
});

const imageUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 8 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (file.mimetype && file.mimetype.startsWith('image/')) {
      cb(null, true);
      return;
    }
    cb(new Error('Only image files are allowed'));
  },
});

mongoose
  .connect(MONGO_URI)
  .then(() => console.log('MongoDB connected'))
  .catch((err) => console.error('MongoDB connection error:', err));

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    phone: { type: String, required: true, unique: true },
    email: { type: String, required: true, unique: true, lowercase: true },
    role: { type: String, enum: ['user', 'worker', 'admin', 'super_admin'], default: 'user' },
    passwordHash: { type: String, required: true },
    resetCodeHash: { type: String, default: null },
    resetCodeExpiresAt: { type: Date, default: null },
    resetTokenHash: { type: String, default: null },
    resetTokenExpiresAt: { type: Date, default: null },
  },
  { timestamps: true }
);

const adminEmailSchema = new mongoose.Schema(
  {
    email: { type: String, required: true, unique: true, lowercase: true },
    role: { type: String, enum: ['worker', 'admin'], default: 'admin' },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  },
  { timestamps: true }
);

const categorySchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    imagePath: { type: String, required: true },
    order: { type: Number, default: 0 },
  },
  { timestamps: true }
);

const productSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    price: { type: Number, required: true },
    imagePath: { type: String, default: '' },
    imageUrl: { type: String, default: '' },
    flowerType: { type: String, required: true },
    category: { type: mongoose.Schema.Types.ObjectId, ref: 'Category' },
    inStock: { type: Boolean, default: true },
    stockCount: { type: Number, default: 0 },
    popular: { type: Boolean, default: false },
    occasionTags: { type: [String], default: [] },
    recipientTags: { type: [String], default: [] },
  },
  { timestamps: true }
);

const customBouquetItemSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    group: { type: String, required: true, default: 'extras' },
    price: { type: Number, required: true, default: 0 },
    stockCount: { type: Number, default: 0 },
    inStock: { type: Boolean, default: true },
    order: { type: Number, default: 0 },
    imagePath: { type: String, default: '' },
    imageUrl: { type: String, default: '' },
  },
  { timestamps: true }
);

const orderSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    orderType: {
      type: String,
      enum: ['standard', 'custom'],
      default: 'standard',
    },
    description: { type: String, default: '' },
    items: [
      {
        productId: { type: mongoose.Schema.Types.ObjectId, ref: 'Product' },
        name: String,
        imagePath: String,
        imageUrl: String,
        price: Number,
        quantity: Number,
      },
    ],
    customItems: [
      {
        customItemId: { type: mongoose.Schema.Types.ObjectId, ref: 'CustomBouquetItem' },
        name: String,
        group: String,
        imagePath: String,
        imageUrl: String,
        price: Number,
        quantity: Number,
      },
    ],
    subtotal: { type: Number, default: 0 },
    deliveryMethod: {
      type: String,
      enum: ['pickup', 'courier'],
      default: 'pickup',
    },
    deliveryPrice: { type: Number, default: 0 },
    pickupStore: {
      id: String,
      name: String,
      address: String,
      latitude: Number,
      longitude: Number,
    },
    deliveryAddress: { type: String, default: null },
    total: { type: Number, default: 0 },
    status: {
      type: String,
      enum: ORDER_STATUSES,
      default: 'pending',
    },
  },
  { timestamps: true }
);

const encryptedFieldSchema = new mongoose.Schema(
  {
    iv: { type: String, required: true },
    tag: { type: String, required: true },
    data: { type: String, required: true },
  },
  { _id: false }
);

const paymentMethodSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    cardholderName: { type: encryptedFieldSchema, required: true },
    paymentToken: { type: encryptedFieldSchema, required: true },
    cardNumber: { type: encryptedFieldSchema, select: false },
    last4: { type: String, required: true },
    brand: { type: String, default: '' },
    expMonth: { type: encryptedFieldSchema, required: true },
    expYear: { type: encryptedFieldSchema, required: true },
    cvv: { type: encryptedFieldSchema, select: false },
  },
  { timestamps: true }
);

const favoriteSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    product: { type: mongoose.Schema.Types.ObjectId, ref: 'Product', required: true },
  },
  { timestamps: true }
);
favoriteSchema.index({ user: 1, product: 1 }, { unique: true });

const cartItemSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    itemType: {
      type: String,
      enum: ['product', 'custom'],
      default: 'product',
    },
    product: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Product',
      required() {
        return this.itemType === 'product';
      },
    },
    quantity: { type: Number, default: 1 },
    description: { type: String, default: '' },
    customTotal: { type: Number, default: 0 },
    imagePath: { type: String, default: '' },
    imageUrl: { type: String, default: '' },
    customItems: [
      {
        customItemId: { type: mongoose.Schema.Types.ObjectId, ref: 'CustomBouquetItem' },
        name: String,
        group: String,
        imagePath: String,
        imageUrl: String,
        price: Number,
        quantity: Number,
      },
    ],
  },
  { timestamps: true }
);
cartItemSchema.index({ user: 1, product: 1 }, { unique: true });

const notificationSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    title: { type: String, required: true },
    message: { type: String, default: '' },
    type: { type: String, default: 'system' },
    read: { type: Boolean, default: false },
  },
  { timestamps: true }
);

const chatSessionSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    title: { type: String, default: 'Жаңа чат' },
    lastMessageAt: { type: Date, default: Date.now },
    lastMessagePreview: { type: String, default: '' },
  },
  { timestamps: true }
);
chatSessionSchema.index({ updatedAt: 1 }, { expireAfterSeconds: CHAT_RETENTION_SECONDS });

const chatMessageSchema = new mongoose.Schema(
  {
    session: { type: mongoose.Schema.Types.ObjectId, ref: 'ChatSession', required: true },
    role: { type: String, enum: ['user', 'assistant'], required: true },
    message: { type: String, required: true, maxlength: CHAT_MAX_MESSAGE_CHARS },
    productSuggestions: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Product' }],
  },
  { timestamps: true }
);
chatMessageSchema.index({ createdAt: 1 }, { expireAfterSeconds: CHAT_RETENTION_SECONDS });

const User = mongoose.model('User', userSchema);
const AdminEmail = mongoose.model('AdminEmail', adminEmailSchema);
const Category = mongoose.model('Category', categorySchema);
const Product = mongoose.model('Product', productSchema);
const CustomBouquetItem = mongoose.model('CustomBouquetItem', customBouquetItemSchema);
const Order = mongoose.model('Order', orderSchema);
const PaymentMethod = mongoose.model('PaymentMethod', paymentMethodSchema);
const Favorite = mongoose.model('Favorite', favoriteSchema);
const CartItem = mongoose.model('CartItem', cartItemSchema);
const Notification = mongoose.model('Notification', notificationSchema);
const ChatSession = mongoose.model('ChatSession', chatSessionSchema);
const ChatMessage = mongoose.model('ChatMessage', chatMessageSchema);

const getPaymentKey = () => getPaymentKeyFromEnv(PAYMENT_ENC_KEY);

const encryptField = (value) => encryptFieldWithKey(value, PAYMENT_ENC_KEY);

const decryptField = (payload) => decryptFieldWithKey(payload, PAYMENT_ENC_KEY);

const getRoleForEmail = async (email) => {
  if (!email) return 'user';
  const lower = email.toLowerCase();
  if (SUPER_ADMIN_EMAIL && lower === SUPER_ADMIN_EMAIL) return 'super_admin';
  const admin = await AdminEmail.findOne({ email: lower });
  return admin ? admin.role || 'admin' : 'user';
};

const authRequired = async (req, res, next) => {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ message: 'Unauthorized' });
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    const user = await User.findById(payload.userId).select('_id name email role');
    if (!user) return res.status(401).json({ message: 'Invalid token' });

    const role = await getRoleForEmail(user.email);
    if (user.role !== role) {
      user.role = role;
      await user.save();
    }
    req.user = {
      userId: String(user._id),
      email: user.email,
      role,
      name: user.name,
    };
    return next();
  } catch (err) {
    return res.status(401).json({ message: 'Invalid token' });
  }
};

const requireRole = (...roles) => (req, res, next) => {
  if (!req.user || !roles.includes(req.user.role)) {
    return res.status(403).json({ message: 'Forbidden' });
  }
  return next();
};

const hasCloudinaryConfig = () =>
  Boolean(CLOUDINARY_CLOUD_NAME && CLOUDINARY_API_KEY && CLOUDINARY_API_SECRET);

const isExternalImageUrl = (value) => /^https?:\/\//i.test(String(value || ''));

const getProductDisplayImageUrl = (product) => {
  const imageUrl = String(product?.imageUrl || '').trim();
  if (isExternalImageUrl(imageUrl)) return imageUrl;
  const imagePath = String(product?.imagePath || '').trim();
  return isExternalImageUrl(imagePath) ? imagePath : '';
};

const isCloudinaryImageUrl = (value) => {
  try {
    const url = new URL(String(value || ''));
    if (!['http:', 'https:'].includes(url.protocol)) return false;
    if (url.hostname.toLowerCase() !== 'res.cloudinary.com') return false;
    const parts = url.pathname.split('/').filter(Boolean);
    if (parts.length < 4 || parts[1] !== 'image' || parts[2] !== 'upload') return false;
    if (CLOUDINARY_CLOUD_NAME && parts[0] !== CLOUDINARY_CLOUD_NAME) return false;
    return true;
  } catch (_) {
    return false;
  }
};

const getCloudinaryVisionUrl = (value) => {
  try {
    const url = new URL(String(value || ''));
    const marker = '/image/upload/';
    const markerIndex = url.pathname.indexOf(marker);
    if (markerIndex === -1) return String(value || '');
    const prefix = url.pathname.slice(0, markerIndex + marker.length);
    const suffix = url.pathname.slice(markerIndex + marker.length);
    url.pathname = `${prefix}f_jpg,q_auto:good,w_512,h_512,c_limit/${suffix}`;
    return url.toString();
  } catch (_) {
    return String(value || '');
  }
};

const uploadFolders = new Set(['products', 'custom-bouquet']);

const getCloudinaryUploadFolder = (value) => {
  const folder = String(value || 'products').trim();
  return `gul-alem/${uploadFolders.has(folder) ? folder : 'products'}`;
};

const uploadImageBufferToCloudinary = (file, folder) =>
  new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      {
        folder: getCloudinaryUploadFolder(folder),
        resource_type: 'image',
      },
      (error, result) => {
        if (error) {
          reject(error);
          return;
        }
        resolve(result);
      }
    );
    stream.end(file.buffer);
  });

const toProductResponse = (product) => ({
  id: product._id,
  name: product.name,
  price: product.price,
  imagePath: product.imagePath,
  imageUrl: getProductDisplayImageUrl(product),
  flowerType: product.flowerType,
  categoryId: product.category,
  inStock: product.inStock,
  stockCount: product.stockCount,
  popular: product.popular,
  occasionTags: product.occasionTags || [],
  recipientTags: product.recipientTags || [],
});

const customCartProductResponse = (item) => {
  const customItems = item.customItems || [];
  const firstImageItem = customItems.find((customItem) =>
    String(customItem.imageUrl || customItem.imagePath || '').trim()
  );
  const imagePath =
    item.imagePath ||
    firstImageItem?.imagePath ||
    firstImageItem?.imageUrl ||
    'assets/cat_10.png';
  const imageUrl = item.imageUrl || (isExternalImageUrl(imagePath) ? imagePath : '');

  return {
    id: item._id,
    name: 'Custom bouquet',
    price: item.customTotal || 0,
    imagePath,
    imageUrl,
    flowerType: 'custom',
    categoryId: null,
    inStock: true,
    stockCount: Math.max(Number(item.quantity) || 1, 1),
    popular: false,
    occasionTags: [],
    recipientTags: [],
  };
};

const toCartItemResponse = (item) => {
  if (item.itemType === 'custom') {
    return {
      id: item._id,
      itemType: 'custom',
      product: customCartProductResponse(item),
      quantity: item.quantity,
      description: item.description || '',
      customItems: (item.customItems || []).map((customItem) => ({
        customItemId: customItem.customItemId,
        name: customItem.name,
        group: customItem.group,
        imagePath: customItem.imagePath,
        imageUrl: customItem.imageUrl,
        price: customItem.price,
        quantity: customItem.quantity,
      })),
    };
  }

  return {
    id: item.product?._id,
    itemType: 'product',
    product: toProductResponse(item.product),
    quantity: item.quantity,
  };
};

const toCategoryResponse = (category) => ({
  id: category._id,
  name: category.name,
  imagePath: category.imagePath,
  order: category.order,
});

const toCustomBouquetItemResponse = (item) => ({
  id: item._id,
  name: item.name,
  group: item.group,
  price: item.price,
  stockCount: item.stockCount,
  inStock: item.inStock,
  order: item.order,
  imagePath: item.imagePath || item.imageUrl || '',
  imageUrl: item.imageUrl || (isExternalImageUrl(item.imagePath) ? item.imagePath : ''),
});

const createToken = (userId, email, role) =>
  jwt.sign({ userId, email, role }, JWT_SECRET, { expiresIn: '7d' });

const getMailTransporter = () => {
  if (!GMAIL_USER || !GMAIL_APP_PASSWORD) {
    throw new Error('GMAIL_USER or GMAIL_APP_PASSWORD missing');
  }
  return nodemailer.createTransport({
    service: GMAIL_SERVICE,
    auth: {
      user: GMAIL_USER,
      pass: GMAIL_APP_PASSWORD,
    },
  });
};

const sendResetCodeEmail = async ({ email, code }) => {
  const transporter = getMailTransporter();
  await transporter.sendMail({
    from: GMAIL_FROM,
    to: email,
    subject: 'Password reset code',
    text: `Your password reset code is ${code}. It expires in ${RESET_CODE_TTL_MIN} minutes.`,
  });
};

const fetchGeminiModels = async (apiKey) => {
  if (typeof fetch !== 'function') {
    return { models: [], error: 'Fetch is not available in this Node.js runtime.' };
  }
  const endpoint = `https://generativelanguage.googleapis.com/v1beta/models?key=${apiKey}`;
  const response = await fetch(endpoint);
  if (!response.ok) {
    return { models: [], error: `ListModels failed (${response.status})` };
  }
  const data = await response.json();
  const models = Array.isArray(data?.models)
    ? data.models.map((model) => ({
        name: model.name,
        supportedMethods: model.supportedMethods || [],
      }))
    : [];
  return { models, error: null };
};

const normalizeImageBase64 = (value) =>
  String(value || '')
    .replace(/^data:image\/[a-zA-Z0-9.+-]+;base64,/, '')
    .replace(/\s/g, '');

const getImageMimeType = (rawValue, imageBase64) => {
  const dataUriMatch = String(rawValue || '').match(/^data:(image\/[a-zA-Z0-9.+-]+);base64,/);
  if (dataUriMatch) return dataUriMatch[1];
  if (imageBase64.startsWith('/9j/')) return 'image/jpeg';
  if (imageBase64.startsWith('iVBOR')) return 'image/png';
  if (imageBase64.startsWith('UklGR')) return 'image/webp';
  return 'image/jpeg';
};

const parseGeminiJson = (value) => {
  const text = String(value || '')
    .replace(/```json/gi, '')
    .replace(/```/g, '')
    .trim();
  if (!text) return {};
  try {
    return JSON.parse(text);
  } catch (_) {
    const start = text.indexOf('{');
    const end = text.lastIndexOf('}');
    if (start >= 0 && end > start) {
      try {
        return JSON.parse(text.slice(start, end + 1));
      } catch (_) {}
    }
  }
  return { description: text, terms: [text] };
};

const normalizeVisionValue = (value) =>
  String(value || '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();

const visionFamilyGroups = {
  rose: ['rose', 'roses', 'red rose', 'white rose'],
  tulip: ['tulip', 'tulips'],
  peony: ['peony', 'peonies'],
  lily: ['lily', 'lilies'],
  hydrangea: ['hydrangea', 'hydrangeas'],
  chrysanthemum: ['chrysanthemum', 'chrysanthemums', 'daisy'],
  mixed: ['mixed', 'assorted', 'mixed bouquet'],
  balloon: ['balloon', 'balloons', 'birthday balloons'],
  fruit: ['fruit', 'fruits', 'edible fruit'],
  candy: ['candy', 'sweets', 'sweet bouquet', 'chocolate'],
  bear: ['bear', 'teddy', 'toy'],
  money: ['money', 'cash', 'banknote', 'currency'],
  umbrella: ['umbrella'],
};

const visionColorTerms = ['red', 'white', 'pink', 'yellow', 'green', 'blue', 'purple', 'mixed'];

const addKeyword = (keywords, value) => {
  const normalized = normalizeVisionValue(value);
  if (!normalized) return;
  keywords.add(normalized);
  normalized
    .split(' ')
    .filter((token) => token.length > 2)
    .forEach((token) => keywords.add(token));
};

const getProductVisionKeywords = (product) => {
  const keywords = new Set();
  addKeyword(keywords, product?.name);
  addKeyword(keywords, product?.flowerType);
  addKeyword(keywords, product?.imagePath);
  addKeyword(keywords, product?.imageUrl);
  (product?.occasionTags || []).forEach((tag) => addKeyword(keywords, tag));
  (product?.recipientTags || []).forEach((tag) => addKeyword(keywords, tag));

  const haystack = Array.from(keywords).join(' ');
  Object.entries(visionFamilyGroups).forEach(([family, terms]) => {
    if (terms.some((term) => haystack.includes(term))) {
      addKeyword(keywords, family);
      terms.forEach((term) => addKeyword(keywords, term));
    }
  });
  visionColorTerms.forEach((color) => {
    if (haystack.includes(color)) addKeyword(keywords, color);
  });
  return Array.from(keywords);
};

const getProductVisionFamilySet = (product) => {
  const keywords = new Set(getProductVisionKeywords(product));
  return new Set(
    Object.keys(visionFamilyGroups).filter((family) =>
      visionFamilyGroups[family].some((term) => keywords.has(family) || keywords.has(term))
    )
  );
};

const sortProductsForCatalogImages = (left, right) => {
  const leftInStock = left?.inStock !== false;
  const rightInStock = right?.inStock !== false;
  if (leftInStock !== rightInStock) return leftInStock ? -1 : 1;
  if (Boolean(left?.popular) !== Boolean(right?.popular)) return left?.popular ? -1 : 1;
  const leftTime = left?.createdAt ? new Date(left.createdAt).getTime() : 0;
  const rightTime = right?.createdAt ? new Date(right.createdAt).getTime() : 0;
  return rightTime - leftTime;
};

const getCatalogImageCandidates = (products, limit = MAX_GEMINI_CATALOG_IMAGES) =>
  products
    .filter((product) => isCloudinaryImageUrl(getProductDisplayImageUrl(product)))
    .sort(sortProductsForCatalogImages)
    .slice(0, limit)
    .map((product, index) => ({
      id: String(product._id),
      visualRef: `catalog_image_${index + 1}`,
      product,
      imageUrl: getCloudinaryVisionUrl(getProductDisplayImageUrl(product)),
    }));

const fetchCatalogImageInlineData = async (imageUrl) => {
  if (typeof fetch !== 'function') return null;
  const controller = typeof AbortController === 'function' ? new AbortController() : null;
  const timeout = controller
    ? setTimeout(() => controller.abort(), GEMINI_CATALOG_IMAGE_TIMEOUT_MS)
    : null;
  try {
    const response = await fetch(imageUrl, {
      ...(controller ? { signal: controller.signal } : {}),
      headers: { Accept: 'image/jpeg,image/png,image/webp,image/*' },
    });
    if (!response.ok) return null;
    const rawContentType = response.headers.get('content-type') || '';
    const mimeType = rawContentType.split(';')[0].trim().toLowerCase();
    if (!mimeType.startsWith('image/')) return null;
    const contentLength = Number.parseInt(response.headers.get('content-length') || '0', 10);
    if (Number.isFinite(contentLength) && contentLength > GEMINI_CATALOG_IMAGE_MAX_BYTES) {
      return null;
    }
    const buffer = Buffer.from(await response.arrayBuffer());
    if (buffer.length > GEMINI_CATALOG_IMAGE_MAX_BYTES) return null;
    return {
      data: buffer.toString('base64'),
      mimeType,
    };
  } catch (_) {
    return null;
  } finally {
    if (timeout) clearTimeout(timeout);
  }
};

const buildCatalogImagePromptParts = async (candidates) => {
  const loaded = await Promise.all(
    candidates.map(async (candidate) => {
      const inlineData = await fetchCatalogImageInlineData(candidate.imageUrl);
      if (!inlineData) return null;
      return { ...candidate, inlineData };
    })
  );

  const catalogImages = loaded.filter(Boolean);
  return {
    catalogImages,
    parts: catalogImages.flatMap((entry) => [
      {
        text: `Catalog image ${entry.visualRef}: id=${entry.id}; name=${entry.product.name}; flowerType=${entry.product.flowerType}.`,
      },
      { inlineData: entry.inlineData },
    ]),
  };
};

const buildVisionCatalog = (products, catalogImages = []) => {
  const visualRefById = new Map(catalogImages.map((entry) => [entry.id, entry.visualRef]));
  const selectedProducts = products.slice(0, 80);
  const selectedIds = new Set(selectedProducts.map((product) => String(product._id)));
  catalogImages.forEach((entry) => {
    if (entry?.product && !selectedIds.has(entry.id)) {
      selectedIds.add(entry.id);
      selectedProducts.push(entry.product);
    }
  });
  return selectedProducts.map((product) => {
    const id = String(product._id);
    const visualRef = visualRefById.get(id);
    return {
      id,
      name: product.name,
      flowerType: product.flowerType,
      imagePath: product.imagePath,
      imageUrl: getProductDisplayImageUrl(product),
      ...(visualRef ? { visualRef } : {}),
      keywords: getProductVisionKeywords(product).slice(0, 24),
      inStock: product.inStock,
      popular: product.popular,
      occasionTags: product.occasionTags || [],
      recipientTags: product.recipientTags || [],
    };
  });
};

const analyzeImageWithGemini = async ({ imageBase64, mimeType, products }) => {
  if (!GEMINI_API_KEY) {
    const error = new Error('Gemini key missing');
    error.status = 500;
    throw error;
  }

  const catalogImageCandidates = getCatalogImageCandidates(products);
  const { catalogImages, parts: catalogImageParts } = await buildCatalogImagePromptParts(
    catalogImageCandidates
  );
  const catalog = buildVisionCatalog(products, catalogImages);
  const prompt = [
    'You are a visual product search engine for the Gul alem flower shop catalog.',
    'Analyze only the main purchasable object in the image. Ignore background, hands, people, table, vase, room, lighting, and camera style.',
    'Identify the most specific visible flower or gift family, dominant colors, arrangement style, and product type.',
    'Prefer specific families over generic words: rose, tulip, peony, lily, hydrangea, chrysanthemum, mixed, balloon, fruit, candy, bear, money, umbrella.',
    'Then choose similar products from the provided catalog. Use only exact catalog ids and order by visual similarity.',
    catalogImages.length > 0
      ? 'Some catalog products include attached Cloudinary images labelled by visualRef. Compare the customer image against these catalog images directly and prefer direct visual similarity over filename or metadata matches.'
      : 'No catalog images are attached, so rely on detected object details and catalog metadata.',
    'Only include catalogMatches when the catalog product is visually close. Do not add weak generic bouquet matches just to fill the list.',
    'Use confidence from 0 to 1. Set lower confidence for uncertain matches. If the photo is unclear, return fewer catalogMatches.',
    'Return only JSON with this shape:',
    '{"detectedObject":"short phrase","description":"short phrase","productQuery":"search phrase","terms":["english keywords"],"flowerTypes":["rose"],"colors":["red"],"productTypes":["bouquet"],"catalogMatches":[{"id":"catalog id","confidence":0.0,"reason":"short reason"}]}',
    'The terms must be concrete English keywords, not vague labels. Avoid generic terms like flower, plant, bouquet unless a specific family is also present.',
    'When catalog images are attached, use visualRef to connect each attached image to its catalog id. Never invent ids.',
    'Pick 3 to 8 catalogMatches when possible, but precision is more important than count.',
    `Catalog: ${JSON.stringify(catalog)}`,
  ].join('\n');

  const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
  const model = genAI.getGenerativeModel({
    model: GEMINI_MODEL,
    generationConfig: {
      temperature: 0.1,
      responseMimeType: 'application/json',
    },
  });
  const result = await model.generateContent([
    { text: prompt },
    { text: 'Customer search image:' },
    { inlineData: { data: imageBase64, mimeType } },
    ...catalogImageParts,
  ]);
  const rawText = result?.response?.text() || '';
  const analysis = parseGeminiJson(rawText);
  return {
    ...analysis,
    rawText,
  };
};

const getCatalogMatchScores = (analysis) => {
  const scores = new Map();
  const matches = Array.isArray(analysis?.catalogMatches) ? analysis.catalogMatches : [];
  matches.forEach((match, index) => {
    const id = String(match?.id || '').trim();
    if (!id) return;
    const confidence = Number(match?.confidence);
    const normalizedConfidence = Number.isFinite(confidence)
      ? Math.min(Math.max(confidence, 0), 1)
      : 0.55;
    if (normalizedConfidence < 0.35) return;
    const confidenceScore = normalizedConfidence * 18;
    scores.set(id, Math.max(scores.get(id) || 0, 26 - index * 2 + confidenceScore));
  });
  return scores;
};

const getSpecificVisionFamilies = (terms) => {
  const expandedTerms = new Set(expandVisionTerms(terms).map(normalizeVisionValue));
  return new Set(
    Object.keys(visionFamilyGroups).filter((family) =>
      visionFamilyGroups[family].some((term) => expandedTerms.has(family) || expandedTerms.has(term))
    )
  );
};

const getDetectedColors = (terms) => {
  const expandedTerms = new Set(expandVisionTerms(terms).map(normalizeVisionValue));
  return new Set(visionColorTerms.filter((color) => expandedTerms.has(color)));
};

const setsIntersect = (left, right) => {
  for (const value of left) {
    if (right.has(value)) return true;
  }
  return false;
};

const productHasAnyKeyword = (product, values) => {
  const keywords = new Set(getProductVisionKeywords(product));
  for (const value of values) {
    if (keywords.has(value)) return true;
  }
  return false;
};

const areProductsVisuallyRelated = (left, right) => {
  const leftFamilies = getProductVisionFamilySet(left);
  const rightFamilies = getProductVisionFamilySet(right);
  if (setsIntersect(leftFamilies, rightFamilies)) return true;

  const edible = new Set(['fruit', 'candy']);
  if (setsIntersect(leftFamilies, edible) && setsIntersect(rightFamilies, edible)) return true;

  const gift = new Set(['money', 'bear']);
  if (setsIntersect(leftFamilies, gift) && setsIntersect(rightFamilies, gift)) return true;

  const leftType = normalizeVisionValue(left?.flowerType);
  const rightType = normalizeVisionValue(right?.flowerType);
  return leftType && leftType !== 'bouquet' && leftType === rightType;
};

const rankProductsForVisionAnalysis = (products, analysis, limit = 12) => {
  const terms = extractVisionTerms(analysis);
  const catalogMatchScores = getCatalogMatchScores(analysis);
  const specificFamilies = getSpecificVisionFamilies(terms);
  const detectedColors = getDetectedColors(terms);
  const scored = products
    .map((product) => {
      const id = String(product._id);
      const catalogScore = catalogMatchScores.get(id) || 0;
      const productFamilies = getProductVisionFamilySet(product);
      const familyMatch = specificFamilies.size > 0 && setsIntersect(productFamilies, specificFamilies);
      const colorMatch = detectedColors.size > 0 && productHasAnyKeyword(product, detectedColors);
      let score = scoreProductForVision(product, terms) + catalogScore;
      if (familyMatch) score += 10;
      if (colorMatch) score += 4;
      if (specificFamilies.size > 0 && !familyMatch && catalogScore < 26) {
        score *= 0.25;
      }
      return { product, score, catalogScore, familyMatch };
    })
    .filter((item) => item.score > 0)
    .sort((a, b) => {
      if (b.score !== a.score) return b.score - a.score;
      if (a.product.inStock !== b.product.inStock) return a.product.inStock ? -1 : 1;
      return Number(b.product.popular) - Number(a.product.popular);
    });
  const topScore = scored[0]?.score || 0;
  const minScore = Math.max(7, topScore * 0.38);
  const preciseScored = scored.filter(
    (item) => item.score >= minScore || item.catalogScore >= 30 || item.familyMatch
  );

  const ranked = [];
  const seen = new Set();
  for (const item of preciseScored) {
    const id = String(item.product._id);
    if (seen.has(id)) continue;
    seen.add(id);
    ranked.push(item.product);
    if (ranked.length >= limit) break;
  }

  if (ranked.length > 0 && ranked.length < limit) {
    const top = ranked[0];
    const related = products
      .filter((product) => {
        if (seen.has(String(product._id))) return false;
        if (areProductsVisuallyRelated(top, product)) return true;
        return specificFamilies.size === 0 && String(product.category || '') === String(top.category || '');
      })
      .sort((a, b) => {
        if (a.inStock !== b.inStock) return a.inStock ? -1 : 1;
        return Number(b.popular) - Number(a.popular);
      });
    for (const product of related) {
      seen.add(String(product._id));
      ranked.push(product);
      if (ranked.length >= limit) break;
    }
  }

  return {
    terms,
    products: ranked.slice(0, limit).map(toProductResponse),
  };
};

const classifyFlowerShopRequestWithGemini = async ({ message, genAI }) => {
  const model = genAI.getGenerativeModel({
    model: GEMINI_MODEL,
    generationConfig: {
      temperature: 0,
      responseMimeType: 'application/json',
    },
  });
  const prompt = [
    'Classify whether a user message should be answered by a flower shop assistant for Gul alem.',
    'Allow messages about flowers, bouquets, gifts sold by a flower shop, recommendations, occasions, recipients, delivery, pickup, orders, payment, prices, availability, catalog, custom bouquets, store address, and store hours.',
    'Allow short greetings, thanks, and follow-up messages if they can naturally belong to a flower shop chat.',
    'Reject messages that are clearly unrelated, including technology, schoolwork, programming, politics, medicine, legal advice, entertainment, general trivia, and unrelated shopping.',
    'Return only JSON in this exact shape: {"allowed":true,"reason":"short reason"}',
    `User message: ${String(message || '').slice(0, 600)}`,
  ].join('\n');

  try {
    const result = await model.generateContent(prompt);
    const rawText = result?.response?.text() || '';
    const parsed = parseGeminiJson(rawText);
    return parsed?.allowed === true;
  } catch (error) {
    console.warn('Gemini topic classification failed:', error?.message || error);
    return false;
  }
};

const shouldAnswerFlowerShopRequest = async ({ message, genAI }) => {
  if (isFlowerTopic(message)) return true;
  return classifyFlowerShopRequestWithGemini({ message, genAI });
};


const buildProductSuggestions = async (message, limit = 5) => {
  const text = String(message || '').toLowerCase();
  const tokens = text
    .split(/[\s\-,.!?;:(){}\[\]]+/)
    .map((token) => token.trim())
    .filter(Boolean);
  const tagMatches = mapTagMatches(text);
  const orFilters = [];
  if (tokens.length > 0) {
    const regex = new RegExp(tokens.slice(0, 6).map(escapeRegex).join('|'), 'i');
    orFilters.push({ name: regex }, { flowerType: regex });
  }
  if (tagMatches.occasion.length > 0) {
    orFilters.push({ occasionTags: { $in: tagMatches.occasion } });
  }
  if (tagMatches.recipient.length > 0) {
    orFilters.push({ recipientTags: { $in: tagMatches.recipient } });
  }
  if (orFilters.length === 0) return [];
  const products = await Product.find({ $or: orFilters, inStock: true }).limit(limit);
  return products.map(toProductResponse);
};

const clampRecommendationLimit = (value) => {
  const parsed = Number.parseInt(value || '8', 10);
  if (!Number.isFinite(parsed)) return 8;
  return Math.min(Math.max(parsed, 1), 20);
};

const addRecommendationSignal = ({ product, weight, signals, seenProductIds }) => {
  if (!product) return;
  const productId = String(product._id || product.id || '');
  if (productId) seenProductIds.add(productId);

  const categoryId = product.category ? String(product.category._id || product.category) : '';
  if (categoryId) {
    signals.categories.set(categoryId, (signals.categories.get(categoryId) || 0) + weight);
  }

  const flowerType = String(product.flowerType || '').trim().toLowerCase();
  if (flowerType) {
    signals.flowerTypes.set(flowerType, (signals.flowerTypes.get(flowerType) || 0) + weight);
  }
};

const getFallbackRecommendations = async (limit, excludedIds = new Set()) => {
  const products = await Product.find({ inStock: true }).sort({
    popular: -1,
    createdAt: -1,
  });
  const result = [];
  for (const product of products) {
    if (excludedIds.has(String(product._id))) continue;
    result.push(product);
    if (result.length >= limit) break;
  }
  return result;
};

const buildRecommendationsForUser = async (userId, limit = 8) => {
  const [favorites, cartItems, orders] = await Promise.all([
    Favorite.find({ user: userId }).sort({ createdAt: -1 }).limit(40).populate('product'),
    CartItem.find({ user: userId }).sort({ updatedAt: -1 }).limit(40).populate('product'),
    Order.find({ user: userId })
      .sort({ createdAt: -1 })
      .limit(20)
      .populate('items.productId'),
  ]);

  const signals = {
    categories: new Map(),
    flowerTypes: new Map(),
  };
  const seenProductIds = new Set();

  favorites.forEach((favorite) =>
    addRecommendationSignal({
      product: favorite.product,
      weight: 4,
      signals,
      seenProductIds,
    })
  );

  cartItems.forEach((item) =>
    addRecommendationSignal({
      product: item.product,
      weight: 3,
      signals,
      seenProductIds,
    })
  );

  orders.forEach((order, orderIndex) => {
    const recencyWeight = Math.max(2, 5 - orderIndex * 0.2);
    (order.items || []).forEach((item) => {
      const quantity = Math.max(1, Number(item.quantity) || 1);
      addRecommendationSignal({
        product: item.productId,
        weight: recencyWeight + Math.min(quantity, 5),
        signals,
        seenProductIds,
      });
    });
  });

  const hasSignals = signals.categories.size > 0 || signals.flowerTypes.size > 0;
  if (!hasSignals) {
    return getFallbackRecommendations(limit);
  }

  const candidates = await Product.find({ inStock: true }).sort({
    popular: -1,
    createdAt: -1,
  });
  const scored = candidates
    .filter((product) => !seenProductIds.has(String(product._id)))
    .map((product) => {
      const categoryId = product.category ? String(product.category) : '';
      const flowerType = String(product.flowerType || '').trim().toLowerCase();
      let score = 0;
      score += signals.categories.get(categoryId) || 0;
      score += signals.flowerTypes.get(flowerType) || 0;
      if (product.popular) score += 1.5;
      score += Math.min(Math.max(Number(product.stockCount) || 0, 0), 20) / 20;
      return { product, score };
    })
    .filter((item) => item.score > 0)
    .sort((left, right) => {
      if (right.score !== left.score) return right.score - left.score;
      if (Boolean(left.product.popular) !== Boolean(right.product.popular)) {
        return left.product.popular ? -1 : 1;
      }
      const leftTime = left.product.createdAt ? new Date(left.product.createdAt).getTime() : 0;
      const rightTime = right.product.createdAt ? new Date(right.product.createdAt).getTime() : 0;
      return rightTime - leftTime;
    });

  const recommendations = scored.slice(0, limit).map((item) => item.product);
  if (recommendations.length < limit) {
    const excludedIds = new Set(recommendations.map((product) => String(product._id)));
    const fallback = await getFallbackRecommendations(limit - recommendations.length, excludedIds);
    recommendations.push(...fallback);
  }
  return recommendations.slice(0, limit);
};

const readPositiveInteger = (value) => {
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed <= 0) return null;
  return parsed;
};

const rollbackStock = async (Model, decremented) => {
  if (!decremented.length) return;
  await Model.bulkWrite(
    decremented.map((entry) => ({
      updateOne: {
        filter: { _id: entry.id },
        update: {
          $inc: { stockCount: entry.quantity },
          $set: { inStock: true },
        },
      },
    }))
  );
};

const sanitizePickupStore = (pickupStore) => {
  if (!pickupStore || typeof pickupStore !== 'object') return null;
  const name = String(pickupStore.name || '').trim();
  const address = String(pickupStore.address || '').trim();
  if (!name || !address) return null;
  return {
    id: String(pickupStore.id || '').trim(),
    name,
    address,
    latitude: Number.isFinite(Number(pickupStore.latitude))
      ? Number(pickupStore.latitude)
      : undefined,
    longitude: Number.isFinite(Number(pickupStore.longitude))
      ? Number(pickupStore.longitude)
      : undefined,
  };
};

const normalizeCardNumber = (value) => String(value || '').replace(/\D/g, '');

const detectCardBrand = (digits) => {
  if (/^4/.test(digits)) return 'visa';
  if (/^(5[1-5]|2[2-7])/.test(digits)) return 'mastercard';
  return '';
};

const validatePaymentPayload = ({ cardholderName, cardNumber, expMonth, expYear, cvv }) => {
  const holder = String(cardholderName || '').trim();
  const digits = normalizeCardNumber(cardNumber);
  const month = Number.parseInt(expMonth, 10);
  const year = Number.parseInt(expYear, 10);
  const currentYear = new Date().getFullYear();
  const securityCode = String(cvv || '').trim();
  if (!holder || digits.length < 12 || digits.length > 19) return null;
  if (!Number.isInteger(month) || month < 1 || month > 12) return null;
  if (!Number.isInteger(year) || year < currentYear || year > 2100) return null;
  if (!/^\d{3,4}$/.test(securityCode)) return null;
  return {
    cardholderName: holder,
    cardNumber: digits,
    expMonth: String(month).padStart(2, '0'),
    expYear: String(year),
    last4: digits.slice(-4),
    brand: detectCardBrand(digits),
  };
};

const validatePaymentMetadata = ({ cardholderName, expMonth, expYear }) => {
  const holder = String(cardholderName || '').trim();
  const month = Number.parseInt(expMonth, 10);
  const year = Number.parseInt(expYear, 10);
  const currentYear = new Date().getFullYear();
  if (!holder) return null;
  if (!Number.isInteger(month) || month < 1 || month > 12) return null;
  if (!Number.isInteger(year) || year < currentYear || year > 2100) return null;
  return {
    cardholderName: holder,
    expMonth: String(month).padStart(2, '0'),
    expYear: String(year),
  };
};

const createPaymentToken = () => encryptField(`local-card-token:${crypto.randomUUID()}`);

const scrubStoredPaymentSecrets = async () => {
  const methods = await PaymentMethod.find({
    $or: [
      { cardNumber: { $exists: true } },
      { cvv: { $exists: true } },
      { paymentToken: { $exists: false } },
    ],
  }).select('+cardNumber +cvv');
  if (methods.length === 0) return;

  const updates = methods.map((method) => {
    const set = {};
    const unset = { cardNumber: '', cvv: '' };
    if (!method.paymentToken) {
      set.paymentToken = createPaymentToken();
    }
    if (!method.last4 && method.cardNumber) {
      try {
        const digits = normalizeCardNumber(decryptField(method.cardNumber));
        if (digits.length >= 4) {
          set.last4 = digits.slice(-4);
          set.brand = detectCardBrand(digits);
        }
      } catch (_) {}
    }
    return {
      updateOne: {
        filter: { _id: method._id },
        update: {
          ...(Object.keys(set).length > 0 ? { $set: set } : {}),
          $unset: unset,
        },
      },
    };
  });
  await PaymentMethod.bulkWrite(updates);
};

const toPaymentMethodResponse = (method, details = {}) => ({
  id: method._id,
  last4: method.last4 || details.last4 || '',
  brand: method.brand || details.brand || '',
  expMonth: details.expMonth,
  expYear: details.expYear,
  cardholderName: details.cardholderName,
  maskedCardNumber: method.last4 ? `**** **** **** ${method.last4}` : '',
});

const sanitizeChatText = (value) =>
  String(value || '').replace(/\s+/g, ' ').trim().slice(0, CHAT_MAX_MESSAGE_CHARS);

const pruneChatMessages = async (sessionId) => {
  const stale = await ChatMessage.find({ session: sessionId })
    .sort({ createdAt: -1 })
    .skip(CHAT_MAX_STORED_MESSAGES)
    .select('_id');
  if (stale.length > 0) {
    await ChatMessage.deleteMany({ _id: { $in: stale.map((entry) => entry._id) } });
  }
};

app.get('/', (req, res) => {
  res.json({ status: 'ok' });
});

app.post('/upload-image', authRequired, requireRole('worker', 'admin', 'super_admin'), (req, res) => {
  imageUpload.single('file')(req, res, async (uploadError) => {
    if (uploadError) {
      return res.status(400).json({ message: uploadError.message || 'Image upload failed' });
    }
    try {
      if (!req.file) {
        return res.status(400).json({ message: 'Image file is required' });
      }
      if (!hasCloudinaryConfig()) {
        return res.status(500).json({ message: 'Cloudinary config missing' });
      }
      const result = await uploadImageBufferToCloudinary(req.file, req.body.folder);
      if (!result?.secure_url) {
        return res.status(502).json({ message: 'Cloudinary did not return a secure URL' });
      }
      return res.json({ imageUrl: result.secure_url });
    } catch (error) {
      console.error('Cloudinary upload error:', error);
      return res.status(500).json({ message: 'Image upload failed' });
    }
  });
});

app.post('/auth/register', async (req, res) => {
  try {
    const { name, phone, email, password } = req.body;
    if (!name || !phone || !email || !password) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const existing = await User.findOne({
      $or: [{ phone }, { email: email.toLowerCase() }],
    });
    if (existing) {
      return res.status(400).json({ message: 'User already exists' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const role = await getRoleForEmail(email);
    const user = await User.create({
      name,
      phone,
      email: email.toLowerCase(),
      role,
      passwordHash,
    });

    const token = createToken(user._id, user.email, role);

    return res.status(201).json({
      message: 'Registered',
      token,
      role,
      name: user.name,
      email: user.email,
    });
  } catch (error) {
    return res.status(500).json({ message: 'Registration failed' });
  }
});

app.post('/auth/login', async (req, res) => {
  try {
    const { login, password } = req.body;
    if (!login || !password) {
      return res.status(400).json({ message: 'Missing credentials' });
    }

    const user = await User.findOne({
      $or: [{ phone: login }, { email: login.toLowerCase() }],
    });
    if (!user) return res.status(401).json({ message: 'Invalid credentials' });

    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) return res.status(401).json({ message: 'Invalid credentials' });

    const role = await getRoleForEmail(user.email);
    if (user.role !== role) {
      user.role = role;
      await user.save();
    }
    const token = createToken(user._id, user.email, role);

    return res.json({
      message: 'Login success',
      token,
      role,
      name: user.name,
      email: user.email,
    });
  } catch (error) {
    return res.status(500).json({ message: 'Login failed' });
  }
});

app.get('/auth/me', authRequired, (req, res) => {
  res.json({
    id: req.user.userId,
    email: req.user.email,
    role: req.user.role,
    name: req.user.name,
  });
});

app.post('/auth/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ message: 'Email required' });
    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      return res.json({ message: 'If the account exists, a code was sent.' });
    }

    const code = String(crypto.randomInt(100000, 1000000));
    user.resetCodeHash = hashToken(code);
    user.resetCodeExpiresAt = new Date(Date.now() + RESET_CODE_TTL_MIN * 60 * 1000);
    user.resetTokenHash = null;
    user.resetTokenExpiresAt = null;
    await user.save();

    await sendResetCodeEmail({ email: user.email, code });
    return res.json({ message: 'If the account exists, a code was sent.' });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to send reset code' });
  }
});

app.post('/auth/verify-reset-code', async (req, res) => {
  try {
    const { email, code } = req.body;
    if (!email || !code) return res.status(400).json({ message: 'Email and code required' });
    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user || !user.resetCodeHash || !user.resetCodeExpiresAt) {
      return res.status(400).json({ message: 'Invalid or expired code' });
    }
    if (user.resetCodeExpiresAt.getTime() < Date.now()) {
      return res.status(400).json({ message: 'Invalid or expired code' });
    }
    const codeHash = hashToken(code);
    if (codeHash !== user.resetCodeHash) {
      return res.status(400).json({ message: 'Invalid or expired code' });
    }

    const resetToken = crypto.randomBytes(32).toString('hex');
    user.resetTokenHash = hashToken(resetToken);
    user.resetTokenExpiresAt = new Date(Date.now() + RESET_TOKEN_TTL_MIN * 60 * 1000);
    user.resetCodeHash = null;
    user.resetCodeExpiresAt = null;
    await user.save();

    return res.json({ resetToken });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to verify code' });
  }
});

app.post('/auth/reset-password', async (req, res) => {
  try {
    const { email, resetToken, newPassword } = req.body;
    if (!email || !resetToken || !newPassword) {
      return res.status(400).json({ message: 'Missing fields' });
    }
    if (String(newPassword).length < 6) {
      return res.status(400).json({ message: 'Password too short' });
    }
    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user || !user.resetTokenHash || !user.resetTokenExpiresAt) {
      return res.status(400).json({ message: 'Invalid or expired reset token' });
    }
    if (user.resetTokenExpiresAt.getTime() < Date.now()) {
      return res.status(400).json({ message: 'Invalid or expired reset token' });
    }
    const tokenHash = hashToken(resetToken);
    if (tokenHash !== user.resetTokenHash) {
      return res.status(400).json({ message: 'Invalid or expired reset token' });
    }

    user.passwordHash = await bcrypt.hash(newPassword, 10);
    user.resetTokenHash = null;
    user.resetTokenExpiresAt = null;
    await user.save();

    return res.json({ message: 'Password updated' });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to reset password' });
  }
});

app.get('/categories', async (req, res) => {
  const categories = await Category.find().sort({ order: 1 });
  res.json(categories.map(toCategoryResponse));
});

app.get('/custom-items', async (req, res) => {
  const items = await CustomBouquetItem.find().sort({ group: 1, order: 1, name: 1 });
  res.json(items.map(toCustomBouquetItemResponse));
});

app.post(
  '/custom-items',
  authRequired,
  requireRole('worker', 'admin', 'super_admin'),
  async (req, res) => {
    try {
      const name = String(req.body.name || '').trim();
      const group = String(req.body.group || 'extras').trim();
      const price = Number(req.body.price);
      const stockCount = Number(req.body.stockCount ?? 0);
      const order = Number(req.body.order ?? 0);
      const imagePath = String(req.body.imagePath || req.body.imageUrl || '').trim();
      const imageUrl = String(req.body.imageUrl || '').trim();

      if (!name || !Number.isFinite(price) || price < 0) {
        return res.status(400).json({ message: 'Name and price are required' });
      }
      if (!Number.isFinite(stockCount) || stockCount < 0) {
        return res.status(400).json({ message: 'Stock count is invalid' });
      }

      const item = await CustomBouquetItem.create({
        name,
        group,
        price,
        stockCount,
        inStock: req.body.inStock !== undefined ? !!req.body.inStock : stockCount > 0,
        order: Number.isFinite(order) ? order : 0,
        imagePath,
        imageUrl: imageUrl || (isExternalImageUrl(imagePath) ? imagePath : ''),
      });
      res.status(201).json(toCustomBouquetItemResponse(item));
    } catch (error) {
      res.status(500).json({ message: 'Custom item create failed' });
    }
  }
);

app.put(
  '/custom-items/:id',
  authRequired,
  requireRole('worker', 'admin', 'super_admin'),
  async (req, res) => {
    try {
      const updates = {};
      if (req.body.name !== undefined) updates.name = String(req.body.name || '').trim();
      if (req.body.group !== undefined) updates.group = String(req.body.group || 'extras').trim();
      if (req.body.imagePath !== undefined) {
        updates.imagePath = String(req.body.imagePath || '').trim();
      }
      if (req.body.imageUrl !== undefined) {
        updates.imageUrl = String(req.body.imageUrl || '').trim();
      }
      if (req.body.price !== undefined) {
        const price = Number(req.body.price);
        if (!Number.isFinite(price) || price < 0) {
          return res.status(400).json({ message: 'Price is invalid' });
        }
        updates.price = price;
      }
      if (req.body.stockCount !== undefined) {
        const stockCount = Number(req.body.stockCount);
        if (!Number.isFinite(stockCount) || stockCount < 0) {
          return res.status(400).json({ message: 'Stock count is invalid' });
        }
        updates.stockCount = stockCount;
      }
      if (req.body.inStock !== undefined) updates.inStock = !!req.body.inStock;
      if (req.body.order !== undefined) {
        const order = Number(req.body.order);
        updates.order = Number.isFinite(order) ? order : 0;
      }

      if (updates.name === '') {
        return res.status(400).json({ message: 'Name is required' });
      }
      if (updates.imagePath !== undefined && updates.imageUrl === undefined) {
        updates.imageUrl = isExternalImageUrl(updates.imagePath) ? updates.imagePath : '';
      }
      if (updates.imageUrl !== undefined && updates.imagePath === undefined && updates.imageUrl) {
        updates.imagePath = updates.imageUrl;
      }

      const item = await CustomBouquetItem.findByIdAndUpdate(req.params.id, updates, {
        new: true,
      });
      if (!item) return res.status(404).json({ message: 'Not found' });
      res.json(toCustomBouquetItemResponse(item));
    } catch (error) {
      res.status(500).json({ message: 'Custom item update failed' });
    }
  }
);

app.delete(
  '/custom-items/:id',
  authRequired,
  requireRole('worker', 'admin', 'super_admin'),
  async (req, res) => {
    const item = await CustomBouquetItem.findByIdAndDelete(req.params.id);
    if (!item) return res.status(404).json({ message: 'Not found' });
    res.json({ message: 'Deleted' });
  }
);

app.get('/products', async (req, res) => {
  const filter = {};
  if (req.query.categoryId) filter.category = req.query.categoryId;
  if (req.query.popular === 'true') filter.popular = true;
  const occasionTags = normalizeTagList(req.query.occasion);
  const recipientTags = normalizeTagList(req.query.recipient);
  if (occasionTags.length > 0) filter.occasionTags = { $in: occasionTags };
  if (recipientTags.length > 0) filter.recipientTags = { $in: recipientTags };
  const products = await Product.find(filter).sort({ createdAt: -1 });
  res.json(products.map(toProductResponse));
});

app.get('/recommendations', authRequired, async (req, res) => {
  try {
    const limit = clampRecommendationLimit(req.query.limit);
    const recommendations = await buildRecommendationsForUser(req.user.userId, limit);
    res.json(recommendations.map(toProductResponse));
  } catch (error) {
    console.error('Recommendations error:', error);
    res.status(500).json({ message: 'Recommendations failed' });
  }
});

app.post('/vision/search', async (req, res) => {
  try {
    const rawImage = req.body?.imageBase64 || req.body?.image;
    const imageBase64 = normalizeImageBase64(rawImage);
    if (!imageBase64) {
      return res.status(400).json({ message: 'Image is required' });
    }

    const parsedLimit = Number.parseInt(req.body?.limit || '12', 10);
    const limit = Number.isFinite(parsedLimit)
      ? Math.min(Math.max(parsedLimit, 1), 30)
      : 12;
    const products = await Product.find().sort({ createdAt: -1 });
    const mimeType = getImageMimeType(rawImage, imageBase64);
    const analysis = await analyzeImageWithGemini({
      imageBase64,
      mimeType,
      products,
    });
    const ranked = rankProductsForVisionAnalysis(products, analysis, limit);

    res.json({
      detectedObject: analysis.detectedObject || analysis.productQuery || '',
      description: analysis.description || '',
      terms: ranked.terms.slice(0, 20),
      products: ranked.products,
    });
  } catch (error) {
    console.error('Gemini vision search error:', error);
    const status = error?.status || error?.response?.status || 500;
    const message =
      error?.message ||
      error?.response?.data?.error?.message ||
      'Photo search failed';
    if (status === 404) {
      try {
        const { models, error: listError } = await fetchGeminiModels(GEMINI_API_KEY);
        const available = models.filter((model) =>
          (model.supportedMethods || []).includes('generateContent')
        );
        return res.status(status).json({
          message,
          availableModels: available.map((model) => model.name),
          listModelsError: listError,
        });
      } catch (_) {
        return res.status(status).json({ message });
      }
    }
    res.status(status).json({ message });
  }
});

app.get('/products/:id', async (req, res) => {
  const product = await Product.findById(req.params.id);
  if (!product) return res.status(404).json({ message: 'Not found' });
  res.json(toProductResponse(product));
});

app.post('/products', authRequired, requireRole('admin', 'super_admin'), async (req, res) => {
  try {
    const {
      name,
      price,
      imagePath,
      imageUrl,
      flowerType,
      categoryId,
      inStock,
      stockCount,
      popular,
      occasionTags,
      recipientTags,
    } = req.body;
    const storedImageUrl = String(imageUrl || '').trim();
    const storedImagePath = String(imagePath || storedImageUrl || '').trim();
    if (!name || price == null || !storedImagePath || !flowerType) {
      return res.status(400).json({ message: 'Missing fields' });
    }
    const tags = resolveProductTags({ occasionTags, recipientTags, name });
    const product = await Product.create({
      name,
      price,
      imagePath: storedImagePath,
      imageUrl: storedImageUrl || (isExternalImageUrl(storedImagePath) ? storedImagePath : ''),
      flowerType,
      category: categoryId || null,
      inStock: inStock !== undefined ? inStock : true,
      stockCount: stockCount || 0,
      popular: !!popular,
      occasionTags: tags.occasionTags,
      recipientTags: tags.recipientTags,
    });
    res.status(201).json(toProductResponse(product));
  } catch (error) {
    res.status(500).json({ message: 'Create failed' });
  }
});

app.put('/products/:id', authRequired, requireRole('admin', 'super_admin'), async (req, res) => {
  try {
    const updates = { ...req.body };
    if (updates.imageUrl !== undefined) {
      updates.imageUrl = String(updates.imageUrl || '').trim();
      if (!updates.imagePath && updates.imageUrl) {
        updates.imagePath = updates.imageUrl;
      }
    }
    if (updates.imagePath !== undefined) {
      updates.imagePath = String(updates.imagePath || '').trim();
      if (!updates.imageUrl && isExternalImageUrl(updates.imagePath)) {
        updates.imageUrl = updates.imagePath;
      }
    }
    if (updates.categoryId) {
      updates.category = updates.categoryId;
      delete updates.categoryId;
    }
    const shouldResolveTags =
      updates.occasionTags !== undefined || updates.recipientTags !== undefined || updates.name;
    if (shouldResolveTags) {
      const existing = await Product.findById(req.params.id);
      if (!existing) return res.status(404).json({ message: 'Not found' });
      const nameForTags = updates.name || existing.name;
      const tags = resolveProductTags({
        occasionTags: updates.occasionTags,
        recipientTags: updates.recipientTags,
        name: nameForTags,
      });
      updates.occasionTags = tags.occasionTags;
      updates.recipientTags = tags.recipientTags;
    }
    const product = await Product.findByIdAndUpdate(req.params.id, updates, { new: true });
    if (!product) return res.status(404).json({ message: 'Not found' });
    res.json(toProductResponse(product));
  } catch (error) {
    res.status(500).json({ message: 'Update failed' });
  }
});

app.patch('/products/:id/stock', authRequired, requireRole('admin', 'super_admin'), async (req, res) => {
  try {
    const { inStock, stockCount } = req.body;
    const updates = {};
    if (inStock !== undefined) updates.inStock = inStock;
    if (stockCount !== undefined) updates.stockCount = stockCount;
    const product = await Product.findByIdAndUpdate(req.params.id, updates, { new: true });
    if (!product) return res.status(404).json({ message: 'Not found' });
    res.json(toProductResponse(product));
  } catch (error) {
    res.status(500).json({ message: 'Stock update failed' });
  }
});

app.patch('/products/:id/popular', authRequired, requireRole('admin', 'super_admin'), async (req, res) => {
  try {
    const { popular } = req.body;
    if (popular === undefined) {
      return res.status(400).json({ message: 'Popular required' });
    }
    const product = await Product.findByIdAndUpdate(
      req.params.id,
      { popular: !!popular },
      { new: true }
    );
    if (!product) return res.status(404).json({ message: 'Not found' });
    res.json(toProductResponse(product));
  } catch (error) {
    res.status(500).json({ message: 'Popular update failed' });
  }
});

app.delete('/products/:id', authRequired, requireRole('admin', 'super_admin'), async (req, res) => {
  const product = await Product.findByIdAndDelete(req.params.id);
  if (!product) return res.status(404).json({ message: 'Not found' });
  res.json({ message: 'Deleted' });
});

app.post('/orders', authRequired, async (req, res) => {
  try {
    const { items, deliveryMethod, pickupStore, deliveryAddress } = req.body;
    if (!Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ message: 'Empty order' });
    }

    const requested = new Map();
    const requestedCustomCartItems = new Map();
    for (const item of items) {
      const cartItemId = String(item.cartItemId || item.cartId || '').trim();
      const productId = String(item.productId || item.id || '').trim();
      const quantity = readPositiveInteger(item.quantity === undefined ? 1 : item.quantity);

      if (cartItemId) {
        if (!mongoose.Types.ObjectId.isValid(cartItemId) || !quantity) {
          return res.status(400).json({ message: 'Invalid custom cart item' });
        }
        requestedCustomCartItems.set(
          cartItemId,
          (requestedCustomCartItems.get(cartItemId) || 0) + quantity
        );
        continue;
      }

      if (!mongoose.Types.ObjectId.isValid(productId) || !quantity) {
        return res.status(400).json({ message: 'Invalid order item' });
      }
      requested.set(productId, (requested.get(productId) || 0) + quantity);
    }

    if (requested.size === 0 && requestedCustomCartItems.size === 0) {
      return res.status(400).json({ message: 'Empty order' });
    }

    const hasDeliveryDetails = Object.prototype.hasOwnProperty.call(req.body, 'deliveryMethod');
    const normalizedDeliveryMethod = deliveryMethod === 'courier' ? 'courier' : 'pickup';
    const normalizedPickupStore = sanitizePickupStore(pickupStore);

    if (
      hasDeliveryDetails &&
      normalizedDeliveryMethod === 'pickup' &&
      !normalizedPickupStore
    ) {
      return res.status(400).json({ message: 'Please select a pickup store.' });
    }

    const normalizedAddress =
      typeof deliveryAddress === 'string' ? deliveryAddress.trim() : '';
    if (
      hasDeliveryDetails &&
      normalizedDeliveryMethod === 'courier' &&
      normalizedAddress.length === 0
    ) {
      return res.status(400).json({ message: 'Please enter the delivery address.' });
    }

    const products = await Product.find({ _id: { $in: Array.from(requested.keys()) } });
    if (products.length !== requested.size) {
      return res.status(400).json({ message: 'Product not found' });
    }

    const customCartItems = requestedCustomCartItems.size
      ? await CartItem.find({
          _id: { $in: Array.from(requestedCustomCartItems.keys()) },
          user: req.user.userId,
          itemType: 'custom',
        })
      : [];
    if (customCartItems.length !== requestedCustomCartItems.size) {
      return res.status(400).json({ message: 'Custom cart item not found' });
    }

    const orderItems = [];
    const customOrderItems = [];
    const customDescriptions = [];
    const requestedCustomStock = new Map();
    let subtotal = 0;

    for (const product of products) {
      const quantity = requested.get(String(product._id));
      if (!product.inStock || product.stockCount < quantity) {
        return res.status(400).json({ message: `${product.name} is out of stock` });
      }
      const imagePath = product.imagePath || product.imageUrl || '';
      const imageUrl = getProductDisplayImageUrl(product);
      subtotal += product.price * quantity;
      orderItems.push({
        productId: product._id,
        name: product.name,
        imagePath,
        imageUrl,
        price: product.price,
        quantity,
      });
    }

    for (const cartItem of customCartItems) {
      const quantity = requestedCustomCartItems.get(String(cartItem._id));
      const customItems = cartItem.customItems || [];
      if (!customItems.length || !(cartItem.customTotal > 0)) {
        return res.status(400).json({ message: 'Invalid custom cart item' });
      }

      subtotal += cartItem.customTotal * quantity;
      orderItems.push({
        name: 'Custom bouquet',
        imagePath: cartItem.imagePath || 'assets/cat_10.png',
        imageUrl: cartItem.imageUrl || '',
        price: cartItem.customTotal,
        quantity,
      });

      const description = String(cartItem.description || '').trim();
      if (description) customDescriptions.push(description);

      for (const customItem of customItems) {
        const customItemId = String(customItem.customItemId || '').trim();
        const itemQuantity = readPositiveInteger(customItem.quantity);
        if (!mongoose.Types.ObjectId.isValid(customItemId) || !itemQuantity) {
          return res.status(400).json({ message: 'Invalid custom cart item' });
        }
        const totalQuantity = itemQuantity * quantity;
        requestedCustomStock.set(
          customItemId,
          (requestedCustomStock.get(customItemId) || 0) + totalQuantity
        );
        customOrderItems.push({
          customItemId: customItem.customItemId,
          name: customItem.name,
          group: customItem.group,
          imagePath: customItem.imagePath,
          imageUrl: customItem.imageUrl,
          price: customItem.price,
          quantity: totalQuantity,
        });
      }
    }

    const stockCustomItems = requestedCustomStock.size
      ? await CustomBouquetItem.find({
          _id: { $in: Array.from(requestedCustomStock.keys()) },
        })
      : [];
    if (stockCustomItems.length !== requestedCustomStock.size) {
      return res.status(400).json({ message: 'Custom item not found' });
    }
    for (const item of stockCustomItems) {
      const quantity = requestedCustomStock.get(String(item._id));
      if (!item.inStock || item.stockCount < quantity) {
        return res.status(400).json({ message: `${item.name} is out of stock` });
      }
    }

    const deliveryPrice = normalizedDeliveryMethod === 'courier' ? 1000 : 0;
    const total = subtotal + deliveryPrice;

    const decremented = [];
    const customDecremented = [];
    for (const product of products) {
      const quantity = requested.get(String(product._id));
      const updated = await Product.findOneAndUpdate(
        { _id: product._id, inStock: true, stockCount: { $gte: quantity } },
        { $inc: { stockCount: -quantity } },
        { new: true }
      );
      if (!updated) {
        await rollbackStock(Product, decremented);
        return res.status(400).json({ message: `${product.name} is out of stock` });
      }
      decremented.push({ id: product._id, quantity });
    }

    for (const item of stockCustomItems) {
      const quantity = requestedCustomStock.get(String(item._id));
      const updated = await CustomBouquetItem.findOneAndUpdate(
        { _id: item._id, inStock: true, stockCount: { $gte: quantity } },
        { $inc: { stockCount: -quantity } },
        { new: true }
      );
      if (!updated) {
        await rollbackStock(Product, decremented);
        await rollbackStock(CustomBouquetItem, customDecremented);
        return res.status(400).json({ message: `${item.name} is out of stock` });
      }
      customDecremented.push({ id: item._id, quantity });
    }

    let order;
    try {
      order = await Order.create({
        user: req.user.userId,
        orderType: requestedCustomCartItems.size > 0 ? 'custom' : 'standard',
        description: customDescriptions.join('; '),
        items: orderItems,
        customItems: customOrderItems,
        subtotal,
        deliveryMethod: normalizedDeliveryMethod,
        deliveryPrice,
        pickupStore: normalizedDeliveryMethod === 'pickup' ? normalizedPickupStore : null,
        deliveryAddress: normalizedDeliveryMethod === 'courier' ? normalizedAddress : null,
        total,
      });
    } catch (error) {
      await rollbackStock(Product, decremented);
      await rollbackStock(CustomBouquetItem, customDecremented);
      throw error;
    }

    if (decremented.length) {
      await Product.updateMany(
        { _id: { $in: decremented.map((entry) => entry.id) }, stockCount: { $lte: 0 } },
        { $set: { inStock: false, stockCount: 0 } }
      );
    }
    if (customDecremented.length) {
      await CustomBouquetItem.updateMany(
        { _id: { $in: customDecremented.map((entry) => entry.id) }, stockCount: { $lte: 0 } },
        { $set: { inStock: false, stockCount: 0 } }
      );
    }

    const deleteFilters = [];
    if (requested.size) {
      deleteFilters.push({ product: { $in: Array.from(requested.keys()) } });
    }
    if (requestedCustomCartItems.size) {
      deleteFilters.push({ _id: { $in: Array.from(requestedCustomCartItems.keys()) } });
    }
    if (deleteFilters.length) {
      await CartItem.deleteMany({
        user: req.user.userId,
        $or: deleteFilters,
      });
    }

    try {
      await Notification.create({
        user: req.user.userId,
        title: 'Тапсырыс жасалды',
        message: `Тапсырыс №${order._id} қабылданды`,
        type: 'order',
      });
      const adminUsers = await User.find({
        role: { $in: ['worker', 'admin', 'super_admin'] },
      }).select('_id email');
      if (adminUsers.length > 0) {
        const itemCount = orderItems.reduce((sum, item) => sum + item.quantity, 0);
        await Notification.insertMany(
          adminUsers.map((admin) => ({
            user: admin._id,
            title: 'Жаңа тапсырыс',
            message: `Тапсырыс №${order._id} | Клиент: ${req.user.email || ''} | Саны: ${itemCount} | Жалпы: ${total}`,
            type: 'order',
          }))
        );
      }
    } catch (notificationError) {
      console.error('Order notification failed:', notificationError);
    }

    res.status(201).json(order);
  } catch (error) {
    console.error('Order failed:', error);
    res.status(500).json({ message: 'Order failed' });
  }
});

app.post('/orders/custom', authRequired, async (req, res) => {
  try {
    const { items, description } = req.body;
    if (!Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ message: 'Empty custom order' });
    }

    const requested = new Map();
    for (const item of items) {
      const id = String(item.itemId || item.customItemId || item.id || '');
      const quantity = readPositiveInteger(item.quantity);
      if (!mongoose.Types.ObjectId.isValid(id) || !quantity) {
        return res.status(400).json({ message: 'Invalid custom item' });
      }
      requested.set(id, (requested.get(id) || 0) + quantity);
    }

    const customItems = await CustomBouquetItem.find({
      _id: { $in: Array.from(requested.keys()) },
    });
    if (customItems.length !== requested.size) {
      return res.status(400).json({ message: 'Custom item not found' });
    }
    const requestedFlowerCount = customItems.reduce((sum, item) => {
      if (item.group !== 'flowers') return sum;
      return sum + requested.get(String(item._id));
    }, 0);
    if (requestedFlowerCount > MAX_CUSTOM_FLOWERS) {
      return res.status(400).json({ message: `Custom bouquet can include up to ${MAX_CUSTOM_FLOWERS} flowers` });
    }

    let total = 0;
    const orderItems = [];
    const customOrderItems = [];

    for (const item of customItems) {
      const quantity = requested.get(String(item._id));
      if (!item.inStock || item.stockCount < quantity) {
        return res.status(400).json({ message: `${item.name} is out of stock` });
      }
      const itemImagePath = item.imagePath || item.imageUrl || 'assets/cat_10.png';
      const itemImageUrl = item.imageUrl || (isExternalImageUrl(itemImagePath) ? itemImagePath : '');
      total += item.price * quantity;
      orderItems.push({
        name: item.name,
        imagePath: itemImagePath,
        imageUrl: itemImageUrl,
        price: item.price,
        quantity,
      });
      customOrderItems.push({
        customItemId: item._id,
        name: item.name,
        group: item.group,
        imagePath: itemImagePath,
        imageUrl: itemImageUrl,
        price: item.price,
        quantity,
      });
    }

    const decremented = [];
    for (const item of customItems) {
      const quantity = requested.get(String(item._id));
      const updated = await CustomBouquetItem.findOneAndUpdate(
        { _id: item._id, inStock: true, stockCount: { $gte: quantity } },
        { $inc: { stockCount: -quantity } },
        { new: true }
      );
      if (!updated) {
        await rollbackStock(CustomBouquetItem, decremented);
        return res.status(400).json({ message: `${item.name} is out of stock` });
      }
      decremented.push({ id: item._id, quantity });
    }

    let order;
    try {
      order = await Order.create({
        user: req.user.userId,
        orderType: 'custom',
        description: String(description || '').trim(),
        items: orderItems,
        customItems: customOrderItems,
        total,
      });
    } catch (error) {
      await rollbackStock(CustomBouquetItem, decremented);
      throw error;
    }

    await CustomBouquetItem.updateMany(
      { _id: { $in: decremented.map((entry) => entry.id) }, stockCount: { $lte: 0 } },
      { $set: { inStock: false, stockCount: 0 } }
    );

    try {
      await Notification.create({
        user: req.user.userId,
        title: 'Жеке букет тапсырысы',
        message: `Тапсырыс №${order._id} қабылданды`,
        type: 'order',
      });

      const staffUsers = await User.find({
        role: { $in: ['worker', 'admin', 'super_admin'] },
      }).select('_id email');
      if (staffUsers.length > 0) {
        const itemCount = customOrderItems.reduce((sum, item) => sum + item.quantity, 0);
        await Notification.insertMany(
          staffUsers.map((staff) => ({
            user: staff._id,
            title: 'Жаңа жеке букет',
            message: `Тапсырыс №${order._id} | Клиент: ${req.user.email || ''} | Саны: ${itemCount} | Жалпы: ${total}`,
            type: 'order',
          }))
        );
      }
    } catch (notificationError) {
      console.error('Custom order notification failed:', notificationError);
    }

    res.status(201).json(order);
  } catch (error) {
    res.status(500).json({ message: 'Custom order failed' });
  }
});

app.get('/orders', authRequired, requireRole('worker', 'admin', 'super_admin'), async (req, res) => {
  const orders = await Order.find().sort({ createdAt: -1 }).populate('user', 'name email');
  res.json(orders);
});

app.get('/orders/my', authRequired, async (req, res) => {
  const orders = await Order.find({ user: req.user.userId }).sort({ createdAt: -1 });
  res.json(orders);
});

app.get('/payment-methods', authRequired, async (req, res) => {
  try {
    const methods = await PaymentMethod.find({ user: req.user.userId }).sort({ createdAt: -1 });
    res.json(methods.map((method) => toPaymentMethodResponse(method)));
  } catch (error) {
    res.status(500).json({ message: 'Failed to load payment methods' });
  }
});

app.get('/payment-methods/:id', authRequired, async (req, res) => {
  try {
    const method = await PaymentMethod.findOne({ _id: req.params.id, user: req.user.userId });
    if (!method) return res.status(404).json({ message: 'Not found' });
    res.json(
      toPaymentMethodResponse(method, {
        cardholderName: decryptField(method.cardholderName),
        expMonth: decryptField(method.expMonth),
        expYear: decryptField(method.expYear),
      })
    );
  } catch (error) {
    res.status(500).json({ message: 'Failed to load payment method' });
  }
});

app.post('/payment-methods', authRequired, async (req, res) => {
  try {
    const { cardholderName, cardNumber, expMonth, expYear, cvv } = req.body;
    const payment = validatePaymentPayload({ cardholderName, cardNumber, expMonth, expYear, cvv });
    if (!payment) return res.status(400).json({ message: 'Invalid payment method' });
    const method = await PaymentMethod.create({
      user: req.user.userId,
      cardholderName: encryptField(payment.cardholderName),
      paymentToken: createPaymentToken(),
      last4: payment.last4,
      brand: payment.brand,
      expMonth: encryptField(payment.expMonth),
      expYear: encryptField(payment.expYear),
    });
    res.status(201).json(toPaymentMethodResponse(method));
  } catch (error) {
    res.status(500).json({ message: 'Failed to save payment method' });
  }
});

app.put('/payment-methods/:id', authRequired, async (req, res) => {
  try {
    const { cardholderName, cardNumber, expMonth, expYear, cvv } = req.body;
    if (!cardholderName || !expMonth || !expYear) {
      return res.status(400).json({ message: 'Missing fields' });
    }
    const metadata = validatePaymentMetadata({ cardholderName, expMonth, expYear });
    if (!metadata) return res.status(400).json({ message: 'Invalid payment method' });
    const updates = {
      $set: {
        cardholderName: encryptField(metadata.cardholderName),
        expMonth: encryptField(metadata.expMonth),
        expYear: encryptField(metadata.expYear),
      },
      $unset: { cardNumber: '', cvv: '' },
    };
    if (cardNumber || cvv) {
      const payment = validatePaymentPayload({
        cardholderName,
        cardNumber,
        expMonth,
        expYear,
        cvv,
      });
      if (!payment) return res.status(400).json({ message: 'Invalid payment method' });
      updates.$set.cardholderName = encryptField(payment.cardholderName);
      updates.$set.paymentToken = createPaymentToken();
      updates.$set.last4 = payment.last4;
      updates.$set.brand = payment.brand;
      updates.$set.expMonth = encryptField(payment.expMonth);
      updates.$set.expYear = encryptField(payment.expYear);
    }
    const method = await PaymentMethod.findOneAndUpdate(
      { _id: req.params.id, user: req.user.userId },
      updates,
      { new: true, runValidators: true }
    );
    if (!method) return res.status(404).json({ message: 'Not found' });
    res.json(toPaymentMethodResponse(method));
  } catch (error) {
    res.status(500).json({ message: 'Failed to update payment method' });
  }
});

app.delete('/payment-methods/:id', authRequired, async (req, res) => {
  try {
    const method = await PaymentMethod.findOneAndDelete({
      _id: req.params.id,
      user: req.user.userId,
    });
    if (!method) return res.status(404).json({ message: 'Not found' });
    res.json({ message: 'Deleted' });
  } catch (error) {
    res.status(500).json({ message: 'Failed to delete payment method' });
  }
});

app.patch('/orders/:id', authRequired, requireRole('worker', 'admin', 'super_admin'), async (req, res) => {
  try {
    const status = String(req.body.status || '').trim();
    if (!ORDER_STATUSES.includes(status)) {
      return res.status(400).json({ message: 'Invalid order status' });
    }
    const order = await Order.findByIdAndUpdate(
      req.params.id,
      { status },
      { new: true, runValidators: true }
    );
    if (!order) return res.status(404).json({ message: 'Not found' });
    const statusTitle = {
      pending: 'Тапсырыс күту режимінде',
      processing: 'Тапсырыс өңделуде',
      completed: 'Тапсырыс расталды',
      cancelled: 'Тапсырыс бас тартылды',
    }[order.status] || 'Тапсырыс мәртебесі өзгерді';
    await Notification.create({
      user: order.user,
      title: statusTitle,
      message: `Тапсырыс №${order._id}`,
      type: 'order',
    });
    res.json(order);
  } catch (error) {
    res.status(500).json({ message: 'Order status update failed' });
  }
});

app.get('/favorites', authRequired, async (req, res) => {
  const favorites = await Favorite.find({ user: req.user.userId }).populate('product');
  const products = favorites
    .map((fav) => fav.product)
    .filter((product) => !!product)
    .map((product) => toProductResponse(product));
  res.json(products);
});

app.post('/favorites', authRequired, async (req, res) => {
  try {
    const { productId } = req.body;
    if (!productId) return res.status(400).json({ message: 'Product required' });
    await Favorite.findOneAndUpdate(
      { user: req.user.userId, product: productId },
      { $setOnInsert: { user: req.user.userId, product: productId } },
      { upsert: true, new: true }
    );
    res.status(201).json({ message: 'Added' });
  } catch (error) {
    res.status(500).json({ message: 'Favorite add failed' });
  }
});

app.delete('/favorites/:productId', authRequired, async (req, res) => {
  await Favorite.findOneAndDelete({ user: req.user.userId, product: req.params.productId });
  res.json({ message: 'Removed' });
});

app.get('/cart', authRequired, async (req, res) => {
  const items = await CartItem.find({ user: req.user.userId }).populate('product');
  const response = items
    .filter((item) => item.itemType === 'custom' || item.product)
    .map(toCartItemResponse);
  res.json(response);
});

app.post('/cart', authRequired, async (req, res) => {
  try {
    const { productId, quantity } = req.body;
    if (!productId) return res.status(400).json({ message: 'Product required' });
    const delta = Number.isFinite(quantity) ? Number(quantity) : 1;
    if (delta <= 0) return res.status(400).json({ message: 'Quantity must be positive' });
    const item = await CartItem.findOneAndUpdate(
      { user: req.user.userId, product: productId },
      { $inc: { quantity: delta }, $setOnInsert: { user: req.user.userId, product: productId } },
      { upsert: true, new: true }
    );
    res.status(201).json({ productId: item.product, quantity: item.quantity });
  } catch (error) {
    res.status(500).json({ message: 'Cart update failed' });
  }
});

app.post('/cart/custom', authRequired, async (req, res) => {
  try {
    const { items, description } = req.body;
    if (!Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ message: 'Empty custom cart item' });
    }

    const quantity = readPositiveInteger(req.body.quantity === undefined ? 1 : req.body.quantity);
    if (!quantity) {
      return res.status(400).json({ message: 'Quantity must be positive' });
    }

    const requested = new Map();
    for (const item of items) {
      const id = String(item.itemId || item.customItemId || item.id || '');
      const itemQuantity = readPositiveInteger(item.quantity);
      if (!mongoose.Types.ObjectId.isValid(id) || !itemQuantity) {
        return res.status(400).json({ message: 'Invalid custom item' });
      }
      requested.set(id, (requested.get(id) || 0) + itemQuantity);
    }

    const customItems = await CustomBouquetItem.find({
      _id: { $in: Array.from(requested.keys()) },
    });
    if (customItems.length !== requested.size) {
      return res.status(400).json({ message: 'Custom item not found' });
    }

    const requestedFlowerCount = customItems.reduce((sum, item) => {
      if (item.group !== 'flowers') return sum;
      return sum + requested.get(String(item._id));
    }, 0);
    if (requestedFlowerCount > MAX_CUSTOM_FLOWERS) {
      return res.status(400).json({ message: `Custom bouquet can include up to ${MAX_CUSTOM_FLOWERS} flowers` });
    }

    let total = 0;
    const customCartItems = [];
    let imagePath = 'assets/cat_10.png';
    let imageUrl = '';

    for (const item of customItems) {
      const itemQuantity = requested.get(String(item._id));
      const totalRequestedQuantity = itemQuantity * quantity;
      if (!item.inStock || item.stockCount < totalRequestedQuantity) {
        return res.status(400).json({ message: `${item.name} is out of stock` });
      }

      const itemImagePath = item.imagePath || item.imageUrl || 'assets/cat_10.png';
      const itemImageUrl = item.imageUrl || (isExternalImageUrl(itemImagePath) ? itemImagePath : '');
      if (!imageUrl && itemImageUrl) imageUrl = itemImageUrl;
      if (imagePath === 'assets/cat_10.png' && itemImagePath) imagePath = itemImagePath;

      total += item.price * itemQuantity;
      customCartItems.push({
        customItemId: item._id,
        name: item.name,
        group: item.group,
        imagePath: itemImagePath,
        imageUrl: itemImageUrl,
        price: item.price,
        quantity: itemQuantity,
      });
    }

    const cartItem = await CartItem.findOneAndUpdate(
      { user: req.user.userId, itemType: 'custom' },
      {
        $set: {
          user: req.user.userId,
          itemType: 'custom',
          quantity,
          description: String(description || '').trim(),
          customTotal: total,
          imagePath,
          imageUrl,
          customItems: customCartItems,
        },
      },
      { upsert: true, new: true }
    );

    res.status(201).json(toCartItemResponse(cartItem));
  } catch (error) {
    res.status(500).json({ message: 'Custom cart update failed' });
  }
});

app.patch('/cart/:productId', authRequired, async (req, res) => {
  try {
    const quantity = Number(req.body.quantity);
    if (!Number.isFinite(quantity)) return res.status(400).json({ message: 'Quantity required' });
    const isCustom = req.body.itemType === 'custom' || req.query.itemType === 'custom';
    const filter = isCustom
      ? { _id: req.params.productId, user: req.user.userId, itemType: 'custom' }
      : { user: req.user.userId, product: req.params.productId };
    if (quantity <= 0) {
      await CartItem.findOneAndDelete(filter);
      return res.json({ message: 'Removed' });
    }
    const item = await CartItem.findOneAndUpdate(
      filter,
      { $set: { quantity } },
      { new: true }
    );
    if (!item) return res.status(404).json({ message: 'Not found' });
    res.json({ productId: item.product, quantity: item.quantity });
  } catch (error) {
    res.status(500).json({ message: 'Cart update failed' });
  }
});

app.delete('/cart/:productId', authRequired, async (req, res) => {
  const isCustom = req.query.itemType === 'custom';
  const filter = isCustom
    ? { _id: req.params.productId, user: req.user.userId, itemType: 'custom' }
    : { user: req.user.userId, product: req.params.productId };
  await CartItem.findOneAndDelete(filter);
  res.json({ message: 'Removed' });
});

app.delete('/cart', authRequired, async (req, res) => {
  await CartItem.deleteMany({ user: req.user.userId });
  res.json({ message: 'Cleared' });
});

app.get('/notifications', authRequired, async (req, res) => {
  const notifications = await Notification.find({ user: req.user.userId }).sort({ createdAt: -1 });
  res.json(notifications);
});

app.post('/notifications', authRequired, async (req, res) => {
  try {
    const { title, message, type } = req.body;
    if (!title) return res.status(400).json({ message: 'Title required' });
    const notification = await Notification.create({
      user: req.user.userId,
      title,
      message: message || '',
      type: type || 'system',
    });
    res.status(201).json(notification);
  } catch (error) {
    res.status(500).json({ message: 'Notification failed' });
  }
});

app.patch('/notifications/:id', authRequired, async (req, res) => {
  const notification = await Notification.findOneAndUpdate(
    { _id: req.params.id, user: req.user.userId },
    { $set: { read: true } },
    { new: true }
  );
  if (!notification) return res.status(404).json({ message: 'Not found' });
  res.json(notification);
});

app.get('/admins', authRequired, requireRole('super_admin'), async (req, res) => {
  const admins = await AdminEmail.find().sort({ createdAt: -1 });
  res.json(admins);
});

app.post('/admins', authRequired, requireRole('super_admin'), async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ message: 'Email required' });
    const normalized = email.toLowerCase();
    const requestedRole = req.body.role === 'worker' ? 'worker' : 'admin';
    const admin = await AdminEmail.findOneAndUpdate(
      { email: normalized },
      {
        $set: {
          role: requestedRole,
          createdBy: req.user.userId,
        },
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );
    const targetRole = normalized === SUPER_ADMIN_EMAIL.toLowerCase()
      ? 'super_admin'
      : requestedRole;
    await User.updateOne({ email: normalized }, { $set: { role: targetRole } });
    res.status(201).json(admin);
  } catch (error) {
    res.status(500).json({ message: 'Admin add failed' });
  }
});

app.delete('/admins/:email', authRequired, requireRole('super_admin'), async (req, res) => {
  const email = req.params.email.toLowerCase();
  await AdminEmail.findOneAndDelete({ email });
  if (email !== SUPER_ADMIN_EMAIL.toLowerCase()) {
    await User.updateOne({ email }, { $set: { role: 'user' } });
  }
  res.json({ message: 'Removed' });
});

app.post('/ai/chat', authRequired, async (req, res) => {
  try {
    const { sessionId } = req.body;
    const message = sanitizeChatText(req.body?.message);
    if (!message) return res.status(400).json({ message: 'Message required' });
    if (!req.user?.userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }
    const apiKey = GEMINI_API_KEY;
    if (!apiKey) return res.status(500).json({ message: 'Gemini key missing' });

    let session = null;
    if (sessionId) {
      session = await ChatSession.findOne({ _id: sessionId, user: req.user.userId });
      if (!session) return res.status(404).json({ message: 'Chat not found' });
    }
    if (!session) {
      session = await ChatSession.create({
        user: req.user.userId,
        title: 'Жаңа чат',
        lastMessageAt: new Date(),
      });
    }

    const notFlowerReply =
      'Кешіріңіз, мен тек гүлдер мен букеттер туралы көмектесе аламын.';
    const genAI = new GoogleGenerativeAI(apiKey);

    const shouldAnswer = await shouldAnswerFlowerShopRequest({ message, genAI });
    if (!shouldAnswer) {
      const safeReply = stripMarkdown(notFlowerReply);
      await ChatMessage.create({
        session: session._id,
        role: 'assistant',
        message: safeReply,
      });
      session.lastMessageAt = new Date();
      session.lastMessagePreview = '';
      await session.save();
      await pruneChatMessages(session._id);
      return res.json({ message: safeReply, sessionId: session._id });
    }

    await ChatMessage.create({ session: session._id, role: 'user', message });

    const recent = await ChatMessage.find({ session: session._id })
      .sort({ createdAt: -1 })
      .limit(CHAT_CONTEXT_MESSAGES);
    const history = recent.reverse();
    const historyText = history
      .map((entry) => `${entry.role === 'user' ? 'User' : 'Assistant'}: ${entry.message}`)
      .join('\n');

    const suggestions = await buildProductSuggestions(message, 5);
    const suggestionText =
      suggestions.length > 0
        ? suggestions.map((item) => `${item.name} (${item.price} ₸)`).join('; ')
        : 'none';

    const modelName = GEMINI_MODEL;
    const model = genAI.getGenerativeModel({ model: modelName });
    const prompt = [
      'You are a helpful flower shop assistant for Gul alem.',
      'Answer only about flowers, bouquets, gifts, and flower shop services.',
      'Respond in Kazakh or Russian matching the user.',
      'Do not use markdown or symbols like *, _, `, #, or bullet lists.',
      'Keep the reply concise and friendly.',
      historyText ? `Conversation:\n${historyText}` : null,
      `Products: ${suggestionText}`,
      `User: ${message}`,
      'Assistant:',
    ]
      .filter(Boolean)
      .join('\n');

    const result = await model.generateContent(prompt);
    const rawText = result?.response?.text() || 'No response';
    const text = stripMarkdown(rawText);
    let reply = sanitizeChatText(text || stripMarkdown('Кешіріңіз, жауап табылмады.'));
    const suggestionProductIds = suggestions.map((item) => item.id).filter(Boolean);

    await ChatMessage.create({
      session: session._id,
      role: 'assistant',
      message: reply,
      productSuggestions: suggestionProductIds,
    });
    session.lastMessageAt = new Date();
    session.lastMessagePreview = '';
    await session.save();
    await pruneChatMessages(session._id);

    res.json({ message: reply, sessionId: session._id, products: suggestions });
  } catch (error) {
    console.error('Gemini error:', error);
    const status = error?.status || error?.response?.status || 500;
    const message =
      error?.message ||
      error?.response?.data?.error?.message ||
      'Gemini request failed';
    if (status === 404) {
      try {
        const apiKey = GEMINI_API_KEY;
        const { models, error: listError } = await fetchGeminiModels(apiKey);
        const available = models.filter((model) =>
          (model.supportedMethods || []).includes('generateContent')
        );
        return res.status(status).json({
          message,
          availableModels: available.map((model) => model.name),
          listModelsError: listError,
        });
      } catch (listErr) {
        return res.status(status).json({ message });
      }
    }
    res.status(status).json({ message });
  }
});

app.get('/ai/chats', authRequired, async (req, res) => {
  const sessions = await ChatSession.find({ user: req.user.userId }).sort({
    lastMessageAt: -1,
    createdAt: -1,
  });
  res.json(
    sessions.map((session) => ({
      id: session._id,
      title: session.title,
      lastMessageAt: session.lastMessageAt,
      lastMessagePreview: session.lastMessagePreview || '',
    }))
  );
});

app.post('/ai/chats', authRequired, async (req, res) => {
  const session = await ChatSession.create({
    user: req.user.userId,
    title: 'Жаңа чат',
    lastMessageAt: new Date(),
  });
  res.status(201).json({
    id: session._id,
    title: session.title,
    lastMessageAt: session.lastMessageAt,
    lastMessagePreview: session.lastMessagePreview || '',
  });
});

app.get('/ai/chats/:id', authRequired, async (req, res) => {
  const session = await ChatSession.findOne({ _id: req.params.id, user: req.user.userId });
  if (!session) return res.status(404).json({ message: 'Chat not found' });
  const messages = await ChatMessage.find({ session: session._id })
    .sort({ createdAt: -1 })
    .limit(CHAT_MAX_STORED_MESSAGES)
    .populate('productSuggestions');
  messages.reverse();
  res.json({
    session: {
      id: session._id,
      title: session.title,
      lastMessageAt: session.lastMessageAt,
      lastMessagePreview: session.lastMessagePreview || '',
    },
    messages: messages.map((msg) => ({
      id: msg._id,
      role: msg.role,
      message: msg.message,
      products: (msg.productSuggestions || [])
        .filter((product) => product && product._id)
        .map((product) => toProductResponse(product)),
      createdAt: msg.createdAt,
    })),
  });
});

app.delete('/ai/chats/:id', authRequired, async (req, res) => {
  const session = await ChatSession.findOneAndDelete({
    _id: req.params.id,
    user: req.user.userId,
  });
  if (!session) return res.status(404).json({ message: 'Chat not found' });
  await ChatMessage.deleteMany({ session: session._id });
  res.json({ message: 'Deleted' });
});

const seedDefaults = async () => {
  const categoryCount = await Category.countDocuments();
  if (categoryCount === 0) {
    const categories = [
      { name: 'Гүлдер', imagePath: 'assets/cat_1.png', order: 1 },
      { name: 'Букеттер', imagePath: 'assets/cat_2.png', order: 2 },
      { name: 'Раушан', imagePath: 'assets/cat_3.png', order: 3 },
      { name: 'Қызғалдақ', imagePath: 'assets/cat_4.png', order: 4 },
      { name: 'Аралас букеттер', imagePath: 'assets/cat_5.png', order: 5 },
      { name: 'Тәтті букеттер', imagePath: 'assets/cat_6.png', order: 6 },
      { name: 'Сыйлық', imagePath: 'assets/cat_7.png', order: 7 },
      { name: 'Жеуге жарамды', imagePath: 'assets/cat_8.png', order: 8 },
      { name: 'Шарлар', imagePath: 'assets/cat_9.png', order: 9 },
      { name: 'DIY', imagePath: 'assets/cat_10.png', order: 10 },
    ];
    await Category.insertMany(categories);
  }

  await Category.findOneAndUpdate(
    { imagePath: 'assets/cat_10.png' },
    {
      $setOnInsert: {
        name: 'DIY',
        imagePath: 'assets/cat_10.png',
        order: 10,
      },
    },
    { upsert: true }
  );

  const productCount = await Product.countDocuments();
  if (productCount === 0) {
    const categories = await Category.find().sort({ order: 1 });
    const getCategory = (index) => categories[Math.min(index, categories.length - 1)]?._id;

    const products = [
      {
        name: 'Қызыл раушан',
        price: 16990,
        imagePath: 'assets/flower_rose_red.png',
        flowerType: 'rose',
        category: getCategory(2),
        inStock: true,
        stockCount: 12,
      },
      {
        name: 'Ақ раушан',
        price: 18990,
        imagePath: 'assets/flower_rose_white.png',
        flowerType: 'rose',
        category: getCategory(2),
        inStock: true,
        stockCount: 10,
      },
      {
        name: 'Қызғылт пион',
        price: 21990,
        imagePath: 'assets/flower_peony_pink.png',
        flowerType: 'peony',
        category: getCategory(0),
        inStock: true,
        stockCount: 8,
      },
      {
        name: 'Ақ пион',
        price: 20990,
        imagePath: 'assets/flower_peony_white.png',
        flowerType: 'peony',
        category: getCategory(0),
        inStock: true,
        stockCount: 6,
      },
      {
        name: 'Лилия',
        price: 25990,
        imagePath: 'assets/flower_lily.png',
        flowerType: 'lily',
        category: getCategory(0),
        inStock: true,
        stockCount: 5,
      },
      {
        name: 'Гортензия',
        price: 23990,
        imagePath: 'assets/flower_hydrangea.png',
        flowerType: 'hydrangea',
        category: getCategory(0),
        inStock: true,
        stockCount: 7,
      },
      {
        name: 'Хризантема',
        price: 15990,
        imagePath: 'assets/flower_chrysanthemum.png',
        flowerType: 'chrysanthemum',
        category: getCategory(0),
        inStock: true,
        stockCount: 9,
      },
      {
        name: 'Түймедақ хризантема',
        price: 16990,
        imagePath: 'assets/flower_daisylike_chrysanthemum.png',
        flowerType: 'chrysanthemum',
        category: getCategory(0),
        inStock: true,
        stockCount: 9,
      },
      {
        name: 'Аралас букет',
        price: 27990,
        imagePath: 'assets/flower_mixed.png',
        flowerType: 'mixed',
        category: getCategory(1),
        inStock: true,
        stockCount: 4,
      },
      {
        name: 'Тәтті букеті',
        price: 31990,
        imagePath: 'assets/product_candy_bouquet.png',
        flowerType: 'bouquet',
        category: getCategory(7),
        inStock: true,
        stockCount: 3,
      },
      {
        name: 'Жеміс букеті',
        price: 29990,
        imagePath: 'assets/product_fruit_bouquet.png',
        flowerType: 'bouquet',
        category: getCategory(7),
        inStock: true,
        stockCount: 5,
        popular: true,
      },
      {
        name: 'Ақша букеті',
        price: 55990,
        imagePath: 'assets/product_money_bouquet.png',
        flowerType: 'bouquet',
        category: getCategory(6),
        inStock: true,
        stockCount: 2,
      },
      {
        name: 'Аю букеті',
        price: 35990,
        imagePath: 'assets/product_bear_bouquet.png',
        flowerType: 'bouquet',
        category: getCategory(6),
        inStock: true,
        stockCount: 3,
        popular: true,
      },
      {
        name: 'Гүл қолшатырлары',
        price: 42990,
        imagePath: 'assets/product_flower_umbrella1.png',
        flowerType: 'umbrella',
        category: getCategory(8),
        inStock: true,
        stockCount: 2,
        popular: true,
      },
      {
        name: 'Гүл қолшатырлары (2)',
        price: 45990,
        imagePath: 'assets/product_flower_umbrella2.png',
        flowerType: 'umbrella',
        category: getCategory(8),
        inStock: true,
        stockCount: 1,
        popular: true,
      },
      {
        name: 'Қызғалдақ (қызғылт)',
        price: 14990,
        imagePath: 'assets/flower_tulip_pink.png',
        flowerType: 'tulip',
        category: getCategory(3),
        inStock: true,
        stockCount: 14,
      },
      {
        name: 'Қызғалдақ (сары)',
        price: 14990,
        imagePath: 'assets/flower_tulip_yellow.png',
        flowerType: 'tulip',
        category: getCategory(3),
        inStock: true,
        stockCount: 14,
      },
      {
        name: 'Шарлар (мерекелік)',
        price: 12990,
        imagePath: 'assets/product_balloons_birthday.png',
        flowerType: 'balloon',
        category: getCategory(8),
        inStock: true,
        stockCount: 10,
      },
      {
        name: 'Шарлар (классикалық)',
        price: 9990,
        imagePath: 'assets/product_balloons_standart.png',
        flowerType: 'balloon',
        category: getCategory(8),
        inStock: true,
        stockCount: 12,
      },
    ];

    await Product.insertMany(products);
  }

  const categoriesForMapping = await Category.find().sort({ order: 1 });
  const getCategoryByOrder = (order) =>
    categoriesForMapping.find((category) => category.order === order)?._id;

  const ensureProduct = async ({
    name,
    price,
    imagePath,
    flowerType,
    order,
    inStock = true,
    stockCount = 10,
  }) => {
    const categoryId = getCategoryByOrder(order);
    if (!categoryId) return;
    await Product.findOneAndUpdate(
      { imagePath },
      {
        $setOnInsert: {
          name,
          price,
          imagePath,
          flowerType,
          category: categoryId,
          inStock,
          stockCount,
        },
      },
      { upsert: true }
    );
  };

  await Promise.all([
    ensureProduct({
      name: 'Түймедақ хризантема',
      price: 16990,
      imagePath: 'assets/flower_daisylike_chrysanthemum.png',
      flowerType: 'chrysanthemum',
      order: 1,
      stockCount: 9,
    }),
    ensureProduct({
      name: 'Қызғалдақ (қызғылт)',
      price: 14990,
      imagePath: 'assets/flower_tulip_pink.png',
      flowerType: 'tulip',
      order: 4,
      stockCount: 14,
    }),
    ensureProduct({
      name: 'Қызғалдақ (сары)',
      price: 14990,
      imagePath: 'assets/flower_tulip_yellow.png',
      flowerType: 'tulip',
      order: 4,
      stockCount: 14,
    }),
    ensureProduct({
      name: 'Шарлар (мерекелік)',
      price: 12990,
      imagePath: 'assets/product_balloons_birthday.png',
      flowerType: 'balloon',
      order: 9,
      stockCount: 10,
    }),
    ensureProduct({
      name: 'Шарлар (классикалық)',
      price: 9990,
      imagePath: 'assets/product_balloons_standart.png',
      flowerType: 'balloon',
      order: 9,
      stockCount: 12,
    }),
  ]);

  const updateByImage = async (order, imagePaths) => {
    const categoryId = getCategoryByOrder(order);
    if (!categoryId || imagePaths.length === 0) return;
    await Product.updateMany(
      { imagePath: { $in: imagePaths } },
      { $set: { category: categoryId } }
    );
  }
  await Promise.all([
    updateByImage(1, [
      'assets/flower_chrysanthemum.png',
      'assets/flower_daisylike_chrysanthemum.png',
      'assets/flower_hydrangea.png',
      'assets/flower_lily.png',
      'assets/flower_peony_pink.png',
      'assets/flower_peony_white.png',
    ]),
    updateByImage(2, ['assets/flower_mixed.png']),
    updateByImage(3, ['assets/flower_rose_red.png', 'assets/flower_rose_white.png']),
    updateByImage(4, ['assets/flower_tulip_pink.png', 'assets/flower_tulip_yellow.png']),
    updateByImage(7, ['assets/product_money_bouquet.png', 'assets/product_bear_bouquet.png']),
    updateByImage(8, ['assets/product_candy_bouquet.png', 'assets/product_fruit_bouquet.png']),
    updateByImage(9, [
      'assets/product_balloons_birthday.png',
      'assets/product_balloons_standart.png',
      'assets/product_flower_umbrella1.png',
      'assets/product_flower_umbrella2.png',
    ]),
  ]);

  const ensureCustomItem = async ({
    name,
    group,
    price,
    stockCount,
    order,
    imagePath = '',
  }) => {
    const imageUrl = isExternalImageUrl(imagePath) ? imagePath : '';
    await CustomBouquetItem.findOneAndUpdate(
      { name, group },
      {
        ...(imagePath ? { $set: { imagePath, imageUrl } } : {}),
        ...(group === 'flowers' ? { $max: { stockCount } } : {}),
        $setOnInsert: {
          name,
          group,
          price,
          ...(group !== 'flowers' ? { stockCount } : {}),
          inStock: stockCount > 0,
          order,
        },
      },
      { upsert: true }
    );
  };

  await Promise.all([
    ensureCustomItem({
      name: 'Қызыл раушан',
      group: 'flowers',
      price: 1200,
      stockCount: MAX_CUSTOM_FLOWERS,
      order: 1,
      imagePath: 'assets/custom_bouquet/custom_bouquet_red_rose.png',
    }),
    ensureCustomItem({
      name: 'Ақ раушан',
      group: 'flowers',
      price: 1300,
      stockCount: MAX_CUSTOM_FLOWERS,
      order: 2,
      imagePath: 'assets/custom_bouquet/custom_bouquet_white_rose.png',
    }),
    ensureCustomItem({
      name: 'Қызғалдақ',
      group: 'flowers',
      price: 900,
      stockCount: MAX_CUSTOM_FLOWERS,
      order: 3,
      imagePath: 'assets/custom_bouquet/custom_bouquet_tulip.png',
    }),
    ensureCustomItem({
      name: 'Гортензия',
      group: 'flowers',
      price: 2500,
      stockCount: MAX_CUSTOM_FLOWERS,
      order: 4,
      imagePath: 'assets/custom_bouquet/custom_bouquet_hydrangea.png',
    }),
    ensureCustomItem({
      name: 'Крафт қағазы',
      group: 'wrapping',
      price: 1500,
      stockCount: 30,
      order: 1,
      imagePath: 'assets/custom_bouquet/custom_bouquet_kraft_wrap.png',
    }),
    ensureCustomItem({
      name: 'Атлас таспа',
      group: 'wrapping',
      price: 700,
      stockCount: 45,
      order: 2,
      imagePath: 'assets/custom_bouquet/custom_bouquet_satin_ribbon.png',
    }),
    ensureCustomItem({
      name: 'Премиум қорап',
      group: 'wrapping',
      price: 3500,
      stockCount: 12,
      order: 3,
      imagePath: 'assets/custom_bouquet/custom_bouquet_premium_box.png',
    }),
    ensureCustomItem({
      name: 'Жасыл жапырақ',
      group: 'extras',
      price: 600,
      stockCount: 60,
      order: 1,
      imagePath: 'assets/custom_bouquet/custom_bouquet_green_leaf.png',
    }),
    ensureCustomItem({
      name: 'Ашықхат',
      group: 'extras',
      price: 500,
      stockCount: 80,
      order: 2,
      imagePath: 'assets/custom_bouquet/custom_bouquet_card.png',
    }),
    ensureCustomItem({
      name: 'Шар',
      group: 'extras',
      price: 1200,
      stockCount: 25,
      order: 3,
      imagePath: 'assets/custom_bouquet/custom_bouquet_balloon.png',
    }),
  ]);

  const applyAutoFilters = async () => {
    const products = await Product.find();
    const updates = products
      .map((product) => {
        const hasOccasion =
          Array.isArray(product.occasionTags) && product.occasionTags.length > 0;
        const hasRecipient =
          Array.isArray(product.recipientTags) && product.recipientTags.length > 0;
        if (hasOccasion && hasRecipient) return null;
        const tags = resolveProductTags({ name: product.name });
        return {
          updateOne: {
            filter: { _id: product._id },
            update: {
              $set: {
                occasionTags: tags.occasionTags,
                recipientTags: tags.recipientTags,
              },
            },
          },
        };
      })
      .filter((item) => item);
    if (updates.length > 0) {
      await Product.bulkWrite(updates);
    }
  };

  await applyAutoFilters();
};

mongoose.connection.once('open', () => {
  seedDefaults()
    .then(() => scrubStoredPaymentSecrets())
    .catch((err) => console.error('Startup maintenance failed:', err));
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
