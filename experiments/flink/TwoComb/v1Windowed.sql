CREATE VIEW V1Windowed AS
SELECT src, window_start, window_end
FROM TABLE(HOP(TABLE V1, DESCRIPTOR(ts),
    INTERVAL '0 17:15:16' DAYS TO SECONDS,
    INTERVAL '1 10:30:32' DAYS TO SECONDS))
GROUP BY src, window_start, window_end