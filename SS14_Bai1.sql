DROP DATABASE IF EXISTS BankDB;
CREATE DATABASE BankDB;
USE BankDB;

DROP TABLE IF EXISTS accounts;

CREATE TABLE accounts (
    account_id INT AUTO_INCREMENT PRIMARY KEY,
    account_name VARCHAR(100) NOT NULL,
    balance DECIMAL(10,2) NOT NULL CHECK (balance >= 0)
);

-- =========================
-- 2. THÊM DỮ LIỆU MẪU
-- =========================
INSERT INTO accounts (account_name, balance) VALUES
('Nguyễn Văn An', 1000.00),
('Trần Thị Bảy', 500.00);

-- Kiểm tra dữ liệu ban đầu
SELECT * FROM accounts;

-- 3. STORED PROCEDURE CHUYỂN TIỀN
DELIMITER //

CREATE PROCEDURE sp_transfer_money (
    IN from_account INT,
    IN to_account INT,
    IN amount DECIMAL(10,2)
)
BEGIN
    DECLARE from_balance DECIMAL(10,2);

    -- Bắt lỗi SQL → rollback
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Có lỗi xảy ra, giao dịch đã bị rollback';
    END;

    -- Lấy số dư tài khoản gửi
    SELECT balance
    INTO from_balance
    FROM accounts
    WHERE account_id = from_account
    FOR UPDATE;

    -- Kiểm tra số dư
    IF from_balance < amount THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Số dư không đủ để thực hiện giao dịch';
    END IF;

    -- Transaction
    START TRANSACTION;

        -- Trừ tiền tài khoản gửi
        UPDATE accounts
        SET balance = balance - amount
        WHERE account_id = from_account;

        -- Cộng tiền tài khoản nhận
        UPDATE accounts
        SET balance = balance + amount
        WHERE account_id = to_account;

    COMMIT;
END//

DELIMITER ;

-- 4. GỌI STORED PROCEDURE
CALL sp_transfer_money(1, 2, 300.00);

-- Kiểm tra kết quả sau giao dịch
SELECT * FROM accounts;
