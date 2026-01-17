-- BTTH --
create database SocialNetworkDB;
use SocialNetworkDB;

CREATE TABLE users (

    user_id INT AUTO_INCREMENT PRIMARY KEY,

    username VARCHAR(50) NOT NULL,

    total_posts INT DEFAULT 0

);


CREATE TABLE posts (

    post_id INT AUTO_INCREMENT PRIMARY KEY,

    user_id INT,

    content TEXT,

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(user_id)

);


INSERT INTO users (username, total_posts) VALUES ('nguyen_van_a', 0);

INSERT INTO users (username, total_posts) VALUES ('le_thi_b', 0);

DROP PROCEDURE IF EXISTS sp_create_post;
DELIMITER //

CREATE PROCEDURE sp_create_post(
    IN p_user_id INT,
    IN p_content TEXT
)
BEGIN
    DECLARE v_err_msg TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;

        SELECT 'Đăng bài thất bại. Vui lòng kiểm tra user_id hợp lệ và dữ liệu đầu vào.' AS message;
    END;

    IF p_content IS NULL OR CHAR_LENGTH(TRIM(p_content)) = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Nội dung bài viết không được để trống.';
    END IF;

    -- =========================
    START TRANSACTION;

        INSERT INTO posts(user_id, content)
        VALUES (p_user_id, p_content);

        UPDATE users
        SET total_posts = total_posts + 1
        WHERE user_id = p_user_id;

    COMMIT;

    SELECT 'Đăng bài thành công.' AS message;
END//

DELIMITER ;

SELECT * FROM users;
SELECT * FROM posts;

-- ---------------------------------------------------------
-- Case 1 (Happy Case): đăng bài cho nguyen_van_a
-- ---------------------------------------------------------
-- Lấy user_id của nguyen_van_a (thường là 1)
SELECT user_id FROM users WHERE username = 'nguyen_van_a';

-- Gọi procedure (giả sử user_id = 1)
CALL sp_create_post(1, 'Bài viết đầu tiên của nguyen_van_a');

-- Kiểm tra: posts có thêm dòng? total_posts tăng?
SELECT * FROM posts ORDER BY post_id DESC;
SELECT * FROM users WHERE user_id = 1;

-- ---------------------------------------------------------
-- Case 2 (Error Case): đăng bài cho user_id không tồn tại 9999
-- ---------------------------------------------------------
CALL sp_create_post(9999, 'Bài viết cho user_id không tồn tại');

-- Kiểm tra quan trọng:
-- 1) Có "dòng rác" trong posts không?
SELECT * FROM posts WHERE user_id = 9999;

-- 2) total_posts của các user thật có bị tăng nhầm không?
SELECT * FROM users ORDER BY user_id;
