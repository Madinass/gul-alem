const express = require('express');
require('dotenv').config();
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const app = express();
app.use(express.json({ limit: '1mb' }));
app.use(cors());

const PORT = process.env.PORT || 3000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/gul_alem_db';
const JWT_SECRET = process.env.JWT_SECRET || 'gul-alem-dev-secret';
const SUPER_ADMIN_EMAIL = 'madinaamandykovna08@gmail.com';

mongoose
  .connect(MONGO_URI)
  .then(() => console.log('MongoDB connected'))
  .catch((err) => console.error('MongoDB connection error:', err));

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    phone: { type: String, required: true, unique: true },
    email: { type: String, required: true, unique: true, lowercase: true },
    passwordHash: { type: String, required: true },
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

const User = mongoose.model('User', userSchema);
const AdminEmail = mongoose.model('AdminEmail', adminEmailSchema);
const Category = mongoose.model('Category', categorySchema);
const Product = mongoose.model('Product', productSchema);
const Order = mongoose.model('Order', orderSchema);

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
});

const toCategoryResponse = (category) => ({
  id: category._id,
  name: category.name,
  imagePath: category.imagePath,
  order: category.order,
});

const createToken = (userId, email, role) =>
  jwt.sign({ userId, email, role }, JWT_SECRET, { expiresIn: '7d' });

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
    const user = await User.create({
      name,
      phone,
      email: email.toLowerCase(),
      passwordHash,
    });

    const role = await getRoleForEmail(user.email);
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

app.get('/categories', async (req, res) => {
  const categories = await Category.find().sort({ order: 1 });
  res.json(categories.map(toCategoryResponse));
});

app.get('/products', async (req, res) => {
  const filter = {};
  if (req.query.categoryId) filter.category = req.query.categoryId;
  if (req.query.popular === 'true') filter.popular = true;
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
    const { name, price, imagePath, flowerType, categoryId, inStock, stockCount, popular } = req.body;
    if (!name || price == null || !imagePath || !flowerType) {
      return res.status(400).json({ message: 'Missing fields' });
    }
    const product = await Product.create({
      name,
      price,
      imagePath,
      flowerType,
      category: categoryId || null,
      inStock: inStock !== undefined ? inStock : true,
      stockCount: stockCount || 0,
      popular: !!popular,
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

app.patch('/orders/:id', authRequired, requireRole('admin', 'super_admin'), async (req, res) => {
  const updates = { status: req.body.status };
  const order = await Order.findByIdAndUpdate(req.params.id, updates, { new: true });
  if (!order) return res.status(404).json({ message: 'Not found' });
  res.json(order);
});

app.get('/admins', authRequired, requireRole('super_admin'), async (req, res) => {
  const admins = await AdminEmail.find().sort({ createdAt: -1 });
  res.json(admins);
});

app.post('/admins', authRequired, requireRole('super_admin'), async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ message: 'Email required' });
    const admin = await AdminEmail.create({ email: email.toLowerCase(), createdBy: req.user.userId });
    res.status(201).json(admin);
  } catch (error) {
    res.status(500).json({ message: 'Admin add failed' });
  }
});

app.delete('/admins/:email', authRequired, requireRole('super_admin'), async (req, res) => {
  const email = req.params.email.toLowerCase();
  await AdminEmail.findOneAndDelete({ email });
  res.json({ message: 'Removed' });
});

app.post('/ai/chat', async (req, res) => {
  try {
    const { message } = req.body;
    if (!message) return res.status(400).json({ message: 'Message required' });
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) return res.status(500).json({ message: 'Gemini key missing' });

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-pro' });
    const result = await model.generateContent(
      `You are a helpful flower shop assistant. User question: ${message}`
    );

    const text = result?.response?.text() || 'No response';
    res.json({ message: text });
  } catch (error) {
    console.error('Gemini error:', error);
    const status = error?.status || error?.response?.status || 500;
    const message =
      error?.message ||
      error?.response?.data?.error?.message ||
      'Gemini request failed';
    res.status(status).json({ message });
  }
});

const seedDefaults = async () => {
  const categoryCount = await Category.countDocuments();
  if (categoryCount === 0) {
    const categories = [
      { name: 'Раушан гүлдері', imagePath: 'assets/cat_1.png', order: 1 },
      { name: 'Пион гүлдері', imagePath: 'assets/cat_2.png', order: 2 },
      { name: 'Лилия және гортензия', imagePath: 'assets/cat_3.png', order: 3 },
      { name: 'Хризантема', imagePath: 'assets/cat_4.png', order: 4 },
      { name: 'Аралас букеттер', imagePath: 'assets/cat_5.png', order: 5 },
      { name: 'Тәтті букеттер', imagePath: 'assets/cat_6.png', order: 6 },
      { name: 'Ақша букеттері', imagePath: 'assets/cat_7.png', order: 7 },
      { name: 'Аю букеттері', imagePath: 'assets/cat_8.png', order: 8 },
      { name: 'Гүл қолшатырлары', imagePath: 'assets/cat_9.png', order: 9 },
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
        popular: true,
      },
      {
        name: 'Ақ раушан',
        price: 18990,
        imagePath: 'assets/flower_rose_white.png',
        flowerType: 'rose',
        category: getCategory(2),
        inStock: true,
        stockCount: 10,
        popular: true,
      },
      {
        name: 'Қызғылт пион',
        price: 21990,
        imagePath: 'assets/flower_peony_pink.png',
        flowerType: 'peony',
        category: getCategory(0),
        inStock: true,
        stockCount: 8,
        popular: true,
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
      },
      {
        name: 'Гүл қолшатырлары',
        price: 42990,
        imagePath: 'assets/product_flower_umbrella1.png',
        flowerType: 'umbrella',
        category: getCategory(8),
        inStock: true,
        stockCount: 2,
      },
      {
        name: 'Гүл қолшатырлары (2)',
        price: 45990,
        imagePath: 'assets/product_flower_umbrella2.png',
        flowerType: 'umbrella',
        category: getCategory(8),
        inStock: true,
        stockCount: 1,
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
    updateByImage(8, ['assets/product_candy_bouquet.png']),
    updateByImage(9, [
      'assets/product_balloons_birthday.png',
      'assets/product_balloons_standart.png',
      'assets/product_flower_umbrella1.png',
      'assets/product_flower_umbrella2.png',
    ]),
  ]);
};

mongoose.connection.once('open', () => {
  seedDefaults().catch((err) => console.error('Seed failed:', err));
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});

















