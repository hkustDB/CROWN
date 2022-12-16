CREATE VIEW GraphWindowed AS
SELECT src, dst, window_start, window_end
FROM TABLE(HOP(TABLE Graph, DESCRIPTOR(ts),
    INTERVAL '0 17:15:16' DAYS TO SECONDS,
    INTERVAL '1 10:30:32' DAYS TO SECONDS))
GROUP BY src, dst, window_start, window_end