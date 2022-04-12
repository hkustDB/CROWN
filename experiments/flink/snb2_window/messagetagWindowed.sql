CREATE VIEW message_tagWindowed AS
SELECT
    mt_messageid,
    mt_tagid,
    window_start,
    window_end
FROM TABLE(HOP(TABLE message_tag, DESCRIPTOR(ts),
    INTERVAL '90' DAYS,
    INTERVAL '180' DAYS(3)))
GROUP BY mt_messageid, mt_tagid, window_start, window_end