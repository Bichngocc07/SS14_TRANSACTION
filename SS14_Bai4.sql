
DROP DATABASE IF EXISTS CourseEnrollmentDB;
CREATE DATABASE CourseEnrollmentDB;
USE CourseEnrollmentDB;

-- Bảng sinh viên
DROP TABLE IF EXISTS students;
CREATE TABLE students (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    student_name VARCHAR(50) NOT NULL
);

-- Bảng môn học
DROP TABLE IF EXISTS courses;
CREATE TABLE courses (
    course_id INT AUTO_INCREMENT PRIMARY KEY,
    course_name VARCHAR(100) NOT NULL,
    available_seats INT NOT NULL
);

-- Bảng đăng ký học phần
DROP TABLE IF EXISTS enrollments;
CREATE TABLE enrollments (
    enrollment_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT,
    course_id INT,
    enrolled_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
);

-- =========================
-- 2. DỮ LIỆU MẪU
-- =========================
INSERT INTO students (student_name) VALUES
('Nguyen Van A'),
('Tran Thi B'),
('Le Van C');

INSERT INTO courses (course_name, available_seats) VALUES
('Database Systems', 2),
('Web Programming', 1),
('Operating Systems', 0);

-- Kiểm tra dữ liệu ban đầu
SELECT * FROM students;
SELECT * FROM courses;

-- =========================
-- 3. STORED PROCEDURE ĐĂNG KÝ HỌC PHẦN
-- =========================
DELIMITER //

CREATE PROCEDURE sp_register_course (
    IN p_student_name VARCHAR(50),
    IN p_course_name VARCHAR(100)
)
BEGIN
    DECLARE v_student_id INT;
    DECLARE v_course_id INT;
    DECLARE v_seats INT;

    -- Bắt lỗi SQL → rollback
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Đăng ký học phần thất bại – đã rollback';
    END;

    -- Lấy student_id
    SELECT student_id INTO v_student_id
    FROM students
    WHERE student_name = p_student_name;

    -- Lấy course_id và số chỗ trống (khóa dòng)
    SELECT course_id, available_seats
    INTO v_course_id, v_seats
    FROM courses
    WHERE course_name = p_course_name
    FOR UPDATE;

    -- Kiểm tra còn chỗ trống
    IF v_seats <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Môn học đã hết chỗ trống';
    END IF;

    -- Bắt đầu Transaction
    START TRANSACTION;

        -- Thêm đăng ký học phần
        INSERT INTO enrollments (student_id, course_id)
        VALUES (v_student_id, v_course_id);

        -- Giảm số chỗ trống
        UPDATE courses
        SET available_seats = available_seats - 1
        WHERE course_id = v_course_id;

    COMMIT;
END//

DELIMITER ;

-- Case 1: Đăng ký thành công
CALL sp_register_course('Nguyen Van A', 'Database Systems');

SELECT * FROM enrollments;
SELECT * FROM courses;

SELECT * FROM enrollments;
SELECT * FROM courses;