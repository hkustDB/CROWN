CREATE VIEW knowsWindowed AS
SELECT
    k_person1id,
    k_person2id,
    window_start,
    window_end
FROM TABLE(HOP(TABLE knows, DESCRIPTOR(ts),
    INTERVAL '90' DAYS,
    INTERVAL '180' DAYS(3)))
GROUP BY k_person1id, k_person2id, window_start, window_end