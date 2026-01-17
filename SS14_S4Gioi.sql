
ALTER TABLE posts
    ADD COLUMN comments_count INT DEFAULT 0;


CREATE TABLE IF NOT EXISTS comments (
    comment_id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_comments_post
        FOREIGN KEY (post_id) REFERENCES posts(post_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_comments_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

DROP PROCEDURE IF EXISTS sp_post_comment;
DELIMITER //

CREATE PROCEDURE sp_post_comment(
    IN p_post_id INT,
    IN p_user_id INT,
    IN p_content TEXT,
    IN p_force_update_error TINYINT -- 0: bình thường, 1: cố ý tạo lỗi ở bước UPDATE
)
BEGIN
    DECLARE v_post_exists INT DEFAULT 0;
    DECLARE v_user_exists INT DEFAULT 0;

    -- Handler chung: lỗi không mong muốn -> rollback toàn bộ
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Đăng bình luận thất bại (SQL error). Giao dịch đã rollback.' AS message;
    END;

    -- Validation trước khi transaction (đúng thực tế triển khai)
    IF p_content IS NULL OR CHAR_LENGTH(TRIM(p_content)) = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nội dung bình luận không được để trống.';
    END IF;

    SELECT COUNT(*) INTO v_post_exists FROM posts WHERE post_id = p_post_id;
    IF v_post_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Post không tồn tại.';
    END IF;

    SELECT COUNT(*) INTO v_user_exists FROM users WHERE user_id = p_user_id;
    IF v_user_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User không tồn tại.';
    END IF;

    START TRANSACTION;

        -- Bước 1: Insert comment
        INSERT INTO comments(post_id, user_id, content)
        VALUES (p_post_id, p_user_id, p_content);

        -- Savepoint sau khi insert thành công
        SAVEPOINT after_insert;

        -- Bước 2: Update tăng comments_count
        -- Nếu muốn test lỗi ở UPDATE: cố ý raise error
        IF p_force_update_error = 1 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cố ý gây lỗi ở bước UPDATE để test SAVEPOINT.';
        END IF;

        -- Thực hiện update thật
        UPDATE posts
        SET comments_count = comments_count + 1
        WHERE post_id = p_post_id;

    COMMIT;

    SELECT 'Đăng bình luận thành công. Bình luận + count đã cập nhật.' AS message;

END//

DELIMITER ;

-- =========================================================
-- 4) TESTING
-- =========================================================

-- (A) Chuẩn bị dữ liệu demo tối thiểu (nếu bạn chưa có post)
-- Đảm bảo có ít nhất 1 user và 1 post
-- Ví dụ:
-- INSERT INTO users(username,total_posts,following_count,followers_count) VALUES ('u1',0,0,0);
-- INSERT INTO posts(user_id,content) VALUES (1,'Post demo');

-- Xem trạng thái ban đầu
SELECT post_id, user_id, content, comments_count FROM posts;
SELECT * FROM comments ORDER BY comment_id DESC;

-- ---------------------------------------------------------
-- CASE 1: Thành công (force_update_error = 0)
-- ---------------------------------------------------------
CALL sp_post_comment(1, 1, 'Bình luận hợp lệ - case thành công', 0);

-- Kiểm tra: comments có thêm dòng + posts.comments_count tăng
SELECT * FROM comments WHERE post_id = 1 ORDER BY comment_id DESC;
SELECT post_id, comments_count FROM posts WHERE post_id = 1;

-- ---------------------------------------------------------
-- CASE 2: Gây lỗi ở bước UPDATE để test SAVEPOINT (force_update_error = 1)
-- Mục tiêu: bình luận vẫn được giữ, nhưng count không tăng
-- ---------------------------------------------------------

-- Ghi nhận count trước
SELECT post_id, comments_count FROM posts WHERE post_id = 1;

-- Gọi procedure gây lỗi
-- Vì trong procedure hiện tại SIGNAL sẽ bị handler chung EXIT -> rollback toàn bộ.
-- Để rollback partial đúng yêu cầu, ta cần handler riêng cho lỗi ở UPDATE và rollback to savepoint.
-- (Phần nâng cấp đúng chuẩn ở bên dưới)
