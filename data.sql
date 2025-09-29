-- *** DATA.SQL ĐÃ CHUYỂN SANG CÚ PHÁP T-SQL (MS SQL SERVER) ***

-- CHỈ DÙNG KHI TESTING/KHỞI TẠO: XÓA CÁC BẢNG ĐỂ TẠO LẠI
-- SỬ DỤNG CÚ PHÁP T-SQL DROP TABLE ĐẦY ĐỦ
IF OBJECT_ID('ProductJourney', 'U') IS NOT NULL DROP TABLE ProductJourney;
IF OBJECT_ID('PurchaseHistory', 'U') IS NOT NULL DROP TABLE PurchaseHistory;
IF OBJECT_ID('ChatMessage', 'U') IS NOT NULL DROP TABLE ChatMessage;
IF OBJECT_ID('ProductAttributeValues', 'U') IS NOT NULL DROP TABLE ProductAttributeValues;
IF OBJECT_ID('ProductImages', 'U') IS NOT NULL DROP TABLE ProductImages;
IF OBJECT_ID('Products', 'U') IS NOT NULL DROP TABLE Products;
IF OBJECT_ID('Categories', 'U') IS NOT NULL DROP TABLE Categories;
IF OBJECT_ID('Brands', 'U') IS NOT NULL DROP TABLE Brands;
IF OBJECT_ID('Suppliers', 'U') IS NOT NULL DROP TABLE Suppliers;
IF OBJECT_ID('ProductAttributes', 'U') IS NOT NULL DROP TABLE ProductAttributes;
IF OBJECT_ID('Coupons', 'U') IS NOT NULL DROP TABLE Coupons;
IF OBJECT_ID('ShippingMethods', 'U') IS NOT NULL DROP TABLE ShippingMethods;
IF OBJECT_ID('SystemSettings', 'U') IS NOT NULL DROP TABLE SystemSettings;
IF OBJECT_ID('Users', 'U') IS NOT NULL DROP TABLE Users;
IF OBJECT_ID('OrderStatuses', 'U') IS NOT NULL DROP TABLE OrderStatuses;
IF OBJECT_ID('Roles', 'U') IS NOT NULL DROP TABLE Roles;


-- =======================================================================
-- 1. TẠO CÁC BẢNG CƠ SỞ (ĐÃ SỬA CÚ PHÁP T-SQL: IDENTITY(1,1) và SỬA DẤU PHẨY)
-- =======================================================================

CREATE TABLE Roles (
    id INT IDENTITY(1,1) PRIMARY KEY,
    RoleName NVARCHAR(255) NOT NULL UNIQUE,
    Description NVARCHAR(MAX) -- Bỏ dấu phẩy ở cột cuối
);

CREATE TABLE OrderStatuses (
    id INT IDENTITY(1,1) PRIMARY KEY,
    StatusName NVARCHAR(255) NOT NULL UNIQUE,
    Description NVARCHAR(MAX),
    SortOrder INT,
    Color NVARCHAR(50) -- Bỏ dấu phẩy ở cột cuối
);

CREATE TABLE Users (
    id INT IDENTITY(1,1) PRIMARY KEY,
    Email NVARCHAR(255) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(MAX) NOT NULL,
    Salt NVARCHAR(MAX),
    FirstName NVARCHAR(255),
    LastName NVARCHAR(255),
    PhoneNumber NVARCHAR(20),
    RoleId INT,
    IsActive BIT DEFAULT 1,
    IsEmailVerified BIT DEFAULT 0,
    FOREIGN KEY(RoleId) REFERENCES Roles(id) -- Bỏ dấu phẩy ở cột cuối
);

CREATE TABLE Categories (
    id INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(255) NOT NULL,
    Slug NVARCHAR(255) NOT NULL UNIQUE,
    Description NVARCHAR(MAX),
    ParentCategoryId INT,
    SortOrder INT,
    IsActive BIT DEFAULT 1,
    FOREIGN KEY(ParentCategoryId) REFERENCES Categories(id) -- Bỏ dấu phẩy ở cột cuối
);

CREATE TABLE Brands (
    id INT IDENTITY(1,1) PRIMARY KEY,
    BrandName NVARCHAR(255) NOT NULL UNIQUE,
    Slug NVARCHAR(255) NOT NULL UNIQUE,
    Description NVARCHAR(MAX),
    IsActive BIT DEFAULT 1 -- Bỏ dấu phẩy ở cột cuối
);

CREATE TABLE Suppliers (
    id INT IDENTITY(1,1) PRIMARY KEY,
    SupplierName NVARCHAR(255) NOT NULL,
    ContactPerson NVARCHAR(255),
    Email NVARCHAR(255),
    PhoneNumber NVARCHAR(20),
    Address NVARCHAR(MAX),
    IsActive BIT DEFAULT 1 -- Bỏ dấu phẩy ở cột cuối
);

CREATE TABLE ProductAttributes (
    id INT IDENTITY(1,1) PRIMARY KEY,
    AttributeName NVARCHAR(255) NOT NULL,
    AttributeType NVARCHAR(50),
    IsRequired BIT DEFAULT 0,
    SortOrder INT -- Bỏ dấu phẩy ở cột cuối
);

-- BẢNG PRODUCTS 
CREATE TABLE Products (
    id INT IDENTITY(1,1) PRIMARY KEY,
    ProductName NVARCHAR(255) NOT NULL,
    Slug NVARCHAR(255) NOT NULL UNIQUE,
    ShortDescription NVARCHAR(MAX),
    LongDescription NVARCHAR(MAX),
    SKU NVARCHAR(50) UNIQUE,
    Price DECIMAL(18, 2) NOT NULL,
    ComparePrice DECIMAL(18, 2),
    Weight REAL,
    StockQuantity INT,
    IsOrganic BIT,
    Origin NVARCHAR(255),
    ExpiryDays INT,
    CategoryId INT,
    BrandId INT,
    SupplierId INT,
    IsActive BIT DEFAULT 1,
    IsFeatured BIT DEFAULT 0,
    FOREIGN KEY(CategoryId) REFERENCES Categories(id),
    FOREIGN KEY(BrandId) REFERENCES Brands(id),
    FOREIGN KEY(SupplierId) REFERENCES Suppliers(id) -- Bỏ dấu phẩy ở cột cuối
);

-- Bảng lưu tin nhắn chat giữa user và admin
CREATE TABLE ChatMessage (
    id INT IDENTITY(1,1) PRIMARY KEY,
    sender NVARCHAR(255), 
    receiver NVARCHAR(255),
    message NVARCHAR(MAX),
    sent_at DATETIME -- Bỏ dấu phẩy ở cột cuối
);
-- Bảng lưu lịch sử mua hàng
CREATE TABLE PurchaseHistory (
    id INT IDENTITY(1,1) PRIMARY KEY,
    user_email NVARCHAR(255),
    product_id INT,
    quantity INT,
    purchased_at DATETIME,
    FOREIGN KEY(product_id) REFERENCES Products(id) -- Bỏ dấu phẩy ở cột cuối
);
-- Bảng ghi lại hành trình sản phẩm
CREATE TABLE ProductJourney (
    id INT IDENTITY(1,1) PRIMARY KEY,
    product_id INT,
    stage NVARCHAR(255), 
    description NVARCHAR(MAX),
    date DATETIME,
    image NVARCHAR(MAX),
    FOREIGN KEY(product_id) REFERENCES Products(id) -- Bỏ dấu phẩy ở cột cuối
);

CREATE TABLE ProductImages (
    id INT IDENTITY(1,1) PRIMARY KEY,
    ProductId INT NOT NULL,
    ImageUrl NVARCHAR(MAX) NOT NULL,
    AltText NVARCHAR(255),
    SortOrder INT,
    IsMain BIT DEFAULT 0,
    FOREIGN KEY(ProductId) REFERENCES Products(id) -- Bỏ dấu phẩy ở cột cuối
);

CREATE TABLE ProductAttributeValues (
    id INT IDENTITY(1,1) PRIMARY KEY,
    ProductId INT NOT NULL,
    AttributeId INT NOT NULL,
    AttributeValue NVARCHAR(MAX),
    FOREIGN KEY(ProductId) REFERENCES Products(id),
    FOREIGN KEY(AttributeId) REFERENCES ProductAttributes(id) -- Bỏ dấu phẩy ở cột cuối
);

CREATE TABLE Coupons (
    id INT IDENTITY(1,1) PRIMARY KEY,
    CouponCode NVARCHAR(50) NOT NULL UNIQUE,
    CouponName NVARCHAR(255),
    Description NVARCHAR(MAX),
    DiscountType NVARCHAR(50),
    DiscountValue REAL,
    MinOrderAmount DECIMAL(18, 2),
    UsageLimit INT,
    StartDate DATETIME,
    EndDate DATETIME,
    IsActive BIT DEFAULT 1 -- Bỏ dấu phẩy ở cột cuối
);

CREATE TABLE ShippingMethods (
    id INT IDENTITY(1,1) PRIMARY KEY,
    MethodName NVARCHAR(255) NOT NULL,
    Description NVARCHAR(MAX),
    Cost DECIMAL(18, 2),
    EstimatedDays INT,
    IsActive BIT DEFAULT 1 -- Bỏ dấu phẩy ở cột cuối
);

CREATE TABLE SystemSettings (
    id INT IDENTITY(1,1) PRIMARY KEY,
    SettingKey NVARCHAR(50) NOT NULL UNIQUE,
    SettingValue NVARCHAR(MAX),
    Description NVARCHAR(MAX),
    DataType NVARCHAR(50),
    IsPublic BIT DEFAULT 0 -- Bỏ dấu phẩy ở cột cuối
);


-- =======================================================================
-- 2. CHÈN DỮ LIỆU MẪU (Sử dụng cú pháp T-SQL: N'' cho chuỗi Unicode và GETDATE() cho ngày tháng)
-- =======================================================================

-- Thêm vai trò
INSERT INTO Roles (RoleName, Description) VALUES
(N'Admin', N'Quản trị viên hệ thống'),
(N'Customer', N'Khách hàng'),
(N'Staff', N'Nhân viên'),
(N'Supplier', N'Nhà cung cấp');

-- Thêm trạng thái đơn hàng
INSERT INTO OrderStatuses (StatusName, Description, SortOrder, Color) VALUES
(N'Chờ xác nhận', N'Đơn hàng mới, chờ xác nhận', 1, N'#FFA500'),
(N'Đã xác nhận', N'Đơn hàng đã được xác nhận', 2, N'#0066CC'),
(N'Đang chuẩn bị', N'Đang chuẩn bị hàng hóa', 3, N'#9966CC'),
(N'Đang giao hàng', N'Đơn hàng đang được giao', 4, N'#FF6600'),
(N'Đã giao hàng', N'Đã giao hàng thành công', 5, N'#00CC00'),
(N'Đã hủy', N'Đơn hàng đã bị hủy', 6, N'#CC0000'),
(N'Hoàn trả', N'Đơn hàng được hoàn trả', 7, N'#CC6600');

-- Thêm user admin
INSERT INTO Users (Email, PasswordHash, Salt, FirstName, LastName, PhoneNumber, RoleId, IsActive, IsEmailVerified)
VALUES 
(N'hungnvvde180650@fpt.edu.vn', N'123', N'salt_here', N'Admin', N'System', N'0123456789', 1, 1, 1),
(N'viethungnguyen2004@gmail.com', N'123', N'salt_here', N'Nguyễn Văn', N'Việt Hưng', N'0987654321', 2, 1, 1);

-- Thêm danh mục sản phẩm
INSERT INTO Categories (CategoryName, Slug, Description, SortOrder, IsActive) VALUES
(N'Rau củ quả', N'rau-cu-qua', N'Các loại rau củ quả tươi ngon', 1, 1),
(N'Trái cây', N'trai-cay', N'Trái cây tươi ngon, giàu vitamin', 2, 1),
(N'Thịt sạch', N'thit-sach', N'Thịt sạch, an toàn', 3, 1),
(N'Hải sản', N'hai-san', N'Hải sản tươi sống', 4, 1),
(N'Gạo & ngũ cốc', N'gao-ngu-coc', N'Gạo và các loại ngũ cốc', 5, 1);

-- Thêm danh mục con
INSERT INTO Categories (CategoryName, Slug, Description, ParentCategoryId, SortOrder, IsActive) VALUES
(N'Rau lá xanh', N'rau-la-xanh', N'Các loại rau lá xanh', 1, 1, 1),
(N'Củ quả', N'cu-qua', N'Các loại củ quả', 1, 2, 1),
(N'Trái cây nhập khẩu', N'trai-cay-nhap-khau', N'Trái cây nhập khẩu chất lượng cao', 2, 1, 1),
(N'Trái cây trong nước', N'trai-cay-trong-nuoc', N'Trái cây Việt Nam', 2, 2, 1);

-- Thêm thương hiệu
INSERT INTO Brands (BrandName, Slug, Description, IsActive) VALUES
(N'Organic Farm', N'organic-farm', N'Trang trại hữu cơ uy tín', 1),
(N'Green Valley', N'green-valley', N'Thung lũng xanh', 1),
(N'Fresh Garden', N'fresh-garden', N'Vườn tươi mát', 1),
(N'VietGAP', N'vietgap', N'Sản phẩm đạt chuẩn VietGAP', 1);

-- Thêm nhà cung cấp
INSERT INTO Suppliers (SupplierName, ContactPerson, Email, PhoneNumber, Address, IsActive) VALUES
(N'Trang trại Đà Lạt', N'Nguyễn Văn B', N'dalat@supplier.com', N'0123456789', N'Đà Lạt, Lâm Đồng', 1),
(N'Vườn rau Củ Chi', N'Trần Thị C', N'cuchi@supplier.com', N'0987654321', N'Củ Chi, TP.HCM', 1);

-- Thêm thuộc tính sản phẩm
INSERT INTO ProductAttributes (AttributeName, AttributeType, IsRequired, SortOrder) VALUES
(N'Xuất xứ', N'text', 1, 1),
(N'Trọng lượng', N'text', 1, 2),
(N'Hạn sử dụng', N'text', 0, 3),
(N'Cách bảo quản', N'text', 0, 4),
(N'Chứng nhận hữu cơ', N'boolean', 0, 5);

-- Thêm sản phẩm mẫu
INSERT INTO Products (ProductName, Slug, ShortDescription, LongDescription, SKU, Price, ComparePrice, Weight, StockQuantity, IsOrganic, Origin, ExpiryDays, CategoryId, BrandId, SupplierId, IsActive, IsFeatured) VALUES
(N'Rau cải xanh hữu cơ', N'rau-cai-xanh-huu-co', N'Rau cải xanh tươi ngon, không hóa chất', N'Rau cải xanh được trồng theo phương pháp hữu cơ, không sử dụng thuốc trừ sâu và phân bón hóa học. Giàu vitamin A, C, K và các khoáng chất thiết yếu.', N'RCX001', 25000, 30000, 0.5, 100, 1, N'Đà Lạt', 5, 6, 1, 1, 1, 1),
(N'Cà chua cherry Đà Lạt', N'ca-chua-cherry-da-lat', N'Cà chua cherry ngọt tự nhiên', N'Cà chua cherry Đà Lạt có vị ngọt tự nhiên, giàu lycopene và vitamin C. Thích hợp ăn tươi hoặc làm salad.', N'CCH001', 45000, 55000, 0.25, 80, 0, N'Đà Lạt', 7, 6, 2, 1, 1, 1),
(N'Gạo hữu cơ ST25', N'gao-huu-co-st25', N'Gạo thơm ngon, dinh dưỡng', N'Gạo ST25 được trồng theo phương pháp hữu cơ, hạt dài, thơm ngon và giàu dinh dưỡng.', N'GHC001', 85000, 85000, 5.0, 50, 1, N'An Giang', 365, 5, 4, 2, 1, 1),
(N'Táo Fuji Nhật Bản', N'tao-fuji-nhat-ban', N'Táo Fuji giòn ngọt', N'Táo Fuji nhập khẩu từ Nhật Bản, giòn ngọt, giàu vitamin và chất xơ.', N'TFJ001', 120000, 120000, 1.0, 30, 0, N'Nhật Bản', 14, 8, 3, NULL, 1, 1);

-- Thêm hình ảnh sản phẩm
INSERT INTO ProductImages (ProductId, ImageUrl, AltText, SortOrder, IsMain) VALUES
(1, N'https://product.hstatic.net/200000423303/product/cai-xanh-huu-co_6e554418635142bab42cb6cbb78c27ce_1024x1024.jpg', N'Rau cải xanh hữu cơ', 1, 1),
(1, N'https://lh3.googleusercontent.com/mnN-VYO-QzTKIkAnRvJ54qHS9RRi6qY9BT4QKtuXRK0F4irwtoSqnXA-Xibwo4bwi0OXLTiSdkOKWslMOvqXbCoi8PbpvOFk', N'Cải ngọt hữu cơ Đại Ngàn', 2, 0),
(2, N'https://dalattungtrinh.vn/wp-content/uploads/2024/08/ca-chua-cherry-1.jpg', N'Cà chua cherry Đà Lạt', 1, 1),
(3, N'https://cdn.tgddvn/2021/06/CookProduct/thumbgao-1200x676.jpg', N'Gạo hữu cơ ST25', 1, 1),
(4, N'https://product.hstatic.net/200000528965/product/hop-qua-tao-fuji-nhat-ban-hop-04-qua_7c4a5ae6ac14419d839a8c26e7314637_master.jpg', N'Táo Fuji Nhật Bản', 1, 1);

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
(N'FRESH10', N'Giảm 10% đơn hàng đầu tiên', N'Giảm 10% cho đơn hàng đầu tiên, áp dụng cho đơn hàng từ 200k', N'percentage', 10, 200000, 100, GETDATE(), DATEADD(month, 1, GETDATE()), 1),
(N'NEWUSER', N'Giảm 50k cho khách hàng mới', N'Giảm 50,000đ cho khách hàng mới đăng ký', N'fixed', 50000, 100000, 50, GETDATE(), DATEADD(month, 1, GETDATE()), 1),
(N'ORGANIC20', N'Giảm 20% sản phẩm hữu cơ', N'Giảm 20% cho tất cả sản phẩm hữu cơ', N'percentage', 20, 150000, 200, GETDATE(), DATEADD(month, 2, GETDATE()), 1);

-- Thêm phương thức vận chuyển
INSERT INTO ShippingMethods (MethodName, Description, Cost, EstimatedDays, IsActive) VALUES
(N'Giao hàng nhanh (2-4h)', N'Giao hàng trong ngày tại TP.HCM', 25000, 0, 1),
(N'Giao hàng tiêu chuẩn', N'Giao hàng trong 1-2 ngày', 15000, 1, 1),
(N'Giao hàng miễn phí', N'Miễn phí giao hàng cho đơn từ 200k', 0, 2, 1);

-- Thêm cấu hình hệ thống
INSERT INTO SystemSettings (SettingKey, SettingValue, Description, DataType, IsPublic) VALUES
(N'site_name', N'Green Fresh', N'Tên website', N'string', 1),
(N'site_description', N'Thực phẩm xanh sạch cho sức khỏe gia đình', N'Mô tả website', N'string', 1),
(N'contact_email', N'info@greenfresh.vn', N'Email liên hệ', N'string', 1),
(N'contact_phone', N'1900 1234', N'Số điện thoại liên hệ', N'string', 1),
(N'free_shipping_threshold', N'200000', N'Miễn phí ship từ số tiền', N'number', 1),
(N'currency_symbol', N'đ', N'Ký hiệu tiền tệ', N'string', 1),
(N'tax_rate', N'0', N'Thuế VAT (%)', N'number', 0),
(N'items_per_page', N'12', N'Số sản phẩm hiển thị mỗi trang', N'number', 1);