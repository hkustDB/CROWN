CREATE VIEW messageWindowed AS
SELECT
    m_messageid,
    m_creatorid,
    window_start,
    window_end
FROM TABLE(HOP(TABLE message, DESCRIPTOR(ts),
    INTERVAL '90' DAYS,
    INTERVAL '180' DAYS(3)))
GROUP BY m_messageid, m_creatorid, window_start, window_end