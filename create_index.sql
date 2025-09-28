-- Tạo các index để tối ưu hiệu suất

-- Index cho bảng Users
CREATE INDEX IX_Users_Email ON Users(Email);
CREATE INDEX IX_Users_RoleId ON Users(RoleId);
CREATE INDEX IX_Users_IsActive ON Users(IsActive);
CREATE INDEX IX_Users_CreatedAt ON Users(CreatedAt);

-- Index cho bảng Products
CREATE INDEX IX_Products_CategoryId ON Products(CategoryId);
CREATE INDEX IX_Products_BrandId ON Products(BrandId);
CREATE INDEX IX_Products_IsActive ON Products(IsActive);
CREATE INDEX IX_Products_IsFeatured ON Products(IsFeatured);
CREATE INDEX IX_Products_Price ON Products(Price);
CREATE INDEX IX_Products_CreatedAt ON Products(CreatedAt);
CREATE INDEX IX_Products_Rating ON Products(Rating);
CREATE INDEX IX_Products_SoldCount ON Products(SoldCount);
CREATE INDEX IX_Products_Slug ON Products(Slug);

-- Index cho bảng Orders
CREATE INDEX IX_Orders_UserId ON Orders(UserId);
CREATE INDEX IX_Orders_StatusId ON Orders(StatusId);
CREATE INDEX IX_Orders_OrderDate ON Orders(OrderDate);
CREATE INDEX IX_Orders_PaymentStatus ON Orders(PaymentStatus);
CREATE INDEX IX_Orders_OrderNumber ON Orders(OrderNumber);

-- Index cho bảng OrderItems
CREATE INDEX IX_OrderItems_OrderId ON OrderItems(OrderId);
CREATE INDEX IX_OrderItems_ProductId ON OrderItems(ProductId);

-- Index cho bảng ProductReviews
CREATE INDEX IX_ProductReviews_ProductId ON ProductReviews(ProductId);
CREATE INDEX IX_ProductReviews_UserId ON ProductReviews(UserId);
CREATE INDEX IX_ProductReviews_IsApproved ON ProductReviews(IsApproved);

-- Index cho bảng Categories
CREATE INDEX IX_Categories_ParentCategoryId ON Categories(ParentCategoryId);
CREATE INDEX IX_Categories_IsActive ON Categories(IsActive);
CREATE INDEX IX_Categories_Slug ON Categories(Slug);

-- Index cho bảng CartItems
CREATE INDEX IX_CartItems_CartId ON CartItems(CartId);
CREATE INDEX IX_CartItems_ProductId ON CartItems(ProductId);

-- Index cho bảng ShoppingCarts
CREATE INDEX IX_ShoppingCarts_UserId ON ShoppingCarts(UserId);
CREATE INDEX IX_ShoppingCarts_SessionId ON ShoppingCarts(SessionId);

-- Index cho bảng Coupons
CREATE INDEX IX_Coupons_CouponCode ON Coupons(CouponCode);
CREATE INDEX IX_Coupons_IsActive ON Coupons(IsActive);
CREATE INDEX IX_Coupons_StartDate_EndDate ON Coupons(StartDate, EndDate);

-- Index cho bảng ActivityLogs
CREATE INDEX IX_ActivityLogs_UserId ON ActivityLogs(UserId);
CREATE INDEX IX_ActivityLogs_Action ON ActivityLogs(Action);
CREATE INDEX IX_ActivityLogs_CreatedAt ON ActivityLogs(CreatedAt);
