-- 1. TẠO DATABASE & TABLE
DROP DATABASE IF EXISTS ShopDB;
CREATE DATABASE ShopDB;
USE ShopDB;

-- Bảng sản phẩm
DROP TABLE IF EXISTS products;
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    stock INT NOT NULL CHECK (stock >= 0),
    price DECIMAL(10,2) NOT NULL
);

-- Bảng đơn hàng
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- 2. DỮ LIỆU MẪU
INSERT INTO products (product_name, stock, price) VALUES
('Laptop', 10, 1500.00),
('Mouse', 50, 20.00),
('Keyboard', 30, 45.00);

-- Kiểm tra dữ liệu ban đầu
SELECT * FROM products;

-- 3. STORED PROCEDURE ĐẶT HÀNG
DELIMITER //

CREATE PROCEDURE sp_place_order (
    IN p_product_id INT,
    IN p_quantity INT
)
BEGIN
    DECLARE current_stock INT;

    -- Bắt lỗi SQL → rollback
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Có lỗi xảy ra, giao dịch đã bị rollback';
    END;

    -- Lấy số lượng tồn kho và khóa dòng
    SELECT stock
    INTO current_stock
    FROM products
    WHERE product_id = p_product_id
    FOR UPDATE;

    -- Kiểm tra tồn kho
    IF current_stock < p_quantity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Số lượng tồn kho không đủ';
    END IF;

    -- Bắt đầu Transaction
    START TRANSACTION;

        -- Tạo đơn hàng
        INSERT INTO orders (product_id, quantity)
        VALUES (p_product_id, p_quantity);

        -- Cập nhật tồn kho
        UPDATE products
        SET stock = stock - p_quantity
        WHERE product_id = p_product_id;

    COMMIT;
END//

DELIMITER ;

-- Case 1: Đặt hàng hợp lệ (Laptop, mua 2)
CALL sp_place_order(1, 2);

-- Kiểm tra kết quả
SELECT * FROM products;
SELECT * FROM orders;

-- Kiểm tra lại dữ liệu
SELECT * FROM products;
SELECT * FROM orders;
