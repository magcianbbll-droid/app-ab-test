-- ============================================================
-- APP首页改版 A/B 测试 — 核心分析查询
-- ============================================================
USE ab_test_app;

-- ============================================================
-- 分析1：整体实验结果概览
-- ============================================================
SELECT
    e.group_name,
    COUNT(DISTINCT e.user_id)                              AS total_users,
    COUNT(DISTINCT s.session_id)                           AS total_sessions,
    ROUND(COUNT(DISTINCT s.session_id) /
          COUNT(DISTINCT e.user_id), 2)                    AS avg_sessions_per_user,
    ROUND(AVG(s.duration_sec), 1)                          AS avg_session_duration_sec,
    ROUND(AVG(s.duration_sec)/60, 2)                       AS avg_session_duration_min
FROM experiments e
LEFT JOIN sessions s ON e.user_id = s.user_id
GROUP BY e.group_name;

-- ============================================================
-- 分析2：核心指标 CTR（点击率）
-- 定义：有点击行为的会话数 / 总会话数
-- ============================================================
SELECT
    e.group_name,
    COUNT(DISTINCT s.session_id)                           AS total_sessions,
    COUNT(DISTINCT CASE
        WHEN ev.event_type IN ('card_click','banner_click')
        THEN s.session_id END)                             AS click_sessions,
    ROUND(COUNT(DISTINCT CASE
        WHEN ev.event_type IN ('card_click','banner_click')
        THEN s.session_id END) * 100.0 /
        COUNT(DISTINCT s.session_id), 2)                   AS ctr_pct
FROM experiments e
LEFT JOIN sessions s  ON e.user_id = s.user_id
LEFT JOIN events  ev  ON s.session_id = ev.session_id
GROUP BY e.group_name;

-- ============================================================
-- 分析3：7日留存率（实验开始后第7天仍有会话的用户比例）
-- ============================================================
SELECT
    e.group_name,
    COUNT(DISTINCT e.user_id)                              AS total_users,
    COUNT(DISTINCT CASE
        WHEN s.session_date >= DATE_ADD('2026-03-01', INTERVAL 7 DAY)
        THEN e.user_id END)                                AS retained_users,
    ROUND(COUNT(DISTINCT CASE
        WHEN s.session_date >= DATE_ADD('2026-03-01', INTERVAL 7 DAY)
        THEN e.user_id END) * 100.0 /
        COUNT(DISTINCT e.user_id), 2)                      AS retention_7d_pct
FROM experiments e
LEFT JOIN sessions s ON e.user_id = s.user_id
GROUP BY e.group_name;

-- ============================================================
-- 分析4：功能模块进入率（feature_enter / total_sessions）
-- ============================================================
SELECT
    e.group_name,
    COUNT(DISTINCT s.session_id)                           AS total_sessions,
    COUNT(DISTINCT CASE
        WHEN ev.event_type = 'feature_enter'
        THEN s.session_id END)                             AS feature_sessions,
    ROUND(COUNT(DISTINCT CASE
        WHEN ev.event_type = 'feature_enter'
        THEN s.session_id END) * 100.0 /
        COUNT(DISTINCT s.session_id), 2)                   AS feature_enter_rate_pct
FROM experiments e
LEFT JOIN sessions s  ON e.user_id = s.user_id
LEFT JOIN events  ev  ON s.session_id = ev.session_id
GROUP BY e.group_name;

-- ============================================================
-- 分析5：按设备类型分层分析（CTR）
-- ============================================================
SELECT
    e.group_name,
    u.device_type,
    COUNT(DISTINCT s.session_id)                           AS total_sessions,
    ROUND(COUNT(DISTINCT CASE
        WHEN ev.event_type IN ('card_click','banner_click')
        THEN s.session_id END) * 100.0 /
        NULLIF(COUNT(DISTINCT s.session_id), 0), 2)        AS ctr_pct
FROM experiments e
JOIN users u ON e.user_id = u.user_id
LEFT JOIN sessions s  ON e.user_id = s.user_id
LEFT JOIN events  ev  ON s.session_id = ev.session_id
GROUP BY e.group_name, u.device_type
ORDER BY u.device_type, e.group_name;

-- ============================================================
-- 分析6：日维度趋势（每日活跃用户数对比）
-- 用窗口函数计算累计留存
-- ============================================================
SELECT
    e.group_name,
    s.session_date,
    COUNT(DISTINCT e.user_id)                              AS dau,
    ROUND(AVG(s.duration_sec), 1)                          AS avg_duration_sec,
    SUM(COUNT(DISTINCT e.user_id))
        OVER (PARTITION BY e.group_name
              ORDER BY s.session_date)                     AS cumulative_dau
FROM experiments e
JOIN sessions s ON e.user_id = s.user_id
GROUP BY e.group_name, s.session_date
ORDER BY s.session_date, e.group_name;

-- ============================================================
-- 分析7：用户漏斗（会话→点击→进入功能→分享）
-- ============================================================
SELECT
    e.group_name,
    COUNT(DISTINCT e.user_id)                              AS step0_total_users,
    COUNT(DISTINCT CASE
        WHEN s.session_id IS NOT NULL
        THEN e.user_id END)                                AS step1_has_session,
    COUNT(DISTINCT CASE
        WHEN ev1.event_type IN ('card_click','banner_click')
        THEN e.user_id END)                                AS step2_clicked,
    COUNT(DISTINCT CASE
        WHEN ev2.event_type = 'feature_enter'
        THEN e.user_id END)                                AS step3_entered_feature,
    COUNT(DISTINCT CASE
        WHEN ev3.event_type = 'share'
        THEN e.user_id END)                                AS step4_shared
FROM experiments e
LEFT JOIN sessions s   ON e.user_id = s.user_id
LEFT JOIN events  ev1  ON e.user_id = ev1.user_id
    AND ev1.event_type IN ('card_click','banner_click')
LEFT JOIN events  ev2  ON e.user_id = ev2.user_id
    AND ev2.event_type = 'feature_enter'
LEFT JOIN events  ev3  ON e.user_id = ev3.user_id
    AND ev3.event_type = 'share'
GROUP BY e.group_name;
