-- ============================================================
-- APP首页改版 A/B 测试数据库
-- 数据库：ab_test_app
-- 执行环境：MySQL 8.0+
-- ============================================================

DROP DATABASE IF EXISTS ab_test_app;
CREATE DATABASE ab_test_app CHARACTER SET utf8mb4;
USE ab_test_app;

-- ============================================================
-- 1. 用户表
-- ============================================================
CREATE TABLE users (
    user_id       INT PRIMARY KEY AUTO_INCREMENT,
    register_date DATE NOT NULL,
    device_type   ENUM('iOS', 'Android') NOT NULL,
    age_group     ENUM('18-24', '25-34', '35-44', '45+') NOT NULL,
    city_tier     ENUM('T1', 'T2', 'T3') NOT NULL  -- 一二三线城市
);

-- ============================================================
-- 2. 实验分组表
-- ============================================================
CREATE TABLE experiments (
    exp_id        INT PRIMARY KEY AUTO_INCREMENT,
    user_id       INT NOT NULL,
    group_name    ENUM('control', 'treatment') NOT NULL,  -- A组/B组
    assign_date   DATE NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- ============================================================
-- 3. 会话表（每次打开APP算一次会话）
-- ============================================================
CREATE TABLE sessions (
    session_id    BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id       INT NOT NULL,
    session_date  DATE NOT NULL,
    duration_sec  INT NOT NULL,   -- 会话时长（秒）
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- ============================================================
-- 4. 用户行为事件表
-- ============================================================
CREATE TABLE events (
    event_id      BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id       INT NOT NULL,
    session_id    BIGINT NOT NULL,
    event_date    DATE NOT NULL,
    event_type    ENUM(
        'banner_click',       -- 点击banner
        'card_click',         -- 点击推荐卡片
        'feature_enter',      -- 进入功能模块
        'search',             -- 搜索
        'share'               -- 分享
    ) NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (session_id) REFERENCES sessions(session_id)
);

-- ============================================================
-- 5. 生成模拟数据（存储过程）
-- ============================================================
DELIMITER $$

CREATE PROCEDURE generate_data()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE grp ENUM('control', 'treatment');
    DECLARE base_ctr DECIMAL(4,3);
    DECLARE n_sessions INT;
    DECLARE n_events INT;
    DECLARE dur INT;
    DECLARE j INT;
    DECLARE k INT;
    DECLARE sid BIGINT;
    DECLARE ev_type ENUM('banner_click','card_click','feature_enter','search','share');
    DECLARE ev_rand DECIMAL(3,2);
    DECLARE d DATE;
    DECLARE device ENUM('iOS','Android');
    DECLARE age ENUM('18-24','25-34','35-44','45+');
    DECLARE city ENUM('T1','T2','T3');

    -- 生成 5000 名用户
    WHILE i <= 5000 DO

        -- 随机属性
        SET device = ELT(FLOOR(RAND()*2)+1, 'iOS', 'Android');
        SET age    = ELT(FLOOR(RAND()*4)+1, '18-24','25-34','35-44','45+');
        SET city   = ELT(FLOOR(RAND()*3)+1, 'T1','T2','T3');

        INSERT INTO users (register_date, device_type, age_group, city_tier)
        VALUES (
            DATE_SUB('2026-01-01', INTERVAL FLOOR(RAND()*180) DAY),
            device, age, city
        );

        -- 随机分组（50/50）
        IF RAND() < 0.5 THEN
            SET grp = 'control';
        ELSE
            SET grp = 'treatment';
        END IF;

        INSERT INTO experiments (user_id, group_name, assign_date)
        VALUES (i, grp, '2026-03-01');

        -- 实验期14天，每天可能有会话
        SET j = 0;
        WHILE j < 14 DO
            SET d = DATE_ADD('2026-03-01', INTERVAL j DAY);

            -- treatment组活跃度略高（留存效果）
            IF grp = 'treatment' THEN
                SET n_sessions = IF(RAND() < 0.55, 1, 0);
            ELSE
                SET n_sessions = IF(RAND() < 0.45, 1, 0);
            END IF;

            IF n_sessions = 1 THEN
                -- treatment组会话更长
                IF grp = 'treatment' THEN
                    SET dur = FLOOR(180 + RAND()*420);  -- 180-600s
                ELSE
                    SET dur = FLOOR(120 + RAND()*300);  -- 120-420s
                END IF;

                INSERT INTO sessions (user_id, session_date, duration_sec)
                VALUES (i, d, dur);

                SET sid = LAST_INSERT_ID();

                -- 每个会话产生若干事件
                SET n_events = FLOOR(1 + RAND()*6);
                SET k = 0;
                WHILE k < n_events DO
                    SET ev_rand = RAND();

                    -- treatment组点击率更高
                    IF grp = 'treatment' THEN
                        IF ev_rand < 0.35 THEN SET ev_type = 'card_click';
                        ELSEIF ev_rand < 0.55 THEN SET ev_type = 'feature_enter';
                        ELSEIF ev_rand < 0.70 THEN SET ev_type = 'banner_click';
                        ELSEIF ev_rand < 0.85 THEN SET ev_type = 'search';
                        ELSE SET ev_type = 'share'; END IF;
                    ELSE
                        IF ev_rand < 0.25 THEN SET ev_type = 'card_click';
                        ELSEIF ev_rand < 0.45 THEN SET ev_type = 'feature_enter';
                        ELSEIF ev_rand < 0.65 THEN SET ev_type = 'banner_click';
                        ELSEIF ev_rand < 0.82 THEN SET ev_type = 'search';
                        ELSE SET ev_type = 'share'; END IF;
                    END IF;

                    INSERT INTO events (user_id, session_id, event_date, event_type)
                    VALUES (i, sid, d, ev_type);

                    SET k = k + 1;
                END WHILE;
            END IF;

            SET j = j + 1;
        END WHILE;

        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

-- 执行数据生成（约需1-2分钟）
CALL generate_data();

-- ============================================================
-- 6. 验证数据
-- ============================================================
SELECT '用户总数' AS metric, COUNT(*) AS value FROM users
UNION ALL
SELECT '实验分组数', COUNT(*) FROM experiments
UNION ALL
SELECT '会话总数', COUNT(*) FROM sessions
UNION ALL
SELECT '事件总数', COUNT(*) FROM events;

SELECT group_name, COUNT(*) AS user_count
FROM experiments GROUP BY group_name;
