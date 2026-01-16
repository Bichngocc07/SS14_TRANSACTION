DROP DATABASE IF EXISTS social_network;
CREATE DATABASE social_network;
USE social_network;

CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    posts_count INT DEFAULT 0
);

CREATE TABLE posts (
    post_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

INSERT INTO users (username) VALUES
('alice'),
('bob');

START TRANSACTION;

INSERT INTO posts (user_id, content)
VALUES (1, 'Hello Social Network!');

UPDATE users
SET posts_count = posts_count + 1
WHERE user_id = 1;

COMMIT;

SELECT * FROM users;
SELECT * FROM posts;

START TRANSACTION;

INSERT INTO posts (user_id, content)
VALUES (999, 'This post will fail');

UPDATE users
SET posts_count = posts_count + 1
WHERE user_id = 999;

ROLLBACK;

SELECT * FROM users;
SELECT * FROM posts;

