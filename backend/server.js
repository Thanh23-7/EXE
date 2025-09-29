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

// Serve static files (HTML, CSS, JS) - CHỈ DÙNG TRONG MÔI TRƯỜNG DEV/MÔI TRƯỜNG CHẠY CÙNG FRONTEND
app.use(express.static(path.join(__dirname, '..')));
app.use(session({ secret: 'greenfresh_secret', resave: false, saveUninitialized: true }));
app.use(passport.initialize());
app.use(passport.session());

// Connect to SQLite database
const db = new sqlite3.Database(path.join(__dirname, 'greenfresh.db'));

// Tạo bảng DB an toàn hơn (sử dụng lệnh riêng biệt)
db.run('CREATE TABLE IF NOT EXISTS orders (id INTEGER PRIMARY KEY, user_email TEXT, items TEXT, status TEXT DEFAULT "Chờ duyệt", created_at TEXT)');
db.run('CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, email TEXT UNIQUE, password TEXT, role TEXT DEFAULT "customer")');
db.run('CREATE TABLE IF NOT EXISTS reviews (id INTEGER PRIMARY KEY, product_id INTEGER, user_email TEXT, rating INTEGER, comment TEXT, created_at TEXT)');
db.run('CREATE TABLE IF NOT EXISTS products (id INTEGER PRIMARY KEY, name TEXT, price REAL, old_price REAL, description TEXT, category TEXT, image TEXT, origin TEXT, weight TEXT, expiry TEXT, storage TEXT, stock INTEGER)');
db.run('CREATE TABLE IF NOT EXISTS ProductJourney (id INTEGER PRIMARY KEY, product_id INTEGER, stage TEXT, details TEXT, timestamp TEXT, image TEXT)'); // Đổi 'date' thành 'timestamp' và 'description' thành 'details' cho nhất quán
db.run('CREATE TABLE IF NOT EXISTS PurchaseHistory (id INTEGER PRIMARY KEY, user_email TEXT, product_id INTEGER, quantity INTEGER, purchased_at TEXT)');
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
                // ⭐️ START: DỮ LIỆU SẢN PHẨM ĐÃ CẬP NHẬT MÔ TẢ CHI TIẾT ⭐️
                const sampleProducts = [
                    { 
                        id: 1, name: 'Rau cải xanh hữu cơ', price: 25000, old_price: 30000, 
                        description: 'Rau cải xanh được trồng theo quy trình **hữu cơ 100%** tại nông trại Lâm Đồng. Chúng tôi cam kết không sử dụng thuốc bảo vệ thực vật hay phân bón hóa học. Sản phẩm có lá xanh đậm, thân giòn, vị ngọt tự nhiên, rất giàu Vitamin A, C và K.\n\n**Cách sử dụng:** Lý tưởng để nấu canh, luộc, xào tỏi hoặc làm món salad trộn. Rửa sạch dưới vòi nước chảy trước khi chế biến.\n\n**Lưu ý bảo quản:** Giữ trong túi kín, để ở ngăn mát tủ lạnh (2-8°C) để duy trì độ tươi ngon tối đa 3-5 ngày.', 
                        category: 'Rau củ quả', image: 'https://cdn.pixabay.com/photo/2017/06/02/18/24/vegetables-2362151_1280.jpg', origin: 'Đà Lạt, Việt Nam', weight: '500g', expiry: '3-5 ngày', storage: 'Tủ lạnh 2-8°C', stock: 47 
                    },
                    { 
                        id: 2, name: 'Cà chua cherry Đà Lạt', price: 45000, old_price: 50000, 
                        description: 'Cà chua cherry được trồng trong nhà kính tại Đà Lạt, đảm bảo điều kiện thổ nhưỡng và ánh sáng tối ưu. Quả nhỏ, tròn, màu đỏ tươi bắt mắt, có vị ngọt thanh tự nhiên và rất giàu Lycopene, một chất chống oxy hóa mạnh mẽ. Sản phẩm đạt tiêu chuẩn VietGAP.\n\n**Ưu điểm:** Ngọt hơn hẳn cà chua thường, thích hợp ăn sống, làm salad hoặc trang trí món ăn.\n\n**Bảo quản:** Nên để ở nơi thoáng mát ngoài tủ lạnh nếu dùng trong vài ngày. Nếu muốn giữ lâu hơn (trên 1 tuần), hãy cho vào ngăn mát.', 
                        category: 'Rau củ quả', image: 'https://cdn.pixabay.com/photo/2016/03/05/19/02/tomatoes-1238252_1280.jpg', origin: 'Đà Lạt, Việt Nam', weight: '300g', expiry: '7 ngày', storage: 'Nơi thoáng mát', stock: 120 
                    },
                    { 
                        id: 3, name: 'Táo Fuji Nhật Bản', price: 120000, old_price: 150000,
                        description: 'Táo Fuji được nhập khẩu trực tiếp từ các vườn trồng tại Nhật Bản, nổi tiếng với độ giòn cao, hương thơm dịu và vị ngọt đậm đà xen lẫn chút chua nhẹ đặc trưng. Táo được thu hoạch đúng độ chín và bảo quản lạnh nghiêm ngặt để giữ trọn dinh dưỡng và độ tươi.\n\n**Dinh dưỡng:** Giàu chất xơ giúp tiêu hóa tốt và cung cấp lượng lớn Vitamin C.\n\n**Khuyến nghị:** Ăn trực tiếp sau khi rửa sạch hoặc dùng để ép nước, làm bánh táo.', 
                        category: 'Trái cây', image: 'https://cdn.pixabay.com/photo/2014/02/01/17/28/apple-256262_1280.jpg', origin: 'Nhật Bản', weight: '1kg', expiry: '10 ngày', storage: 'Tủ lạnh', stock: 65 
                    },
                    { 
                        id: 4, name: 'Gạo hữu cơ ST25', price: 85000, old_price: 100000,
                        description: 'Gạo ST25 đạt danh hiệu Gạo ngon nhất thế giới, được trồng theo phương pháp hữu cơ, không sử dụng thuốc trừ sâu hay phân hóa học. Hạt gạo dài, trắng trong, khi nấu cho cơm dẻo, thơm mùi lá dứa tự nhiên. Cơm vẫn giữ được độ mềm dẻo ngay cả khi để nguội.\n\n**Hướng dẫn nấu:** Cho 1 chén gạo với khoảng 0.9 chén nước (tỷ lệ 1:0.9). Không cần vo gạo quá kỹ. Ngâm gạo 15 phút trước khi nấu để cơm được ngon hơn.\n\n**Bảo quản:** Giữ nơi khô ráo, tránh ánh nắng trực tiếp.', 
                        category: 'Rau củ quả', image: 'https://cdn.pixabay.com/photo/2017/07/16/10/43/rice-2511123_1280.jpg', origin: 'Sóc Trăng', weight: '5kg', expiry: '12 tháng', storage: 'Nơi khô ráo', stock: 80 
                    },
                    { 
                        id: 5, name: 'Thịt bò Úc', price: 220000, old_price: 250000,
                        description: 'Thịt bò thăn ngoại hoặc thăn nội (tùy đợt) được nhập khẩu từ Úc, nơi có quy trình chăn nuôi sạch và khép kín. Thịt có màu đỏ tươi tự nhiên, vân mỡ trắng xen kẽ, đảm bảo độ mềm và hương vị đậm đà khi chế biến. Sản phẩm được cắt miếng và đóng gói hút chân không.\n\n**Chế biến:** Hoàn hảo cho các món nướng (steak), xào, hoặc làm bò lúc lắc. Nên rã đông chậm trong ngăn mát tủ lạnh.\n\n**An toàn:** Đã qua kiểm dịch an toàn thực phẩm nghiêm ngặt của Việt Nam.', 
                        category: 'Thịt sạch', image: 'https://cdn.pixabay.com/photo/2016/03/05/19/02/beef-1238248_1280.jpg', origin: 'Úc', weight: '500g', expiry: '2 ngày', storage: 'Đông lạnh', stock: 30 
                    },
                    { 
                        id: 6, name: 'Thịt gà ta', price: 90000, old_price: 110000,
                        description: 'Gà ta được nuôi thả vườn tự nhiên tại các trang trại miền quê, đảm bảo vận động thường xuyên nên thịt chắc, da giòn và ít mỡ. Thịt gà không bị bở như gà công nghiệp, giữ trọn vị ngọt tự nhiên của gà ta truyền thống.\n\n**Sử dụng:** Tuyệt vời cho món gà luộc, gà tiềm thuốc bắc, hoặc làm phở gà. Thịt sau khi chế biến sẽ có màu vàng tự nhiên, rất đẹp mắt.\n\n**Thời gian dùng tốt nhất:** Chế biến trong vòng 24 giờ sau khi mua để đảm bảo chất lượng thịt tốt nhất.', 
                        category: 'Thịt sạch', image: 'https://cdn.pixabay.com/photo/2017/07/16/10/43/chicken-2511125_1280.jpg', origin: 'Việt Nam', weight: '1kg', expiry: '1 ngày', storage: 'Tủ lạnh', stock: 55 
                    },
                    { 
                        id: 7, name: 'Cá hồi Nauy', price: 350000, old_price: 380000,
                        description: 'Cá hồi tươi được đánh bắt và vận chuyển bằng đường hàng không từ Nauy. Đây là nguồn cung cấp dồi dào **Omega-3** (EPA và DHA) có lợi cho tim mạch và trí não. Thịt cá có màu cam hồng tươi sáng, thớ thịt dày, béo ngậy.\n\n**Chế biến:** Có thể dùng ăn sống (sashimi), nướng, áp chảo hoặc làm ruốc cá hồi cho trẻ em.\n\n**Lưu ý:** Chỉ rã đông một lần duy nhất. Không tái cấp đông sản phẩm để đảm bảo dinh dưỡng.', 
                        category: 'Hải sản', image: 'https://cdn.pixabay.com/photo/2017/07/16/10/43/salmon-2511126_1280.jpg', origin: 'Nauy', weight: '300g', expiry: '1 ngày', storage: 'Đông lạnh', stock: 20 
                    },
                    { 
                        id: 8, name: 'Tôm sú biển', price: 180000, old_price: 200000,
                        description: 'Tôm sú được nuôi thả tự nhiên trong môi trường nước lợ hoặc đánh bắt từ biển, đảm bảo chất lượng thịt tươi ngon, dai ngọt. Tôm có kích thước lớn, vỏ xanh đậm, mang lại trải nghiệm ẩm thực cao cấp.\n\n**Chế biến:** Tôm sú hấp bia, nướng muối ớt, hoặc rang me đều rất ngon. Khi tôm chuyển sang màu đỏ gạch là đã chín.\n\n**Tiêu chuẩn:** Sản phẩm được kiểm tra nghiêm ngặt về độ tươi và không sử dụng chất bảo quản.', 
                        category: 'Hải sản', image: 'https://cdn.pixabay.com/photo/2017/07/16/10/43/shrimp-2511127_1280.jpg', origin: 'Việt Nam', weight: '500g', expiry: '1 ngày', storage: 'Đông lạnh', stock: 40 
                    },
                ];
                // ⭐️ END: DỮ LIỆU SẢN PHẨM ĐÃ CẬP NHẬT MÔ TẢ CHI TIẾT ⭐️
                
                const insertStmt = db.prepare('INSERT INTO products (id, name, price, old_price, description, category, image, origin, weight, expiry, storage, stock) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
                sampleProducts.forEach(p => {
                    insertStmt.run(p.id, p.name, p.price, p.old_price || p.price, p.description, p.category, p.image, p.origin, p.weight, p.expiry, p.storage, p.stock);
                });
                insertStmt.finalize();

                // Thêm dữ liệu Hành trình sản phẩm mẫu cho sản phẩm ID=1
                const journeyStmt = db.prepare('INSERT INTO ProductJourney (product_id, stage, details, timestamp) VALUES (?, ?, ?, ?)');
                journeyStmt.run(1, 'Gieo hạt', 'Hạt giống hữu cơ được gieo trồng tại nông trại Lâm Đồng.', new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString());
                journeyStmt.run(1, 'Chăm sóc hữu cơ', 'Sử dụng phân bón hữu cơ và nước sạch được kiểm soát.', new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString());
                journeyStmt.run(1, 'Thu hoạch', 'Thu hoạch bằng tay vào sáng sớm để đảm bảo độ tươi ngon.', new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString());
                journeyStmt.run(1, 'Đóng gói & Vận chuyển', 'Đóng gói trong bao bì sinh học và vận chuyển về kho lạnh.', new Date().toISOString());
                journeyStmt.finalize();
                
                // Thêm đánh giá mẫu cho sản phẩm ID=1
                const reviewStmt = db.prepare('INSERT INTO reviews (product_id, user_email, rating, comment, created_at) VALUES (?, ?, ?, ?, ?)');
                reviewStmt.run(1, 'customer1@gmail.com', 5, 'Rau tươi, sạch, rất đáng tiền!', new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString());
                reviewStmt.run(1, 'customer2@gmail.com', 4, 'Hơi ít, nhưng chất lượng tuyệt vời.', new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString());
                reviewStmt.finalize();
            }
        });
    });
}
initializeDB();

// --- API ROUTES ---

// API: Get products (Danh sách)
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
    // Limit and Exclude (dùng cho gợi ý)
    if (req.query.limit) sql += ` LIMIT ${parseInt(req.query.limit)}`;
    if (req.query.exclude) {
        sql += ' AND id != ?';
        params.push(req.query.exclude);
    }
    
    db.all(sql, params, (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});

// API: Lấy chi tiết sản phẩm theo ID 
app.get('/api/products/:id', (req, res) => {
    const productId = req.params.id; 
    
    // Sử dụng db.get vì chỉ cần lấy 1 sản phẩm
    db.get('SELECT * FROM products WHERE id = ?', [productId], (err, row) => {
        if (err) {
            console.error('Database error:', err);
            return res.status(500).json({ error: err.message });
        }
        
        if (!row) {
            // Trả về 404 nếu không tìm thấy
            return res.status(404).json({ message: 'Không tìm thấy sản phẩm.' });
        }
        
        // Trả về dữ liệu sản phẩm
        res.json(row);
    });
});


// API: Lấy hành trình sản phẩm
app.get('/api/products/:product_id/journey', (req, res) => {
    db.all('SELECT * FROM ProductJourney WHERE product_id = ? ORDER BY timestamp ASC', [req.params.product_id], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});

// API: Thêm hành trình sản phẩm
app.post('/api/product-journey', (req, res) => {
    const { product_id, stage, details, timestamp } = req.body;
    db.run('INSERT INTO ProductJourney (product_id, stage, details, timestamp) VALUES (?, ?, ?, ?)', [product_id, stage, details, timestamp], function(err) {
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

// ⭐️ API GỢI Ý SẢN PHẨM ĐÃ FIX VÀ HOÀN THIỆN LOGIC ⭐️
app.get('/api/recommend-products', (req, res) => {
    const { product_id, user_email } = req.query;
    
    if (user_email) {
        // Kịch bản 1: Gợi ý theo sản phẩm user đã mua nhiều nhất
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
                    // Lấy các sản phẩm khác cùng danh mục
                    db.all('SELECT * FROM products WHERE category = ? AND id != ? LIMIT 6', [prod.category, row.product_id], (err4, rows) => {
                        if (err4) return res.json([]);
                        res.json(rows);
                    });
                });
            }
        });
    } else if (product_id) {
        // Kịch bản 2: Gợi ý sản phẩm cùng loại với sản phẩm đang xem
        db.get('SELECT category FROM products WHERE id = ?', [product_id], (err, prod) => {
            if (err || !prod) return res.json([]);
            db.all('SELECT * FROM products WHERE category = ? AND id != ? LIMIT 6', [prod.category, product_id], (err2, rows) => {
                if (err2) return res.json([]);
                res.json(rows);
            });
        });
    } else {
        // Kịch bản 3: Gợi ý sản phẩm bán chạy nhất (mặc định)
        db.all('SELECT p.*, COUNT(ph.id) as sold FROM products p LEFT JOIN PurchaseHistory ph ON p.id = ph.product_id GROUP BY p.id ORDER BY sold DESC LIMIT 6', [], (err, rows) => {
            if (err) return res.json([]);
            res.json(rows);
        });
    }
});


app.post('/api/products', (req, res) => {
    const { name, price, description, category, image, origin, weight, expiry, storage, stock } = req.body;
    db.run('INSERT INTO products (name, price, description, category, image, origin, weight, expiry, storage, stock) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', [name, price, description, category, image, origin, weight, expiry, storage, stock], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ id: this.lastID });
    });
});

// --- VNPay Payment Integration ---
const vnp_TmnCode = process.env.VNP_TMN_CODE; 
const vnp_HashSecret = process.env.VNP_HASH_SECRET; 
// ⭐️ FIX: Dùng URL Sandbox nếu đang sử dụng Mã Test 2XQUI4J4 ⭐️
const vnp_Url = (vnp_TmnCode === '2XQUI4J4') ? 'http://sandbox.vnpayment.vn/paymentv2/vpcpay.html' : 'https://pay.vnpay.vn/vpcpay.html';

// Đã FIX: Đổi URL trả về thành địa chỉ Netlify Frontend
const vnp_ReturnUrl = `${NETLIFY_URL}/vnpay_return.html`; 

// API: Tạo link thanh toán VNPay
app.post('/api/vnpay/create_payment', (req, res) => {
    // ⭐️ FIX: Thêm kiểm tra placeholder để báo lỗi rõ ràng hơn ⭐️
    if (!vnp_TmnCode || !vnp_HashSecret || vnp_TmnCode.startsWith('YOUR_') || vnp_HashSecret.startsWith('YOUR_')) {
        return res.status(500).json({ error: 'Missing or placeholder VNPAY credentials (VNP_TMN_CODE or VNP_HASH_SECRET) in Environment Variables' });
    }
    
    const { amount, orderId, orderInfo } = req.body;
    // Xử lý lấy IP address khi chạy trên Render/Production
    const ipAddr = req.headers['x-forwarded-for'] ? req.headers['x-forwarded-for'].split(',')[0].trim() : req.connection.remoteAddress;
    
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
    const sortedParams = Object.fromEntries(Object.entries(vnp_Params).sort(([k1], [k2]) => k1.localeCompare(k2)));

    // Create querystring and Hash
    const signData = Object.entries(sortedParams).map(([k, v]) => `${k}=${v}`).join('&');
    const hmac = crypto.createHmac('sha512', secretKey);
    const signed = hmac.update(signData).digest('hex');
    sortedParams['vnp_SecureHash'] = signed;
    
    const query = Object.entries(sortedParams).map(([k, v]) => `${k}=${encodeURIComponent(v)}`).join('&');
    const paymentUrl = `${vnp_Url}?${query}`;
    res.json({ paymentUrl });
});

// API: Xử lý callback VNPay (demo)
app.get('/vnpay_return', (req, res) => {
    // Frontend sẽ xử lý kết quả trả về từ VNPay qua vnpay_return.html
    res.send('Thanh toán VNPay thành công!');
});

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
    const { name, price, description, category, image, origin, weight, expiry, storage, stock } = req.body;
    db.run('UPDATE products SET name = ?, price = ?, description = ?, category = ?, image = ?, origin = ?, weight = ?, expiry = ?, storage = ?, stock = ? WHERE id = ?', [name, price, description, category, image, origin, weight, expiry, storage, stock, req.params.id], function(err) {
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

app.listen(PORT, () => {
    console.log(`GreenFresh backend running at ${BACKEND_BASE_URL}`);
});