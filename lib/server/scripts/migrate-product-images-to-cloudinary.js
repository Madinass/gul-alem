const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');
const { v2: cloudinary } = require('cloudinary');
require('dotenv').config({ path: path.resolve(__dirname, '..', '.env') });

const args = new Set(process.argv.slice(2));
const dryRun = args.has('--dry-run');
const force = args.has('--force');
const limitArg = process.argv.find((arg) => arg.startsWith('--limit='));
const onlyArg = process.argv.find((arg) => arg.startsWith('--only='));
const limit = limitArg ? Number.parseInt(limitArg.split('=')[1], 10) : null;
const onlyId = onlyArg ? onlyArg.split('=')[1] : null;

const serverRoot = path.resolve(__dirname, '..');
const projectRoot = path.resolve(serverRoot, '..', '..');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/gul_alem_db';
const CLOUDINARY_CLOUD_NAME = process.env.CLOUDINARY_CLOUD_NAME || '';
const CLOUDINARY_API_KEY = process.env.CLOUDINARY_API_KEY || '';
const CLOUDINARY_API_SECRET = process.env.CLOUDINARY_API_SECRET || '';

cloudinary.config({
  cloud_name: CLOUDINARY_CLOUD_NAME,
  api_key: CLOUDINARY_API_KEY,
  api_secret: CLOUDINARY_API_SECRET,
});

const productSchema = new mongoose.Schema(
  {
    name: String,
    imagePath: String,
    imageUrl: String,
  },
  { strict: false, timestamps: true }
);

const Product = mongoose.model('ProductMigration', productSchema, 'products');

const isHttpUrl = (value) => /^https?:\/\//i.test(String(value || ''));

const resolveAssetPath = (imagePath) => {
  const normalized = String(imagePath || '').replace(/\\/g, '/');
  if (!normalized.startsWith('assets/')) return null;
  return path.resolve(projectRoot, normalized);
};

const uploadToCloudinary = (filePath, product) =>
  cloudinary.uploader.upload(filePath, {
    folder: 'gul-alem/products',
    public_id: product._id.toString(),
    overwrite: true,
    unique_filename: false,
    resource_type: 'image',
  });

const main = async () => {
  if (!dryRun && (!CLOUDINARY_CLOUD_NAME || !CLOUDINARY_API_KEY || !CLOUDINARY_API_SECRET)) {
    throw new Error('Cloudinary env vars are missing');
  }
  if (!dryRun && CLOUDINARY_CLOUD_NAME.toLowerCase() === 'root') {
    throw new Error('CLOUDINARY_CLOUD_NAME must be your Cloudinary cloud name, not "Root"');
  }

  await mongoose.connect(MONGO_URI);

  const filter = onlyId ? { _id: onlyId } : {};
  let query = Product.find(filter).sort({ createdAt: 1 });
  if (Number.isFinite(limit) && limit > 0) query = query.limit(limit);
  const products = await query;

  let uploaded = 0;
  let skipped = 0;
  let missing = 0;
  let linked = 0;
  let failed = 0;

  for (const product of products) {
    const imagePath = String(product.imagePath || '');
    const imageUrl = String(product.imageUrl || '');

    if (imageUrl && !force) {
      skipped += 1;
      console.log(`SKIP has imageUrl: ${product.name} (${product._id})`);
      continue;
    }

    if (isHttpUrl(imagePath)) {
      linked += 1;
      console.log(`${dryRun ? 'DRY ' : ''}LINK imagePath URL: ${product.name} -> ${imagePath}`);
      if (!dryRun) {
        product.imageUrl = imagePath;
        await product.save();
      }
      continue;
    }

    const filePath = resolveAssetPath(imagePath);
    if (!filePath || !fs.existsSync(filePath)) {
      missing += 1;
      console.log(`MISSING file: ${product.name} (${product._id}) imagePath=${imagePath}`);
      continue;
    }

    console.log(`${dryRun ? 'DRY ' : ''}UPLOAD ${product.name} (${product._id}) <- ${imagePath}`);
    if (dryRun) continue;

    try {
      const result = await uploadToCloudinary(filePath, product);
      product.imageUrl = result.secure_url;
      await product.save();
      uploaded += 1;
      console.log(`DONE ${product.name} -> ${result.secure_url}`);
    } catch (error) {
      failed += 1;
      console.error(`FAILED ${product.name} (${product._id}): ${error.message}`);
    }
  }

  console.log(
    JSON.stringify(
      {
        dryRun,
        totalChecked: products.length,
        uploaded,
        linked,
        skipped,
        missing,
        failed,
      },
      null,
      2
    )
  );

  await mongoose.disconnect();

  if (failed > 0) process.exitCode = 1;
};

main().catch(async (error) => {
  console.error(error.message);
  await mongoose.disconnect().catch(() => {});
  process.exit(1);
});
