// Simple Express backend for GreenFresh
const express = require('express');
const session = require('express-session');
const passport = require('passport');
const GoogleStrategy = require('passport-google-oauth20').Strategy;
const FacebookStrategy = require('passport-facebook').Strategy;
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const crypto = require('crypto');
const app = express();

// ⭐️ THÊM: Cấu hình CORS ⭐️
const cors = require('cors');

// Sử dụng biến môi trường PORT của Render, nếu không có thì dùng 3000
const PORT = process.env.PORT || 3000; 

// Định nghĩa URL cơ sở từ biến môi trường (BACKEND_URL đã đặt trên Render)
const BACKEND_BASE_URL = process.env.BACKEND_URL || `http://localhost:${PORT}`;

// ⭐️ ĐỊA CHỈ FRONTEND NETLIFY CỦA BẠN ⭐️
const NETLIFY_URL = 'https://sage-kelpie-f9cd13.netlify.app'; 

const corsOptions = {
    // Cho phép truy cập từ Netlify và địa chỉ Render của chính nó
    origin: [NETLIFY_URL, BACKEND_BASE_URL], 
    credentials: true, // Cho phép gửi cookie/session
};

app.use(cors(corsOptions)); // ⭐️ SỬ DỤNG CORS ⭐️
app.use(express.json());

// Serve static files (HTML, CSS, JS)
app.use(express.static(path.join(__dirname, '..')));
app.use(session({ secret: 'greenfresh_secret', resave: false, saveUninitialized: true }));
app.use(passport.initialize());
app.use(passport.session());

// Connect to SQLite database (or create if not exists)
const db = new sqlite3.Database(path.join(__dirname, 'greenfresh.db'));

// Bảng đơn hàng có trạng thái
db.run('CREATE TABLE IF NOT EXISTS orders (id INTEGER PRIMARY KEY, user_email TEXT, items TEXT, status TEXT DEFAULT "Chờ duyệt", created_at TEXT)');
// Simple user table for demo
db.run('CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, email TEXT UNIQUE, password TEXT, role TEXT DEFAULT "customer")');
// Bảng đánh giá sản phẩm
db.run('CREATE TABLE IF NOT EXISTS reviews (id INTEGER PRIMARY KEY, product_id INTEGER, user_email TEXT, rating INTEGER, comment TEXT, created_at TEXT)');
// Bảng sản phẩm (thêm lại cho đầy đủ)
db.run('CREATE TABLE IF NOT EXISTS products (id INTEGER PRIMARY KEY, name TEXT, price REAL, description TEXT, category TEXT, image TEXT)');
// Bảng ProductJourney (thêm lại cho đầy đủ)
db.run('CREATE TABLE IF NOT EXISTS ProductJourney (id INTEGER PRIMARY KEY, product_id INTEGER, stage TEXT, description TEXT, date TEXT, image TEXT)');
// Bảng PurchaseHistory (thêm lại cho đầy đủ)
db.run('CREATE TABLE IF NOT EXISTS PurchaseHistory (id INTEGER PRIMARY KEY, user_email TEXT, product_id INTEGER, quantity INTEGER, purchased_at TEXT)');
// Bảng ChatMessage (thêm lại cho đầy đủ)
db.run('CREATE TABLE IF NOT EXISTS ChatMessage (id INTEGER PRIMARY KEY, sender TEXT, receiver TEXT, message TEXT, sent_at TEXT)');

// Tạo tài khoản admin mặc định nếu chưa có
db.get('SELECT * FROM users WHERE email = ?', ['admin@greenfresh.com'], (err, user) => {
    if (!user) {
        db.run('INSERT INTO users (email, password, role) VALUES (?, ?, ?)', ['admin@greenfresh.com', 'admin123', 'admin']);
        console.log('Đã tạo tài khoản admin mặc định: admin@greenfresh.com / admin123');
    }
});

passport.serializeUser(function(user, done) {
    done(null, user);
});

passport.deserializeUser(function(obj, done) {
    done(null, obj);
});

// Google OAuth - SỬ DỤNG BIẾN MÔI TRƯỜNG
passport.use(new GoogleStrategy({
    clientID: process.env.GOOGLE_CLIENT_ID || 'YOUR_GOOGLE_CLIENT_ID', 
    clientSecret: process.env.GOOGLE_CLIENT_SECRET || 'YOUR_GOOGLE_CLIENT_SECRET',
    callbackURL: `${BACKEND_BASE_URL}/auth/google/callback` // Dùng URL công khai
}, function(accessToken, refreshToken, profile, done) {
    // Tùy chỉnh lưu user vào DB nếu cần
    return done(null, { email: profile.emails[0].value, displayName: profile.displayName, role: 'customer' });
}));

// Facebook OAuth - SỬ DỤNG BIẾN MÔI TRƯỜNG
passport.use(new FacebookStrategy({
    clientID: process.env.FACEBOOK_APP_ID || 'YOUR_FACEBOOK_APP_ID',
    clientSecret: process.env.FACEBOOK_APP_SECRET || 'YOUR_FACEBOOK_APP_SECRET',
    callbackURL: `${BACKEND_BASE_URL}/auth/facebook/callback`, // Dùng URL công khai
    profileFields: ['id', 'displayName', 'emails']
}, function(accessToken, refreshToken, profile, done) {
    // Tùy chỉnh lưu user vào DB nếu cần
    return done(null, { email: (profile.emails && profile.emails[0].value) || '', displayName: profile.displayName, role: 'customer' });
}));

// Google Auth Routes
app.get('/auth/google', passport.authenticate('google', { scope: ['profile', 'email'] }));
app.get('/auth/google/callback', passport.authenticate('google', { failureRedirect: '/login.html' }), (req, res) => {
    // Lưu user vào session, chuyển về trang chủ
    req.session.user = req.user;
    res.redirect('/');
});
// Facebook Auth Routes
app.get('/auth/facebook', passport.authenticate('facebook', { scope: ['email'] }));
app.get('/auth/facebook/callback', passport.authenticate('facebook', { failureRedirect: '/login.html' }), (req, res) => {
    req.session.user = req.user;
    res.redirect('/');
});

// Initialize DB from SQL files if empty
function initializeDB() {
    db.serialize(() => {
        db.all('SELECT COUNT(*) as count FROM products', (err, rows) => {
            if (!err && rows[0].count === 0) {
                const sampleProducts = [
                    { name: 'Rau cải xanh hữu cơ', price: 25000, description: 'Tươi ngon, không hóa chất', category: 'Rau củ quả', image: 'https://cdn.pixabay.com/photo/2017/06/02/18/24/vegetables-2362151_1280.jpg' },
                    { name: 'Cà chua cherry Đà Lạt', price: 45000, description: 'Ngọt tự nhiên, giàu vitamin', category: 'Rau củ quả', image: 'https://cdn.pixabay.com/photo/2016/03/05/19/02/tomatoes-1238252_1280.jpg' },
                    { name: 'Táo Fuji Nhật Bản', price: 120000, description: 'Giòn ngọt, chất lượng cao', category: 'Trái cây', image: 'https://cdn.pixabay.com/photo/2014/02/01/17/28/apple-256262_1280.jpg' },
                    { name: 'Gạo hữu cơ ST25', price: 85000, description: 'Gạo thơm ngon, dinh dưỡng', category: 'Rau củ quả', image: 'https://cdn.pixabay.com/photo/2017/07/16/10/43/rice-2511123_1280.jpg' },
                    { name: 'Thịt bò Úc', price: 220000, description: 'Thịt bò nhập khẩu, mềm ngon', category: 'Thịt sạch', image: 'https://cdn.pixabay.com/photo/2016/03/05/19/02/beef-1238248_1280.jpg' },
                    { name: 'Thịt gà ta', price: 90000, description: 'Gà ta thả vườn, chắc thịt', category: 'Thịt sạch', image: 'https://cdn.pixabay.com/photo/2017/07/16/10/43/chicken-2511125_1280.jpg' },
                    { name: 'Cá hồi Nauy', price: 350000, description: 'Cá hồi tươi, giàu Omega-3', category: 'Hải sản', image: 'https://cdn.pixabay.com/photo/2017/07/16/10/43/salmon-2511126_1280.jpg' },
                    { name: 'Tôm sú biển', price: 180000, description: 'Tôm sú tươi sống, ngọt thịt', category: 'Hải sản', image: 'https://cdn.pixabay.com/photo/2017/07/16/10/43/shrimp-2511127_1280.jpg' },
                    { name: 'Cam sành miền Tây', price: 40000, description: 'Cam sành mọng nước, giàu vitamin C', category: 'Trái cây', image: 'https://cdn.pixabay.com/photo/2016/03/05/19/02/orange-1238251_1280.jpg' },
                    { name: 'Chuối Laba Đà Lạt', price: 30000, description: 'Chuối Laba thơm ngon, bổ dưỡng', category: 'Trái cây', image: 'https://cdn.pixabay.com/photo/2016/03/05/19/02/banana-1238253_1280.jpg' },
                    { name: 'Dưa hấu Long An', price: 25000, description: 'Dưa hấu ngọt mát, giải nhiệt', category: 'Trái cây', image: 'https://cdn.pixabay.com/photo/2016/03/05/19/02/watermelon-1238254_1280.jpg' },
                    { name: 'Hàu sữa Pháp', price: 60000, description: 'Hàu sữa nhập khẩu, béo ngậy', category: 'Hải sản', image: 'https://cdn.pixabay.com/photo/2017/07/16/10/43/oyster-2511128_1280.jpg' }
                ];
                const insertStmt = db.prepare('INSERT INTO products (name, price, description, category, image) VALUES (?, ?, ?, ?, ?)');
                sampleProducts.forEach(p => {
                    insertStmt.run(p.name, p.price, p.description, p.category, p.image);
                });
                insertStmt.finalize();
            }
        });
    });
}
initializeDB();
// ... (Các API khác giữ nguyên) ...

// API: Get products with optional price filter
app.get('/api/products', (req, res) => {
    let sql = 'SELECT * FROM products WHERE 1=1';
    const params = [];
    // Price filter
    if (req.query.price) {
        const price = req.query.price;
        if (price === '1') sql += ' AND price < 50000';
        else if (price === '2') sql += ' AND price >= 50000 AND price <= 100000';
        else if (price === '3') sql += ' AND price > 100000 AND price <= 200000';
        else if (price === '4') sql += ' AND price > 200000';
    }
    // Category filter
    if (req.query.category) {
        sql += ' AND category = ?';
        params.push(req.query.category);
    }
    db.all(sql, params, (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});

// API: Thêm hành trình sản phẩm
app.post('/api/product-journey', (req, res) => {
    const { product_id, stage, description, date, image } = req.body;
    db.run('INSERT INTO ProductJourney (product_id, stage, description, date, image) VALUES (?, ?, ?, ?, ?)', [product_id, stage, description, date, image], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ id: this.lastID });
    });
});

// API: Gửi tin nhắn chat
app.post('/api/chat/send', (req, res) => {
    const { sender, receiver, message } = req.body;
    const sent_at = new Date().toISOString();
    db.run('INSERT INTO ChatMessage (sender, receiver, message, sent_at) VALUES (?, ?, ?, ?)', [sender, receiver, message, sent_at], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ id: this.lastID });
    });
});

// API: Lấy tin nhắn chat giữa user và admin
app.get('/api/chat/history', (req, res) => {
    const { user_email } = req.query;
    db.all('SELECT * FROM ChatMessage WHERE (sender = ? OR receiver = ?) ORDER BY sent_at ASC', [user_email, user_email], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});
app.get('/api/recommend-products', (req, res) => {
    // Logic AI: Nếu có user_email, gợi ý sản phẩm cùng loại với sản phẩm user đã mua nhiều nhất
    // Nếu không, gợi ý sản phẩm bán chạy nhất
    const { product_id, user_email } = req.query;
    if (user_email) {
        // Tìm sản phẩm user đã mua nhiều nhất
        db.get('SELECT product_id, COUNT(*) as cnt FROM PurchaseHistory WHERE user_email = ? GROUP BY product_id ORDER BY cnt DESC LIMIT 1', [user_email], (err, row) => {
            if (err || !row) {
                // Nếu chưa có lịch sử, gợi ý sản phẩm bán chạy
                db.all('SELECT p.*, COUNT(ph.id) as sold FROM products p LEFT JOIN PurchaseHistory ph ON p.id = ph.product_id GROUP BY p.id ORDER BY sold DESC LIMIT 6', [], (err2, rows) => {
                    if (err2) return res.json([]);
                    res.json(rows);
                });
            } else {
                // Lấy loại sản phẩm đã mua nhiều nhất
                db.get('SELECT category FROM products WHERE id = ?', [row.product_id], (err3, prod) => {
                    if (err3 || !prod) return res.json([]);
                    db.all('SELECT * FROM products WHERE category = ? AND id != ? LIMIT 6', [prod.category, row.product_id], (err4, rows) => {
                        if (err4) return res.json([]);
                        res.json(rows);
                    });
                });
            }
        });
    } else if (product_id) {
        // Gợi ý sản phẩm cùng loại với sản phẩm đang xem
        db.get('SELECT category FROM products WHERE id = ?', [product_id], (err, prod) => {
            if (err || !prod) return res.json([]);
            db.all('SELECT * FROM products WHERE category = ? AND id != ? LIMIT 6', [prod.category, product_id], (err2, rows) => {
                if (err2) return res.json([]);
                res.json(rows);
            });
        });
    } else {
        // Gợi ý sản phẩm bán chạy nhất
        db.all('SELECT p.*, COUNT(ph.id) as sold FROM products p LEFT JOIN PurchaseHistory ph ON p.id = ph.product_id GROUP BY p.id ORDER BY sold DESC LIMIT 6', [], (err, rows) => {
            if (err) return res.json([]);
            res.json(rows);
        });
    }
});
app.get('/api/product-journey/:product_id', (req, res) => {
    db.all('SELECT * FROM ProductJourney WHERE product_id = ? ORDER BY date ASC', [req.params.product_id], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});
app.post('/api/products', (req, res) => {
    const { name, price, description, category, image } = req.body;
    db.run('INSERT INTO products (name, price, description, category, image) VALUES (?, ?, ?, ?, ?)', [name, price, description, category, image], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ id: this.lastID });
    });
});

app.listen(PORT, () => {
    console.log(`GreenFresh backend running at ${BACKEND_BASE_URL}`);
});

// --- VNPay Payment Integration (Demo structure, fill merchant info to use real) ---
// SỬ DỤNG BIẾN MÔI TRƯỜNG CHO VNPay
const vnp_TmnCode = process.env.VNP_TMN_CODE; 
const vnp_HashSecret = process.env.VNP_HASH_SECRET; 
const vnp_Url = 'https://pay.vnpay.vn/vpcpay.html';

// ⭐️ ĐÃ FIX: Đổi URL trả về thành địa chỉ Netlify Frontend ⭐️
const vnp_ReturnUrl = `${NETLIFY_URL}/vnpay_return.html`; 

// API: Tạo link thanh toán VNPay
app.post('/api/vnpay/create_payment', (req, res) => {
    if (!vnp_TmnCode || !vnp_HashSecret) {
        return res.status(500).json({ error: 'Missing VNPAY credentials (VNP_TMN_CODE or VNP_HASH_SECRET) in Environment Variables' });
    }
    
    const { amount, orderId, orderInfo } = req.body;
    const ipAddr = req.headers['x-forwarded-for'] || req.connection.remoteAddress;
    const tmnCode = vnp_TmnCode;
    const secretKey = vnp_HashSecret;
    let vnp_Params = {};
    vnp_Params['vnp_Version'] = '2.1.0';
    vnp_Params['vnp_Command'] = 'pay';
    vnp_Params['vnp_TmnCode'] = tmnCode;
    vnp_Params['vnp_Locale'] = 'vn';
    vnp_Params['vnp_CurrCode'] = 'VND';
    vnp_Params['vnp_TxnRef'] = orderId;
    vnp_Params['vnp_OrderInfo'] = orderInfo;
    vnp_Params['vnp_OrderType'] = 'other';
    vnp_Params['vnp_Amount'] = amount * 100;
    vnp_Params['vnp_ReturnUrl'] = vnp_ReturnUrl; // <-- Đã dùng URL Netlify
    vnp_Params['vnp_IpAddr'] = ipAddr;
    vnp_Params['vnp_CreateDate'] = new Date().toISOString().replace(/[-:T.]/g, '').slice(0, 14);
    // Sort params
    vnp_Params = Object.fromEntries(Object.entries(vnp_Params).sort());
    // Create querystring
    const signData = Object.entries(vnp_Params).map(([k, v]) => `${k}=${v}`).join('&');
    const hmac = crypto.createHmac('sha512', secretKey);
    const signed = hmac.update(signData).digest('hex');
    vnp_Params['vnp_SecureHash'] = signed;
    const query = Object.entries(vnp_Params).map(([k, v]) => `${k}=${encodeURIComponent(v)}`).join('&');
    const paymentUrl = `${vnp_Url}?${query}`;
    res.json({ paymentUrl });
});

// API: Xử lý callback VNPay (demo, cần xác thực hash khi dùng thật)
// API này chỉ dành cho SERVER-TO-SERVER (IPN), nhưng ta vẫn giữ lại
app.get('/vnpay_return', (req, res) => {
    // Logic: VNPay gửi kết quả về Frontend (vnpay_return.html). 
    // Frontend sẽ gọi một API khác trên Backend để xác thực.
    // API này (vnpay_return trên Render) có thể chỉ dùng cho IPN (thông báo tức thời).
    res.send('Thanh toán VNPay thành công!');
});

// ... (Các API còn lại giữ nguyên) ...

// API: Tạo đơn hàng
app.post('/api/orders', (req, res) => {
    const { user_email, items } = req.body;
    const created_at = new Date().toISOString();
    db.run('INSERT INTO orders (user_email, items, status, created_at) VALUES (?, ?, ?, ?)', [user_email, JSON.stringify(items), 'Chờ duyệt', created_at], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ success: true, id: this.lastID });
    });
});

// API: Lấy danh sách đơn hàng
app.get('/api/orders', (req, res) => {
    db.all('SELECT * FROM orders ORDER BY created_at DESC', (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        // Parse items JSON
        rows.forEach(o => { o.items = JSON.parse(o.items); });
        res.json(rows);
    });
});

// API: Cập nhật trạng thái đơn hàng
app.put('/api/orders/:id', (req, res) => {
    const { status } = req.body;
    db.run('UPDATE orders SET status = ? WHERE id = ?', [status, req.params.id], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ success: true });
    });
});

// API: Sửa sản phẩm (chỉ admin)
app.put('/api/products/:id', (req, res) => {
    const { name, price, description, category, image } = req.body;
    db.run('UPDATE products SET name = ?, price = ?, description = ?, category = ?, image = ? WHERE id = ?', [name, price, description, category, image, req.params.id], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ success: true });
    });
});

// API: Xóa sản phẩm (chỉ admin)
app.delete('/api/products/:id', (req, res) => {
    db.run('DELETE FROM products WHERE id = ?', [req.params.id], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ success: true });
    });
});

// API: Lấy đánh giá sản phẩm
app.get('/api/reviews', (req, res) => {
    const product_id = req.query.product_id;
    db.all('SELECT * FROM reviews WHERE product_id = ? ORDER BY created_at DESC', [product_id], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});

// API: Thêm đánh giá sản phẩm
app.post('/api/reviews', (req, res) => {
    const { product_id, user_email, rating, comment } = req.body;
    const created_at = new Date().toISOString();
    db.run('INSERT INTO reviews (product_id, user_email, rating, comment, created_at) VALUES (?, ?, ?, ?, ?)', [product_id, user_email, rating, comment, created_at], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ success: true, id: this.lastID });
    });
});

// API: Cập nhật thông tin cá nhân
app.post('/api/update-profile', (req, res) => {
    const { email, displayName } = req.body;
    db.run('UPDATE users SET displayName = ? WHERE email = ?', [displayName, email], function(err) {
        if (err) return res.json({ success: false });
        res.json({ success: true });
    });
});

// API: Đổi mật khẩu
app.post('/api/change-password', (req, res) => {
    const { email, currentPassword, newPassword } = req.body;
    db.get('SELECT * FROM users WHERE email = ? AND password = ?', [email, currentPassword], (err, user) => {
        if (err || !user) return res.json({ success: false, error: 'Mật khẩu hiện tại không đúng!' });
        db.run('UPDATE users SET password = ? WHERE email = ?', [newPassword, email], function(err2) {
            if (err2) return res.json({ success: false });
            res.json({ success: true });
        });
    });
});

// API: Đăng ký
app.post('/api/register', (req, res) => {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ error: 'Thiếu thông tin' });
    db.run('INSERT INTO users (email, password, role) VALUES (?, ?, ?)', [email, password, 'customer'], function(err) {
        if (err) return res.status(400).json({ error: 'Email đã tồn tại hoặc lỗi' });
        res.json({ success: true, id: this.lastID });
    });
});

// API: Đăng nhập
app.post('/api/login', (req, res) => {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ error: 'Thiếu thông tin' });
    db.get('SELECT * FROM users WHERE email = ? AND password = ?', [email, password], (err, user) => {
        if (err || !user) return res.status(401).json({ error: 'Sai thông tin đăng nhập' });
        res.json({ success: true, user: { id: user.id, email: user.email, role: user.role } });
    });
});

// API: Tạo tài khoản admin (chỉ dùng 1 lần, hoặc xóa sau khi tạo)
app.post('/api/create-admin', (req, res) => {
    const { email, password } = req.body;
    db.run('INSERT INTO users (email, password, role) VALUES (?, ?, ?)', [email, password, 'admin'], function(err) {
        if (err) return res.status(400).json({ error: 'Email đã tồn tại hoặc lỗi' });
        res.json({ success: true, id: this.lastID });
    });
});