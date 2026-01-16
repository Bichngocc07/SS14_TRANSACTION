DROP DATABASE IF EXISTS social_network;
CREATE DATABASE social_network;
USE social_network;

CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL
);

CREATE TABLE posts (
    post_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    likes_count INT DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE likes (
    like_id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    UNIQUE KEY unique_like (post_id, user_id),
    FOREIGN KEY (post_id) REFERENCES posts(post_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

INSERT INTO users (username) VALUES
('alice'),
('bob');

INSERT INTO posts (user_id, content) VALUES
(1, 'Hello Social Network'),
(2, 'My first post');

START TRANSACTION;

INSERT INTO likes (post_id, user_id)
VALUES (1, 2);

UPDATE posts
SET likes_count = likes_count + 1
WHERE post_id = 1;

COMMIT;

SELECT * FROM likes;
SELECT post_id, likes_count FROM posts WHERE post_id = 1;

START TRANSACTION;

INSERT INTO likes (post_id, user_id)
VALUES (1, 2); -- lỗi UNIQUE

UPDATE posts
SET likes_count = likes_count + 1
WHERE post_id = 1;

ROLLBACK;

SELECT * FROM likes;
SELECT post_id, likes_count FROM posts WHERE post_id = 1;
