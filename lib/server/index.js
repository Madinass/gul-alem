const express = require('express');
require('dotenv').config();
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const crypto = require('crypto');
const nodemailer = require('nodemailer');
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
} = require('./utils');

const app = express();
app.use(express.json({ limit: '1mb' }));
app.use(cors());

const PORT = process.env.PORT || 3000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/gul_alem_db';
const JWT_SECRET = process.env.JWT_SECRET || 'gul-alem-dev-secret';
const SUPER_ADMIN_EMAIL = 'madinaamandykovna08@gmail.com';
const PAYMENT_ENC_KEY = process.env.PAYMENT_ENC_KEY || '';
const GMAIL_USER = process.env.GMAIL_USER || '';
const GMAIL_APP_PASSWORD = process.env.GMAIL_APP_PASSWORD || '';
const GMAIL_FROM = process.env.GMAIL_FROM || GMAIL_USER;
const RESET_CODE_TTL_MIN = Number.parseInt(process.env.RESET_CODE_TTL_MIN || '10', 10);
const RESET_TOKEN_TTL_MIN = Number.parseInt(process.env.RESET_TOKEN_TTL_MIN || '30', 10);

mongoose
  .connect(MONGO_URI)
  .then(() => console.log('MongoDB connected'))
  .catch((err) => console.error('MongoDB connection error:', err));

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    phone: { type: String, required: true, unique: true },
    email: { type: String, required: true, unique: true, lowercase: true },
    role: { type: String, enum: ['user', 'admin', 'super_admin'], default: 'user' },
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
    imagePath: { type: String, required: true },
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

const orderSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    items: [
      {
        productId: { type: mongoose.Schema.Types.ObjectId, ref: 'Product' },
        name: String,
        imagePath: String,
        price: Number,
        quantity: Number,
      },
    ],
    total: { type: Number, default: 0 },
    status: {
      type: String,
      enum: ['pending', 'processing', 'completed', 'cancelled'],
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
    cardNumber: { type: encryptedFieldSchema, required: true },
    expMonth: { type: encryptedFieldSchema, required: true },
    expYear: { type: encryptedFieldSchema, required: true },
    cvv: { type: encryptedFieldSchema, required: true },
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
    product: { type: mongoose.Schema.Types.ObjectId, ref: 'Product', required: true },
    quantity: { type: Number, default: 1 },
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

const chatMessageSchema = new mongoose.Schema(
  {
    session: { type: mongoose.Schema.Types.ObjectId, ref: 'ChatSession', required: true },
    role: { type: String, enum: ['user', 'assistant'], required: true },
    message: { type: String, required: true },
  },
  { timestamps: true }
);

const User = mongoose.model('User', userSchema);
const AdminEmail = mongoose.model('AdminEmail', adminEmailSchema);
const Category = mongoose.model('Category', categorySchema);
const Product = mongoose.model('Product', productSchema);
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
  if (lower === SUPER_ADMIN_EMAIL.toLowerCase()) return 'super_admin';
  const admin = await AdminEmail.findOne({ email: lower });
  return admin ? 'admin' : 'user';
};

const authRequired = (req, res, next) => {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ message: 'Unauthorized' });
  try {
    req.user = jwt.verify(token, JWT_SECRET);
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

const toProductResponse = (product) => ({
  id: product._id,
  name: product.name,
  price: product.price,
  imagePath: product.imagePath,
  flowerType: product.flowerType,
  categoryId: product.category,
  inStock: product.inStock,
  stockCount: product.stockCount,
  popular: product.popular,
  occasionTags: product.occasionTags || [],
  recipientTags: product.recipientTags || [],
});

const toCategoryResponse = (category) => ({
  id: category._id,
  name: category.name,
  imagePath: category.imagePath,
  order: category.order,
});

const createToken = (userId, email, role) =>
  jwt.sign({ userId, email, role }, JWT_SECRET, { expiresIn: '7d' });

const getMailTransporter = () => {
  if (!GMAIL_USER || !GMAIL_APP_PASSWORD) {
    throw new Error('GMAIL_USER or GMAIL_APP_PASSWORD missing');
  }
  return nodemailer.createTransport({
    service: 'gmail',
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

app.get('/', (req, res) => {
  res.json({ status: 'ok' });
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
      flowerType,
      categoryId,
      inStock,
      stockCount,
      popular,
      occasionTags,
      recipientTags,
    } = req.body;
    if (!name || price == null || !imagePath || !flowerType) {
      return res.status(400).json({ message: 'Missing fields' });
    }
    const tags = resolveProductTags({ occasionTags, recipientTags, name });
    const product = await Product.create({
      name,
      price,
      imagePath,
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
    const { items } = req.body;
    if (!Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ message: 'Empty order' });
    }
    const total = items.reduce((sum, item) => sum + (item.price || 0) * (item.quantity || 1), 0);
    const order = await Order.create({
      user: req.user.userId,
      items,
      total,
    });
    await CartItem.deleteMany({ user: req.user.userId });
    await Notification.create({
      user: req.user.userId,
      title: 'Тапсырыс жасалды',
      message: `Тапсырыс №${order._id} қабылданды`,
      type: 'order',
    });
    const adminUsers = await User.find({
      role: { $in: ['admin', 'super_admin'] },
    }).select('_id email');
    if (adminUsers.length > 0) {
      const itemCount = items.reduce((sum, item) => sum + (item.quantity || 1), 0);
      await Notification.insertMany(
        adminUsers.map((admin) => ({
          user: admin._id,
          title: 'Жаңа тапсырыс',
          message: `Тапсырыс №${order._id} | Клиент: ${req.user.email || ''} | Саны: ${itemCount} | Жалпы: ${total}`,
          type: 'order',
        }))
      );
    }
    res.status(201).json(order);
  } catch (error) {
    res.status(500).json({ message: 'Order failed' });
  }
});

app.get('/orders', authRequired, requireRole('admin', 'super_admin'), async (req, res) => {
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
    const response = methods.map((method) => {
      let last4 = '';
      try {
        const cardNumber = decryptField(method.cardNumber);
        last4 = cardNumber.slice(-4);
      } catch (error) {
        last4 = '';
      }
      return { id: method._id, last4 };
    });
    res.json(response);
  } catch (error) {
    res.status(500).json({ message: 'Failed to load payment methods' });
  }
});

app.get('/payment-methods/:id', authRequired, async (req, res) => {
  try {
    const method = await PaymentMethod.findOne({ _id: req.params.id, user: req.user.userId });
    if (!method) return res.status(404).json({ message: 'Not found' });
    res.json({
      id: method._id,
      cardholderName: decryptField(method.cardholderName),
      cardNumber: decryptField(method.cardNumber),
      expMonth: decryptField(method.expMonth),
      expYear: decryptField(method.expYear),
      cvv: decryptField(method.cvv),
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to load payment method' });
  }
});

app.post('/payment-methods', authRequired, async (req, res) => {
  try {
    const { cardholderName, cardNumber, expMonth, expYear, cvv } = req.body;
    if (!cardholderName || !cardNumber || !expMonth || !expYear || !cvv) {
      return res.status(400).json({ message: 'Missing fields' });
    }
    const method = await PaymentMethod.create({
      user: req.user.userId,
      cardholderName: encryptField(cardholderName),
      cardNumber: encryptField(cardNumber),
      expMonth: encryptField(expMonth),
      expYear: encryptField(expYear),
      cvv: encryptField(cvv),
    });
    const last4 = String(cardNumber).slice(-4);
    res.status(201).json({ id: method._id, last4 });
  } catch (error) {
    res.status(500).json({ message: 'Failed to save payment method' });
  }
});

app.put('/payment-methods/:id', authRequired, async (req, res) => {
  try {
    const { cardholderName, cardNumber, expMonth, expYear, cvv } = req.body;
    if (!cardholderName || !cardNumber || !expMonth || !expYear || !cvv) {
      return res.status(400).json({ message: 'Missing fields' });
    }
    const method = await PaymentMethod.findOneAndUpdate(
      { _id: req.params.id, user: req.user.userId },
      {
        cardholderName: encryptField(cardholderName),
        cardNumber: encryptField(cardNumber),
        expMonth: encryptField(expMonth),
        expYear: encryptField(expYear),
        cvv: encryptField(cvv),
      },
      { new: true }
    );
    if (!method) return res.status(404).json({ message: 'Not found' });
    const last4 = String(cardNumber).slice(-4);
    res.json({ id: method._id, last4 });
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

app.patch('/orders/:id', authRequired, requireRole('admin', 'super_admin'), async (req, res) => {
  const updates = { status: req.body.status };
  const order = await Order.findByIdAndUpdate(req.params.id, updates, { new: true });
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
    .filter((item) => item.product)
    .map((item) => ({
      product: toProductResponse(item.product),
      quantity: item.quantity,
    }));
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

app.patch('/cart/:productId', authRequired, async (req, res) => {
  try {
    const quantity = Number(req.body.quantity);
    if (!Number.isFinite(quantity)) return res.status(400).json({ message: 'Quantity required' });
    if (quantity <= 0) {
      await CartItem.findOneAndDelete({ user: req.user.userId, product: req.params.productId });
      return res.json({ message: 'Removed' });
    }
    const item = await CartItem.findOneAndUpdate(
      { user: req.user.userId, product: req.params.productId },
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
  await CartItem.findOneAndDelete({ user: req.user.userId, product: req.params.productId });
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
    const admin = await AdminEmail.create({ email: normalized, createdBy: req.user.userId });
    const targetRole =
      normalized === SUPER_ADMIN_EMAIL.toLowerCase() ? 'super_admin' : 'admin';
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
    const { message, sessionId } = req.body;
    if (!message) return res.status(400).json({ message: 'Message required' });
    if (!req.user?.userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) return res.status(500).json({ message: 'Gemini key missing' });

    let session = null;
    if (sessionId) {
      session = await ChatSession.findOne({ _id: sessionId, user: req.user.userId });
      if (!session) return res.status(404).json({ message: 'Chat not found' });
    }
    if (!session) {
      session = await ChatSession.create({
        user: req.user.userId,
        title: buildChatTitle(message),
        lastMessageAt: new Date(),
      });
    }

    await ChatMessage.create({ session: session._id, role: 'user', message });

    const notFlowerReply =
      'Кешіріңіз, мен тек гүлдер мен букеттер туралы көмектесе аламын.';

    if (!isFlowerTopic(message)) {
      const safeReply = stripMarkdown(notFlowerReply);
      await ChatMessage.create({
        session: session._id,
        role: 'assistant',
        message: safeReply,
      });
      session.lastMessageAt = new Date();
      session.lastMessagePreview = safeReply.slice(0, 120);
      await session.save();
      return res.json({ message: safeReply, sessionId: session._id });
    }

    const recent = await ChatMessage.find({ session: session._id })
      .sort({ createdAt: -1 })
      .limit(6);
    const history = recent.reverse();
    const historyText = history
      .map((entry) => `${entry.role === 'user' ? 'User' : 'Assistant'}: ${entry.message}`)
      .join('\n');

    const suggestions = await buildProductSuggestions(message, 5);
    const suggestionText =
      suggestions.length > 0
        ? suggestions.map((item) => `${item.name} (${item.price} ₸)`).join('; ')
        : 'none';

    const genAI = new GoogleGenerativeAI(apiKey);
    const modelName = process.env.GEMINI_MODEL || 'gemini-1.5-flash';
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
    let reply = text || stripMarkdown('Кешіріңіз, жауап табылмады.');
    if (suggestions.length > 0) {
      const suggestionLine = `Ұсыныстар: ${suggestionText}.`;
      const sampleName = suggestions[0]?.name?.toLowerCase() || '';
      if (!sampleName || !reply.toLowerCase().includes(sampleName)) {
        reply = `${reply} ${suggestionLine}`.trim();
      }
    }

    await ChatMessage.create({
      session: session._id,
      role: 'assistant',
      message: reply,
    });
    session.lastMessageAt = new Date();
    session.lastMessagePreview = reply.slice(0, 120);
    if (!session.title || session.title === 'Жаңа чат') {
      session.title = buildChatTitle(message);
    }
    await session.save();

    res.json({ message: reply, sessionId: session._id });
  } catch (error) {
    console.error('Gemini error:', error);
    const status = error?.status || error?.response?.status || 500;
    const message =
      error?.message ||
      error?.response?.data?.error?.message ||
      'Gemini request failed';
    if (status === 404) {
      try {
        const apiKey = process.env.GEMINI_API_KEY;
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
  const { title } = req.body || {};
  const session = await ChatSession.create({
    user: req.user.userId,
    title: title ? String(title).trim() : 'Жаңа чат',
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
  const messages = await ChatMessage.find({ session: session._id }).sort({ createdAt: 1 });
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
      createdAt: msg.createdAt,
    })),
  });
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
    ];
    await Category.insertMany(categories);
  }

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
  seedDefaults().catch((err) => console.error('Seed failed:', err));
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
