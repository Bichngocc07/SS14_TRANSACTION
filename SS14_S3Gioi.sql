CREATE TABLE IF NOT EXISTS followers (
    follower_id INT NOT NULL,
    followed_id INT NOT NULL,
    followed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (follower_id, followed_id),
    CONSTRAINT fk_followers_follower
        FOREIGN KEY (follower_id) REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_followers_followed
        FOREIGN KEY (followed_id) REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- =========================================================
-- 3) (TUỲ CHỌN) TẠO follow_log ĐỂ GHI LỖI / SỰ KIỆN
-- =========================================================
CREATE TABLE IF NOT EXISTS follow_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    follower_id INT NULL,
    followed_id INT NULL,
    action VARCHAR(20) NOT NULL,        -- 'FOLLOW' / 'ERROR'
    message VARCHAR(255) NOT NULL,
    log_time DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================
-- 4) STORED PROCEDURE sp_follow_user (Transaction + Validation + Rollback)
-- =========================================================
DROP PROCEDURE IF EXISTS sp_follow_user;
DELIMITER //

CREATE PROCEDURE sp_follow_user(
    IN p_follower_id INT,
    IN p_followed_id INT
)
BEGIN
    DECLARE v_exists_follower INT DEFAULT 0;
    DECLARE v_exists_followed INT DEFAULT 0;
    DECLARE v_already_followed INT DEFAULT 0;

    -- Bắt mọi lỗi SQL trong quá trình chạy procedure
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        INSERT INTO follow_log(follower_id, followed_id, action, message)
        VALUES (p_follower_id, p_followed_id, 'ERROR',
                'Follow thất bại do lỗi hệ thống/SQL. Giao dịch đã được rollback.');
        SELECT 'Follow thất bại (SQL error). Dữ liệu đã rollback.' AS message;
    END;

    START TRANSACTION;

        -- 1) Không tự follow chính mình
        IF p_follower_id = p_followed_id THEN
            INSERT INTO follow_log(follower_id, followed_id, action, message)
            VALUES (p_follower_id, p_followed_id, 'ERROR',
                    'Không được follow chính mình.');
            ROLLBACK;
            SELECT 'Không được follow chính mình.' AS message;
            LEAVE proc_end;
        END IF;

        -- 2) Kiểm tra tồn tại user follower và user followed
        SELECT COUNT(*) INTO v_exists_follower
        FROM users
        WHERE user_id = p_follower_id;

        SELECT COUNT(*) INTO v_exists_followed
        FROM users
        WHERE user_id = p_followed_id;

        IF v_exists_follower = 0 OR v_exists_followed = 0 THEN
            INSERT INTO follow_log(follower_id, followed_id, action, message)
            VALUES (p_follower_id, p_followed_id, 'ERROR',
                    'Follower hoặc Followed không tồn tại.');
            ROLLBACK;
            SELECT 'Follower hoặc Followed không tồn tại.' AS message;
            LEAVE proc_end;
        END IF;

        -- 3) Kiểm tra chưa follow trước đó
        SELECT COUNT(*) INTO v_already_followed
        FROM followers
        WHERE follower_id = p_follower_id
          AND followed_id = p_followed_id;

        IF v_already_followed > 0 THEN
            INSERT INTO follow_log(follower_id, followed_id, action, message)
            VALUES (p_follower_id, p_followed_id, 'ERROR',
                    'Đã follow trước đó, không thể follow trùng.');
            ROLLBACK;
            SELECT 'Đã follow trước đó.' AS message;
            LEAVE proc_end;
        END IF;

        -- 4) Nếu OK: INSERT followers + UPDATE counts (3 thao tác phải cùng thành công)
        INSERT INTO followers(follower_id, followed_id)
        VALUES (p_follower_id, p_followed_id);

        UPDATE users
        SET following_count = following_count + 1
        WHERE user_id = p_follower_id;

        UPDATE users
        SET followers_count = followers_count + 1
        WHERE user_id = p_followed_id;

    COMMIT;

    INSERT INTO follow_log(follower_id, followed_id, action, message)
    VALUES (p_follower_id, p_followed_id, 'FOLLOW', 'Follow thành công.');

    SELECT 'Follow thành công.' AS message;

    proc_end: BEGIN END;
END//

DELIMITER ;

-- Xem users
SELECT user_id, username, following_count, followers_count FROM users;

-- Case A: Follow thành công (giả sử user_id 1 follow user_id 2)
CALL sp_follow_user(1, 2);

-- Kiểm tra followers và counts
SELECT * FROM followers ORDER BY followed_at DESC;
SELECT user_id, username, following_count, followers_count FROM users WHERE user_id IN (1,2);

-- Case B: Follow trùng (1 follow 2 lần nữa) -> fail + rollback
CALL sp_follow_user(1, 2);

-- Case C: Tự follow (1 follow 1) -> fail + rollback
CALL sp_follow_user(1, 1);

-- Case D: Follow user không tồn tại (1 follow 9999) -> fail + rollback
CALL sp_follow_user(1, 9999);

-- Xem log
SELECT * FROM follow_log ORDER BY log_time DESC;