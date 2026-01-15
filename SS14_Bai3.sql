DROP DATABASE IF EXISTS PayrollDB;
CREATE DATABASE PayrollDB;
USE PayrollDB;

-- Bảng nhân viên
DROP TABLE IF EXISTS employees;
CREATE TABLE employees (
    emp_id INT AUTO_INCREMENT PRIMARY KEY,
    emp_name VARCHAR(100) NOT NULL,
    salary DECIMAL(10,2) NOT NULL
);

-- Bảng quỹ công ty
DROP TABLE IF EXISTS company_funds;
CREATE TABLE company_funds (
    fund_id INT PRIMARY KEY,
    balance DECIMAL(15,2) NOT NULL
);

-- Bảng lương
DROP TABLE IF EXISTS payroll;
CREATE TABLE payroll (
    payroll_id INT AUTO_INCREMENT PRIMARY KEY,
    emp_id INT NOT NULL,
    salary_paid DECIMAL(10,2) NOT NULL,
    paid_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
);

-- =========================
-- 2. DỮ LIỆU MẪU
-- =========================
INSERT INTO employees (emp_name, salary) VALUES
('Nguyen Van A', 5000.00),
('Tran Thi B', 7000.00),
('Le Van C', 4000.00);

INSERT INTO company_funds (fund_id, balance) VALUES
(1, 15000.00);

-- Kiểm tra dữ liệu ban đầu
SELECT * FROM employees;
SELECT * FROM company_funds;

-- 3. STORED PROCEDURE TRẢ LƯƠNG
DELIMITER //

CREATE PROCEDURE sp_pay_salary (
    IN p_emp_id INT
)
BEGIN
    DECLARE v_salary DECIMAL(10,2);
    DECLARE v_balance DECIMAL(15,2);
    DECLARE v_bank_status INT DEFAULT 1;

    -- Bắt lỗi SQL → rollback
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Giao dịch thất bại – đã rollback';
    END;

    -- Lấy lương nhân viên
    SELECT salary INTO v_salary
    FROM employees
    WHERE emp_id = p_emp_id;

    -- Lấy số dư quỹ công ty (khóa dòng)
    SELECT balance INTO v_balance
    FROM company_funds
    WHERE fund_id = 1
    FOR UPDATE;

    -- Kiểm tra quỹ đủ tiền
    IF v_balance < v_salary THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Quỹ công ty không đủ tiền để trả lương';
    END IF;

    -- Bắt đầu Transaction
    START TRANSACTION;

        -- Trừ tiền quỹ công ty
        UPDATE company_funds
        SET balance = balance - v_salary
        WHERE fund_id = 1;

        -- Ghi nhận bảng lương
        INSERT INTO payroll (emp_id, salary_paid)
        VALUES (p_emp_id, v_salary);

        -- Giả lập lỗi hệ thống ngân hàng (đổi 1 → 0 để test)
        IF v_bank_status = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lỗi hệ thống ngân hàng';
        END IF;

    COMMIT;
END//

DELIMITER ;

-- Case 1: Trả lương hợp lệ cho nhân viên 1
CALL sp_pay_salary(1);

SELECT * FROM company_funds;
SELECT * FROM payroll;

-- Kiểm tra lại dữ liệu
SELECT * FROM company_funds;
SELECT * FROM payroll;
