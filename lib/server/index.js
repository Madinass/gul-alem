const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();
app.use(express.json());
app.use(cors());

mongoose.connect('mongodb://127.0.0.1:27017/gul_alem_db')
  .then(() => console.log("Бәрекелді! Жаңа базаға қосылдық."))
  .catch(err => console.error("Базаға қосылу қатесі:", err));

// Схемаға 'name' қостық
const UserSchema = new mongoose.Schema({
    name: { type: String, required: true }, // ОСЫ ЖЕР МАҢЫЗДЫ
    phone: { type: String, required: true, unique: true },
    password: { type: String, required: true }
});
const User = mongoose.model('User', UserSchema);

// --- ТІРКЕЛУ (REGISTER) ---
app.post('/register', async (req, res) => {
    try {
        const { name, phone, password } = req.body; // 'name' қосылды
        const existingUser = await User.findOne({ phone });
        if (existingUser) return res.status(400).json({ message: "Бұл нөмір тіркелген!" });

        const newUser = new User({ name, phone, password });
        await newUser.save();
        res.status(201).json({ message: "Тіркелу сәтті өтті!" });
    } catch (error) {
        res.status(500).json({ message: "Тіркелуде қате болды" });
    }
});

// --- КІРУ (LOGIN) ---
app.post('/login', async (req, res) => {
    const { phone, password } = req.body;
    
    // МЫНА ЖОЛДАР ТЕРМИНАЛҒА ЖАЗАДЫ:
    console.log("--- КІРУ ТАЛПЫНЫСЫ ---");
    console.log("Телефон:", phone);
    console.log("Пароль:", password);

    const user = await User.findOne({ phone });

    if (!user) {
        console.log("ҚАТЕ: Мұндай нөмір базада жоқ!");
        return res.status(401).json({ message: "Нөмір қате!" });
    }

    if (user.password !== password) {
        console.log("ҚАТЕ: Пароль сәйкес емес!");
        console.log("Базадағы пароль:", user.password);
        return res.status(401).json({ message: "Құпиясөз қате!" });
    }

    console.log("СӘТТІ: Қолданушы танылды!");
    res.status(200).json({ message: "Қош келдіңіз!", name: user.name });
});

// const express = require ('express');
// const mongoose = require('mongoose');
// const cors = require('cors');
// const bcrypt = require('bcrypt');

// const app = express();
// const PORT = 3000;

// // Құпия кілт JWT үшін (егер керек болса)
// const JWT_SECRET = 'your_secret_key_here';

// // Орнату middleware
// app.use(cors());
// app.use(express.json()); // body-parser орнына express.json()

// // MongoDB қосылу
// mongoose.connect('mongodb://localhost:27017/myapp', {
//   useNewUrlParser: true,
//   useUnifiedTopology: true,
// }).then(() => console.log('MongoDB connected'))
//   .catch(err => console.log('MongoDB connection error:', err));

// // Қолданушы схемасы
// const userSchema = new mongoose.Schema({
//   phone: { type: String, unique: true, required: true },
//   passwordHash: { type: String, required: true },
// });

// const User = mongoose.model('User', userSchema);

// // Тіркелу маршруты
// app.post('/register', async (req, res) => {
//   const { phone, password } = req.body;

//   if (!phone || !password) {
//     return res.status(400).json({ message: 'Телефон және құпиясөз қажет' });
//   }

//   try {
//     // Құпиясөзді хештеу
//     const salt = await bcrypt.genSalt(10);
//     const passwordHash = await bcrypt.hash(password, salt);

//     const newUser = new User({ phone, passwordHash });
//     await newUser.save();

//     res.status(201).json({ message: 'Тіркелу сәтті өтті' });
//   } catch (error) {
//     if (error.code === 11000) {
//       return res.status(400).json({ message: 'Бұл телефон бұрын тіркелген' });
//     }
//     res.status(500).json({ message: 'Серверлік қате' });
//   }
// });

// // Кіру маршруты
// app.post('/login', async (req, res) => {
//   const { phone, password } = req.body;

//   if (!phone || !password) {
//     return res.status(400).json({ message: 'Телефон және құпиясөз қажет' });
//   }

//   try {
//     const user = await User.findOne({ phone });
//     if (!user) {
//       return res.status(400).json({ message: 'Қолданушы табылмады' });
//     }

//     const isMatch = await bcrypt.compare(password, user.passwordHash);
//     if (!isMatch) {
//       return res.status(400).json({ message: 'Құпиясөз қате' });
//     }

//     res.json({ message: 'Сәтті кірдіңіз' });
//   } catch (error) {
//     res.status(500).json({ message: 'Серверлік қате' });
//   }
// });

// // Серверді іске қосу
// app.listen(PORT, () => {
//   console.log(`Server running on http://localhost:${PORT}`);
// });