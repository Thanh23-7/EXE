
CREATE DATABASE VeggiesDB;
USE VeggiesDB;

-- Bảng vai trò người dùng
CREATE TABLE Roles (
    RoleId INT PRIMARY KEY IDENTITY(1,1),
    RoleName NVARCHAR(50) NOT NULL UNIQUE,
    Description NVARCHAR(200),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE()
);

-- Bảng người dùng
CREATE TABLE Users (
    UserId INT PRIMARY KEY IDENTITY(1,1),
    Email NVARCHAR(255) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,
    Salt NVARCHAR(255) NOT NULL,
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    PhoneNumber NVARCHAR(20),
    DateOfBirth DATE,
    Gender NVARCHAR(10) CHECK (Gender IN (N'Nam', N'Nữ', N'Khác')),
    Avatar NVARCHAR(500),
    IsActive BIT DEFAULT 1,
    IsEmailVerified BIT DEFAULT 0,
    EmailVerificationToken NVARCHAR(255),
    PasswordResetToken NVARCHAR(255),
    PasswordResetExpires DATETIME2,
    LastLoginAt DATETIME2,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE(),
    RoleId INT NOT NULL,
    FOREIGN KEY (RoleId) REFERENCES Roles(RoleId)
);

-- Bảng địa chỉ người dùng
CREATE TABLE UserAddresses (
    AddressId INT PRIMARY KEY IDENTITY(1,1),
    UserId INT NOT NULL,
    AddressType NVARCHAR(20) CHECK (AddressType IN (N'Nhà', N'Văn phòng', N'Khác')) DEFAULT N'Nhà',
    RecipientName NVARCHAR(200) NOT NULL,
    PhoneNumber NVARCHAR(20) NOT NULL,
    AddressLine1 NVARCHAR(500) NOT NULL,
    AddressLine2 NVARCHAR(500),
    Ward NVARCHAR(100) NOT NULL,
    District NVARCHAR(100) NOT NULL,
    City NVARCHAR(100) NOT NULL,
    PostalCode NVARCHAR(20),
    IsDefault BIT DEFAULT 0,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE
);

-- Bảng danh mục sản phẩm
CREATE TABLE Categories (
    CategoryId INT PRIMARY KEY IDENTITY(1,1),
    CategoryName NVARCHAR(200) NOT NULL,
    Slug NVARCHAR(200) NOT NULL UNIQUE,
    Description NVARCHAR(1000),
    ImageUrl NVARCHAR(500),
    ParentCategoryId INT NULL,
    SortOrder INT DEFAULT 0,
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (ParentCategoryId) REFERENCES Categories(CategoryId)
);

-- Bảng thương hiệu
CREATE TABLE Brands (
    BrandId INT PRIMARY KEY IDENTITY(1,1),
    BrandName NVARCHAR(200) NOT NULL UNIQUE,
    Slug NVARCHAR(200) NOT NULL UNIQUE,
    Description NVARCHAR(1000),
    LogoUrl NVARCHAR(500),
    Website NVARCHAR(500),
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE()
);

-- Bảng nhà cung cấp
CREATE TABLE Suppliers (
    SupplierId INT PRIMARY KEY IDENTITY(1,1),
    SupplierName NVARCHAR(200) NOT NULL,
    ContactPerson NVARCHAR(200),
    Email NVARCHAR(255),
    PhoneNumber NVARCHAR(20),
    Address NVARCHAR(500),
    TaxCode NVARCHAR(50),
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE()
);

-- Bảng sản phẩm
CREATE TABLE Products (
    ProductId INT PRIMARY KEY IDENTITY(1,1),
    ProductName NVARCHAR(500) NOT NULL,
    Slug NVARCHAR(500) NOT NULL UNIQUE,
    ShortDescription NVARCHAR(1000),
    LongDescription NVARCHAR(MAX),
    SKU NVARCHAR(100) NOT NULL UNIQUE,
    Price DECIMAL(18,2) NOT NULL,
    ComparePrice DECIMAL(18,2), -- Giá gốc để hiển thị giảm giá
    CostPrice DECIMAL(18,2), -- Giá vốn
    Weight DECIMAL(10,3), -- Trọng lượng (kg)
    Unit NVARCHAR(50) DEFAULT N'Kg', -- Đơn vị tính
    StockQuantity INT DEFAULT 0,
    MinStockLevel INT DEFAULT 0, -- Mức tồn kho tối thiểu
    MaxStockLevel INT DEFAULT 1000, -- Mức tồn kho tối đa
    IsOrganic BIT DEFAULT 0, -- Sản phẩm hữu cơ
    Origin NVARCHAR(200), -- Xuất xứ
    ExpiryDays INT, -- Số ngày hết hạn
    StorageInstructions NVARCHAR(1000), -- Hướng dẫn bảo quản
    NutritionalInfo NVARCHAR(MAX), -- Thông tin dinh dưỡng (JSON)
    IsActive BIT DEFAULT 1,
    IsFeatured BIT DEFAULT 0, -- Sản phẩm nổi bật
    ViewCount INT DEFAULT 0,
    SoldCount INT DEFAULT 0,
    Rating DECIMAL(3,2) DEFAULT 0, -- Đánh giá trung bình
    ReviewCount INT DEFAULT 0,
    MetaTitle NVARCHAR(200),
    MetaDescription NVARCHAR(500),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE(),
    CategoryId INT NOT NULL,
    BrandId INT,
    SupplierId INT,
    FOREIGN KEY (CategoryId) REFERENCES Categories(CategoryId),
    FOREIGN KEY (BrandId) REFERENCES Brands(BrandId),
    FOREIGN KEY (SupplierId) REFERENCES Suppliers(SupplierId)
);

-- Bảng hình ảnh sản phẩm
CREATE TABLE ProductImages (
    ImageId INT PRIMARY KEY IDENTITY(1,1),
    ProductId INT NOT NULL,
    ImageUrl NVARCHAR(500) NOT NULL,
    AltText NVARCHAR(200),
    SortOrder INT DEFAULT 0,
    IsMain BIT DEFAULT 0, -- Ảnh chính
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (ProductId) REFERENCES Products(ProductId) ON DELETE CASCADE
);

-- Bảng thuộc tính sản phẩm (như màu sắc, kích thước)
CREATE TABLE ProductAttributes (
    AttributeId INT PRIMARY KEY IDENTITY(1,1),
    AttributeName NVARCHAR(100) NOT NULL UNIQUE,
    AttributeType NVARCHAR(50) DEFAULT 'text', -- text, number, boolean, select
    IsRequired BIT DEFAULT 0,
    SortOrder INT DEFAULT 0,
    CreatedAt DATETIME2 DEFAULT GETDATE()
);

-- Bảng giá trị thuộc tính sản phẩm
CREATE TABLE ProductAttributeValues (
    ValueId INT PRIMARY KEY IDENTITY(1,1),
    ProductId INT NOT NULL,
    AttributeId INT NOT NULL,
    AttributeValue NVARCHAR(500) NOT NULL,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (ProductId) REFERENCES Products(ProductId) ON DELETE CASCADE,
    FOREIGN KEY (AttributeId) REFERENCES ProductAttributes(AttributeId),
    UNIQUE(ProductId, AttributeId)
);

-- Bảng đánh giá sản phẩm
CREATE TABLE ProductReviews (
    ReviewId INT PRIMARY KEY IDENTITY(1,1),
    ProductId INT NOT NULL,
    UserId INT NOT NULL,
    Rating INT CHECK (Rating >= 1 AND Rating <= 5) NOT NULL,
    Title NVARCHAR(200),
    Comment NVARCHAR(2000),
    IsVerifiedPurchase BIT DEFAULT 0,
    IsApproved BIT DEFAULT 0,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (ProductId) REFERENCES Products(ProductId) ON DELETE CASCADE,
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    UNIQUE(ProductId, UserId) -- Mỗi user chỉ đánh giá 1 lần cho 1 sản phẩm
);

-- Bảng giỏ hàng
CREATE TABLE ShoppingCarts (
    CartId INT PRIMARY KEY IDENTITY(1,1),
    UserId INT,
    SessionId NVARCHAR(255), -- Cho guest users
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE
);

-- Bảng chi tiết giỏ hàng
CREATE TABLE CartItems (
    CartItemId INT PRIMARY KEY IDENTITY(1,1),
    CartId INT NOT NULL,
    ProductId INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    Price DECIMAL(18,2) NOT NULL, -- Giá tại thời điểm thêm vào giỏ
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (CartId) REFERENCES ShoppingCarts(CartId) ON DELETE CASCADE,
    FOREIGN KEY (ProductId) REFERENCES Products(ProductId),
    UNIQUE(CartId, ProductId)
);

-- Bảng sản phẩm yêu thích
CREATE TABLE Wishlists (
    WishlistId INT PRIMARY KEY IDENTITY(1,1),
    UserId INT NOT NULL,
    ProductId INT NOT NULL,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    FOREIGN KEY (ProductId) REFERENCES Products(ProductId) ON DELETE CASCADE,
    UNIQUE(UserId, ProductId)
);

-- Bảng mã giảm giá
CREATE TABLE Coupons (
    CouponId INT PRIMARY KEY IDENTITY(1,1),
    CouponCode NVARCHAR(50) NOT NULL UNIQUE,
    CouponName NVARCHAR(200) NOT NULL,
    Description NVARCHAR(1000),
    DiscountType NVARCHAR(20) CHECK (DiscountType IN ('percentage', 'fixed')) NOT NULL,
    DiscountValue DECIMAL(18,2) NOT NULL,
    MinOrderAmount DECIMAL(18,2) DEFAULT 0,
    MaxDiscountAmount DECIMAL(18,2), -- Giới hạn số tiền giảm tối đa
    UsageLimit INT, -- Giới hạn số lần sử dụng
    UsageCount INT DEFAULT 0, -- Số lần đã sử dụng
    UsageLimitPerUser INT DEFAULT 1, -- Giới hạn số lần sử dụng per user
    StartDate DATETIME2 NOT NULL,
    EndDate DATETIME2 NOT NULL,
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE()
);

-- Bảng lịch sử sử dụng coupon
CREATE TABLE CouponUsages (
    UsageId INT PRIMARY KEY IDENTITY(1,1),
    CouponId INT NOT NULL,
    UserId INT NOT NULL,
    OrderId INT, -- Sẽ tạo sau
    UsedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (CouponId) REFERENCES Coupons(CouponId),
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
);

-- Bảng trạng thái đơn hàng
CREATE TABLE OrderStatuses (
    StatusId INT PRIMARY KEY IDENTITY(1,1),
    StatusName NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(500),
    SortOrder INT DEFAULT 0,
    Color NVARCHAR(20) DEFAULT '#000000', -- Màu hiển thị
    CreatedAt DATETIME2 DEFAULT GETDATE()
);

-- Bảng đơn hàng
CREATE TABLE Orders (
    OrderId INT PRIMARY KEY IDENTITY(1,1),
    OrderNumber NVARCHAR(50) NOT NULL UNIQUE,
    UserId INT,
    CustomerEmail NVARCHAR(255) NOT NULL,
    CustomerPhone NVARCHAR(20) NOT NULL,
    
    -- Thông tin giao hàng
    ShippingName NVARCHAR(200) NOT NULL,
    ShippingPhone NVARCHAR(20) NOT NULL,
    ShippingAddress NVARCHAR(500) NOT NULL,
    ShippingWard NVARCHAR(100) NOT NULL,
    ShippingDistrict NVARCHAR(100) NOT NULL,
    ShippingCity NVARCHAR(100) NOT NULL,
    ShippingPostalCode NVARCHAR(20),
    
    -- Thông tin thanh toán
    BillingName NVARCHAR(200),
    BillingPhone NVARCHAR(20),
    BillingAddress NVARCHAR(500),
    BillingWard NVARCHAR(100),
    BillingDistrict NVARCHAR(100),
    BillingCity NVARCHAR(100),
    BillingPostalCode NVARCHAR(20),
    
    -- Thông tin đơn hàng
    SubTotal DECIMAL(18,2) NOT NULL, -- Tổng tiền hàng
    ShippingFee DECIMAL(18,2) DEFAULT 0,
    TaxAmount DECIMAL(18,2) DEFAULT 0,
    DiscountAmount DECIMAL(18,2) DEFAULT 0,
    TotalAmount DECIMAL(18,2) NOT NULL, -- Tổng tiền cuối cùng
    
    -- Thông tin thanh toán
    PaymentMethod NVARCHAR(50) NOT NULL, -- COD, Bank Transfer, Credit Card, etc.
    PaymentStatus NVARCHAR(50) DEFAULT 'Pending', -- Pending, Paid, Failed, Refunded
    PaidAt DATETIME2,
    
    -- Ghi chú và trạng thái
    OrderNotes NVARCHAR(2000),
    StatusId INT NOT NULL,
    
    -- Thông tin coupon
    CouponId INT,
    CouponCode NVARCHAR(50),
    CouponDiscount DECIMAL(18,2) DEFAULT 0,
    
    -- Thời gian
    OrderDate DATETIME2 DEFAULT GETDATE(),
    RequiredDate DATETIME2,
    ShippedDate DATETIME2,
    DeliveredDate DATETIME2,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE(),
    
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (StatusId) REFERENCES OrderStatuses(StatusId),
    FOREIGN KEY (CouponId) REFERENCES Coupons(CouponId)
);

-- Bảng chi tiết đơn hàng
CREATE TABLE OrderItems (
    OrderItemId INT PRIMARY KEY IDENTITY(1,1),
    OrderId INT NOT NULL,
    ProductId INT NOT NULL,
    ProductName NVARCHAR(500) NOT NULL, -- Lưu tên sản phẩm tại thời điểm đặt hàng
    ProductSKU NVARCHAR(100) NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    UnitPrice DECIMAL(18,2) NOT NULL, -- Giá tại thời điểm đặt hàng
    TotalPrice DECIMAL(18,2) NOT NULL, -- Quantity * UnitPrice
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (OrderId) REFERENCES Orders(OrderId) ON DELETE CASCADE,
    FOREIGN KEY (ProductId) REFERENCES Products(ProductId)
);

-- Bảng lịch sử trạng thái đơn hàng
CREATE TABLE OrderStatusHistory (
    HistoryId INT PRIMARY KEY IDENTITY(1,1),
    OrderId INT NOT NULL,
    StatusId INT NOT NULL,
    Notes NVARCHAR(1000),
    CreatedBy INT, -- UserId của người thay đổi trạng thái
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (OrderId) REFERENCES Orders(OrderId) ON DELETE CASCADE,
    FOREIGN KEY (StatusId) REFERENCES OrderStatuses(StatusId),
    FOREIGN KEY (CreatedBy) REFERENCES Users(UserId)
);

-- Bảng phương thức vận chuyển
CREATE TABLE ShippingMethods (
    ShippingMethodId INT PRIMARY KEY IDENTITY(1,1),
    MethodName NVARCHAR(200) NOT NULL,
    Description NVARCHAR(1000),
    Cost DECIMAL(18,2) NOT NULL,
    EstimatedDays INT, -- Số ngày dự kiến giao hàng
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE()
);

-- Bảng newsletter subscribers
CREATE TABLE NewsletterSubscribers (
    SubscriberId INT PRIMARY KEY IDENTITY(1,1),
    Email NVARCHAR(255) NOT NULL UNIQUE,
    FirstName NVARCHAR(100),
    LastName NVARCHAR(100),
    IsActive BIT DEFAULT 1,
    SubscribedAt DATETIME2 DEFAULT GETDATE(),
    UnsubscribedAt DATETIME2,
    UnsubscribeToken NVARCHAR(255)
);

-- Bảng liên hệ
CREATE TABLE ContactMessages (
    MessageId INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(200) NOT NULL,
    Email NVARCHAR(255) NOT NULL,
    Phone NVARCHAR(20),
    Subject NVARCHAR(500) NOT NULL,
    Message NVARCHAR(MAX) NOT NULL,
    IsRead BIT DEFAULT 0,
    IsReplied BIT DEFAULT 0,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    ReadAt DATETIME2,
    RepliedAt DATETIME2
);

-- Bảng cấu hình hệ thống
CREATE TABLE SystemSettings (
    SettingId INT PRIMARY KEY IDENTITY(1,1),
    SettingKey NVARCHAR(100) NOT NULL UNIQUE,
    SettingValue NVARCHAR(MAX),
    Description NVARCHAR(500),
    DataType NVARCHAR(50) DEFAULT 'string', -- string, number, boolean, json
    IsPublic BIT DEFAULT 0, -- Có thể truy cập từ frontend không
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE()
);

-- Bảng log hoạt động
CREATE TABLE ActivityLogs (
    LogId INT PRIMARY KEY IDENTITY(1,1),
    UserId INT,
    Action NVARCHAR(100) NOT NULL, -- login, logout, create_order, etc.
    EntityType NVARCHAR(100), -- Product, Order, User, etc.
    EntityId INT,
    Description NVARCHAR(1000),
    IpAddress NVARCHAR(45),
    UserAgent NVARCHAR(1000),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
);
