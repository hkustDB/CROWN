CREATE VIEW V2Windowed AS
SELECT dst, window_start, window_end
FROM TABLE(HOP(TABLE V2, DESCRIPTOR(ts),
    INTERVAL '0 17:15:16' DAYS TO SECONDS,
    INTERVAL '1 10:30:32' DAYS TO SECONDS))
GROUP BY dst, window_start, window_end