-- Bảng lưu tin nhắn chat giữa user và admin
CREATE TABLE IF NOT EXISTS ChatMessage (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	sender TEXT, -- email hoặc 'admin'
	receiver TEXT, -- email hoặc 'admin'
	message TEXT,
	sent_at TEXT
);
-- Bảng lưu lịch sử mua hàng
CREATE TABLE IF NOT EXISTS PurchaseHistory (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	user_email TEXT,
	product_id INTEGER,
	quantity INTEGER,
	purchased_at TEXT,
	FOREIGN KEY(product_id) REFERENCES Products(id)
);
-- Bảng ghi lại hành trình sản phẩm
CREATE TABLE IF NOT EXISTS ProductJourney (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	product_id INTEGER,
	stage TEXT, -- Trồng trọt, Chăm sóc, Thu hoạch, Đóng gói, Giao hàng
	description TEXT,
	date TEXT,
	image TEXT,
	FOREIGN KEY(product_id) REFERENCES Products(id)
);
-- Chèn dữ liệu mẫu

-- Thêm vai trò
INSERT INTO Roles (RoleName, Description) VALUES
('Admin', N'Quản trị viên hệ thống'),
('Customer', N'Khách hàng'),
('Staff', N'Nhân viên'),
('Supplier', N'Nhà cung cấp');

-- Thêm trạng thái đơn hàng
INSERT INTO OrderStatuses (StatusName, Description, SortOrder, Color) VALUES
(N'Chờ xác nhận', N'Đơn hàng mới, chờ xác nhận', 1, '#FFA500'),
(N'Đã xác nhận', N'Đơn hàng đã được xác nhận', 2, '#0066CC'),
(N'Đang chuẩn bị', N'Đang chuẩn bị hàng hóa', 3, '#9966CC'),
(N'Đang giao hàng', N'Đơn hàng đang được giao', 4, '#FF6600'),
(N'Đã giao hàng', N'Đã giao hàng thành công', 5, '#00CC00'),
(N'Đã hủy', N'Đơn hàng đã bị hủy', 6, '#CC0000'),
(N'Hoàn trả', N'Đơn hàng được hoàn trả', 7, '#CC6600');

-- Thêm user admin
INSERT INTO Users (Email, PasswordHash, Salt, FirstName, LastName, PhoneNumber, RoleId, IsActive, IsEmailVerified)
VALUES 
('hungnvvde180650@fpt.edu.vn', '123', 'salt_here', N'Admin', N'System', '0123456789', 1, 1, 1),
('viethungnguyen2004@gmail.com', '123', 'salt_here', N'Nguyễn Văn', N'Việt Hưng', '0987654321', 2, 1, 1);

-- Thêm danh mục sản phẩm
INSERT INTO Categories (CategoryName, Slug, Description, SortOrder, IsActive) VALUES
(N'Rau củ quả', 'rau-cu-qua', N'Các loại rau củ quả tươi ngon', 1, 1),
(N'Trái cây', 'trai-cay', N'Trái cây tươi ngon, giàu vitamin', 2, 1),
(N'Thịt sạch', 'thit-sach', N'Thịt sạch, an toàn', 3, 1),
(N'Hải sản', 'hai-san', N'Hải sản tươi sống', 4, 1),
(N'Gạo & ngũ cốc', 'gao-ngu-coc', N'Gạo và các loại ngũ cốc', 5, 1);

-- Thêm danh mục con
INSERT INTO Categories (CategoryName, Slug, Description, ParentCategoryId, SortOrder, IsActive) VALUES
(N'Rau lá xanh', 'rau-la-xanh', N'Các loại rau lá xanh', 1, 1, 1),
(N'Củ quả', 'cu-qua', N'Các loại củ quả', 1, 2, 1),
(N'Trái cây nhập khẩu', 'trai-cay-nhap-khau', N'Trái cây nhập khẩu chất lượng cao', 2, 1, 1),
(N'Trái cây trong nước', 'trai-cay-trong-nuoc', N'Trái cây Việt Nam', 2, 2, 1);

-- Thêm thương hiệu
INSERT INTO Brands (BrandName, Slug, Description, IsActive) VALUES
(N'Organic Farm', 'organic-farm', N'Trang trại hữu cơ uy tín', 1),
(N'Green Valley', 'green-valley', N'Thung lũng xanh', 1),
(N'Fresh Garden', 'fresh-garden', N'Vườn tươi mát', 1),
(N'VietGAP', 'vietgap', N'Sản phẩm đạt chuẩn VietGAP', 1);

-- Thêm nhà cung cấp
INSERT INTO Suppliers (SupplierName, ContactPerson, Email, PhoneNumber, Address, IsActive) VALUES
(N'Trang trại Đà Lạt', N'Nguyễn Văn B', 'dalat@supplier.com', '0123456789', N'Đà Lạt, Lâm Đồng', 1),
(N'Vườn rau Củ Chi', N'Trần Thị C', 'cuchi@supplier.com', '0987654321', N'Củ Chi, TP.HCM', 1);

-- Thêm thuộc tính sản phẩm
INSERT INTO ProductAttributes (AttributeName, AttributeType, IsRequired, SortOrder) VALUES
(N'Xuất xứ', 'text', 1, 1),
(N'Trọng lượng', 'text', 1, 2),
(N'Hạn sử dụng', 'text', 0, 3),
(N'Cách bảo quản', 'text', 0, 4),
(N'Chứng nhận hữu cơ', 'boolean', 0, 5);

-- Thêm sản phẩm mẫu
INSERT INTO Products (ProductName, Slug, ShortDescription, LongDescription, SKU, Price, ComparePrice, Weight, StockQuantity, IsOrganic, Origin, ExpiryDays, CategoryId, BrandId, SupplierId, IsActive, IsFeatured) VALUES
(N'Rau cải xanh hữu cơ', 'rau-cai-xanh-huu-co', N'Rau cải xanh tươi ngon, không hóa chất', N'Rau cải xanh được trồng theo phương pháp hữu cơ, không sử dụng thuốc trừ sâu và phân bón hóa học. Giàu vitamin A, C, K và các khoáng chất thiết yếu.', 'RCX001', 25000, 30000, 0.5, 100, 1, N'Đà Lạt', 5, 6, 1, 1, 1, 1),
(N'Cà chua cherry Đà Lạt', 'ca-chua-cherry-da-lat', N'Cà chua cherry ngọt tự nhiên', N'Cà chua cherry Đà Lạt có vị ngọt tự nhiên, giàu lycopene và vitamin C. Thích hợp ăn tươi hoặc làm salad.', 'CCH001', 45000, 55000, 0.25, 80, 0, N'Đà Lạt', 7, 6, 2, 1, 1, 1),
(N'Gạo hữu cơ ST25', 'gao-huu-co-st25', N'Gạo thơm ngon, dinh dưỡng', N'Gạo ST25 được trồng theo phương pháp hữu cơ, hạt dài, thơm ngon và giàu dinh dưỡng.', 'GHC001', 85000, 85000, 5.0, 50, 1, N'An Giang', 365, 5, 4, 2, 1, 1),
(N'Táo Fuji Nhật Bản', 'tao-fuji-nhat-ban', N'Táo Fuji giòn ngọt', N'Táo Fuji nhập khẩu từ Nhật Bản, giòn ngọt, giàu vitamin và chất xơ.', 'TFJ001', 120000, 120000, 1.0, 30, 0, N'Nhật Bản', 14, 8, 3, NULL, 1, 1);

-- Thêm hình ảnh sản phẩm
INSERT INTO ProductImages (ProductId, ImageUrl, AltText, SortOrder, IsMain) VALUES
(1, 'https://product.hstatic.net/200000423303/product/cai-xanh-huu-co_6e554418635142bab42cb6cbb78c27ce_1024x1024.jpg', N'Rau cải xanh hữu cơ', 1, 1),
(1, 'https://lh3.googleusercontent.com/mnN-VYO-QzTKIkAnRvJ54qHS9RRi6qY9BT4QKtuXRK0F4irwtoSqnXA-Xibwo4bwi0OXLTiSdkOKWslMOvqXbCoi8PbpvOFk', N'Cải ngọt hữu cơ Đại Ngàn', 2, 0),
(2, 'https://dalattungtrinh.vn/wp-content/uploads/2024/08/ca-chua-cherry-1.jpg', N'Cà chua cherry Đà Lạt', 1, 1),
(3, 'https://cdn.tgdd.vn/2021/06/CookProduct/thumbgao-1200x676.jpg', N'Gạo hữu cơ ST25', 1, 1),
(4, 'https://product.hstatic.net/200000528965/product/hop-qua-tao-fuji-nhat-ban-hop-04-qua_7c4a5ae6ac14419d839a8c26e7314637_master.jpg', N'Táo Fuji Nhật Bản', 1, 1);

-- Thêm giá trị thuộc tính cho sản phẩm
INSERT INTO ProductAttributeValues (ProductId, AttributeId, AttributeValue) VALUES
(1, 1, N'Đà Lạt, Việt Nam'),
(1, 2, N'500g'),
(1, 3, N'3-5 ngày'),
(1, 4, N'Bảo quản trong tủ lạnh 2-8°C'),
(1, 5, N'Có'),
(2, 1, N'Đà Lạt, Việt Nam'),
(2, 2, N'250g'),
(2, 3, N'5-7 ngày'),
(3, 1, N'An Giang, Việt Nam'),
(3, 2, N'5kg'),
(3, 3, N'12 tháng'),
(3, 5, N'Có'),
(4, 1, N'Nhật Bản'),
(4, 2, N'1kg'),
(4, 3, N'2 tuần');

-- Thêm mã giảm giá
INSERT INTO Coupons (CouponCode, CouponName, Description, DiscountType, DiscountValue, MinOrderAmount, UsageLimit, StartDate, EndDate, IsActive) VALUES
('FRESH10', N'Giảm 10% đơn hàng đầu tiên', N'Giảm 10% cho đơn hàng đầu tiên, áp dụng cho đơn hàng từ 200k', 'percentage', 10, 200000, 100, GETDATE(), DATEADD(MONTH, 1, GETDATE()), 1),
('NEWUSER', N'Giảm 50k cho khách hàng mới', N'Giảm 50,000đ cho khách hàng mới đăng ký', 'fixed', 50000, 100000, 50, GETDATE(), DATEADD(MONTH, 1, GETDATE()), 1),
('ORGANIC20', N'Giảm 20% sản phẩm hữu cơ', N'Giảm 20% cho tất cả sản phẩm hữu cơ', 'percentage', 20, 150000, 200, GETDATE(), DATEADD(MONTH, 2, GETDATE()), 1);

-- Thêm phương thức vận chuyển
INSERT INTO ShippingMethods (MethodName, Description, Cost, EstimatedDays, IsActive) VALUES
(N'Giao hàng nhanh (2-4h)', N'Giao hàng trong ngày tại TP.HCM', 25000, 0, 1),
(N'Giao hàng tiêu chuẩn', N'Giao hàng trong 1-2 ngày', 15000, 1, 1),
(N'Giao hàng miễn phí', N'Miễn phí giao hàng cho đơn từ 200k', 0, 2, 1);

-- Thêm cấu hình hệ thống
INSERT INTO SystemSettings (SettingKey, SettingValue, Description, DataType, IsPublic) VALUES
('site_name', 'Green Fresh', N'Tên website', 'string', 1),
('site_description', N'Thực phẩm xanh sạch cho sức khỏe gia đình', N'Mô tả website', 'string', 1),
('contact_email', 'info@greenfresh.vn', N'Email liên hệ', 'string', 1),
('contact_phone', '1900 1234', N'Số điện thoại liên hệ', 'string', 1),
('free_shipping_threshold', '200000', N'Miễn phí ship từ số tiền', 'number', 1),
('currency_symbol', 'đ', N'Ký hiệu tiền tệ', 'string', 1),
('tax_rate', '0', N'Thuế VAT (%)', 'number', 0),
('items_per_page', '12', N'Số sản phẩm hiển thị mỗi trang', 'number', 1);
