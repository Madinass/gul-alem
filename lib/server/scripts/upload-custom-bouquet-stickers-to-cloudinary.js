const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');
const { v2: cloudinary } = require('cloudinary');
require('dotenv').config({ path: path.resolve(__dirname, '..', '.env') });

const args = new Set(process.argv.slice(2));
const dryRun = args.has('--dry-run');
const force = args.has('--force');

const serverRoot = path.resolve(__dirname, '..');
const projectRoot = path.resolve(serverRoot, '..', '..');
const cloudinaryFolder = 'gul-alem/custom-bouquet';

const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/gul_alem_db';
const CLOUDINARY_CLOUD_NAME = process.env.CLOUDINARY_CLOUD_NAME || '';
const CLOUDINARY_API_KEY = process.env.CLOUDINARY_API_KEY || '';
const CLOUDINARY_API_SECRET = process.env.CLOUDINARY_API_SECRET || '';

cloudinary.config({
  cloud_name: CLOUDINARY_CLOUD_NAME,
  api_key: CLOUDINARY_API_KEY,
  api_secret: CLOUDINARY_API_SECRET,
});

const customBouquetItemSchema = new mongoose.Schema(
  {
    name: String,
    group: String,
    price: Number,
    stockCount: Number,
    inStock: Boolean,
    order: Number,
    imagePath: String,
    imageUrl: String,
  },
  { strict: false, timestamps: true }
);

const CustomBouquetItem = mongoose.model(
  'CustomBouquetStickerUpload',
  customBouquetItemSchema,
  'custombouquetitems'
);

const stickers = [
  {
    name: 'Қызыл раушан',
    group: 'flowers',
    price: 1200,
    stockCount: 40,
    order: 1,
    assetPath: 'assets/custom_bouquet/custom_bouquet_red_rose.png',
    publicId: 'red-rose',
  },
  {
    name: 'Ақ раушан',
    group: 'flowers',
    price: 1300,
    stockCount: 35,
    order: 2,
    assetPath: 'assets/custom_bouquet/custom_bouquet_white_rose.png',
    publicId: 'white-rose',
  },
  {
    name: 'Қызғалдақ',
    group: 'flowers',
    price: 900,
    stockCount: 50,
    order: 3,
    assetPath: 'assets/custom_bouquet/custom_bouquet_tulip.png',
    publicId: 'tulip',
  },
  {
    name: 'Гортензия',
    group: 'flowers',
    price: 2500,
    stockCount: 18,
    order: 4,
    assetPath: 'assets/custom_bouquet/custom_bouquet_hydrangea.png',
    publicId: 'hydrangea',
  },
  {
    name: 'Крафт қағазы',
    group: 'wrapping',
    price: 1500,
    stockCount: 30,
    order: 1,
    assetPath: 'assets/custom_bouquet/custom_bouquet_kraft_wrap.png',
    publicId: 'kraft-wrap',
  },
  {
    name: 'Атлас таспа',
    group: 'wrapping',
    price: 700,
    stockCount: 45,
    order: 2,
    assetPath: 'assets/custom_bouquet/custom_bouquet_satin_ribbon.png',
    publicId: 'satin-ribbon',
  },
  {
    name: 'Премиум қорап',
    group: 'wrapping',
    price: 3500,
    stockCount: 12,
    order: 3,
    assetPath: 'assets/custom_bouquet/custom_bouquet_premium_box.png',
    publicId: 'premium-box',
  },
  {
    name: 'Жасыл жапырақ',
    group: 'extras',
    price: 600,
    stockCount: 60,
    order: 1,
    assetPath: 'assets/custom_bouquet/custom_bouquet_green_leaf.png',
    publicId: 'green-leaf',
  },
  {
    name: 'Ашықхат',
    group: 'extras',
    price: 500,
    stockCount: 80,
    order: 2,
    assetPath: 'assets/custom_bouquet/custom_bouquet_card.png',
    publicId: 'card',
  },
  {
    name: 'Шар',
    group: 'extras',
    price: 1200,
    stockCount: 25,
    order: 3,
    assetPath: 'assets/custom_bouquet/custom_bouquet_balloon.png',
    publicId: 'balloon',
  },
];

const getCloudinaryResource = async (publicId) => {
  try {
    return await cloudinary.api.resource(publicId, { resource_type: 'image' });
  } catch (error) {
    const status = error.http_code || error?.error?.http_code || error.statusCode;
    const message = error?.message || error?.error?.message || '';
    if (status === 404 || message.includes('Resource not found')) return null;
    throw error;
  }
};

const uploadSticker = (filePath, publicId) =>
  cloudinary.uploader.upload(filePath, {
    public_id: publicId,
    overwrite: force,
    unique_filename: false,
    resource_type: 'image',
  });

const main = async () => {
  if (!dryRun && (!CLOUDINARY_CLOUD_NAME || !CLOUDINARY_API_KEY || !CLOUDINARY_API_SECRET)) {
    throw new Error('Cloudinary env vars are missing');
  }

  await mongoose.connect(MONGO_URI);

  let uploaded = 0;
  let reused = 0;
  let linkedFromDb = 0;
  let missing = 0;

  for (const sticker of stickers) {
    const filePath = path.resolve(projectRoot, sticker.assetPath);
    if (!fs.existsSync(filePath)) {
      missing += 1;
      console.log(`MISSING ${sticker.assetPath}`);
      continue;
    }

    const item = await CustomBouquetItem.findOne({
      name: sticker.name,
      group: sticker.group,
    });
    let imageUrl = !force ? String(item?.imageUrl || '') : '';
    const publicId = `${cloudinaryFolder}/${sticker.publicId}`;

    if (imageUrl) {
      linkedFromDb += 1;
      console.log(`SKIP has imageUrl: ${sticker.name}`);
    } else if (dryRun) {
      console.log(`DRY UPLOAD ${sticker.name} <- ${sticker.assetPath}`);
    } else {
      const existing = !force ? await getCloudinaryResource(publicId) : null;
      if (existing?.secure_url) {
        imageUrl = existing.secure_url;
        reused += 1;
        console.log(`REUSE ${sticker.name} -> ${imageUrl}`);
      } else {
        const result = await uploadSticker(filePath, publicId);
        imageUrl = result.secure_url;
        uploaded += 1;
        console.log(`UPLOAD ${sticker.name} -> ${imageUrl}`);
      }
    }

    if (dryRun) continue;

    await CustomBouquetItem.findOneAndUpdate(
      { name: sticker.name, group: sticker.group },
      {
        $set: {
          imagePath: sticker.assetPath,
          imageUrl,
        },
        $setOnInsert: {
          name: sticker.name,
          group: sticker.group,
          price: sticker.price,
          stockCount: sticker.stockCount,
          inStock: sticker.stockCount > 0,
          order: sticker.order,
        },
      },
      { upsert: true }
    );
  }

  console.log(
    JSON.stringify(
      {
        dryRun,
        uploaded,
        reused,
        linkedFromDb,
        missing,
      },
      null,
      2
    )
  );

  await mongoose.disconnect();
};

main().catch(async (error) => {
  console.error(error?.message || error?.error?.message || JSON.stringify(error) || String(error));
  await mongoose.disconnect().catch(() => {});
  process.exit(1);
});
