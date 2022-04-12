CREATE VIEW GraphWindowed AS
SELECT src, dst, window_start, window_end
FROM TABLE(HOP(TABLE Graph, DESCRIPTOR(ts),
    INTERVAL '${hop.window.step.day} ${hop.window.step.hour}:${hop.window.step.minute}:${hop.window.step.second}' DAYS TO SECONDS,
    INTERVAL '${hop.window.size.day} ${hop.window.size.hour}:${hop.window.size.minute}:${hop.window.size.second}' DAYS TO SECONDS))
GROUP BY src, dst, window_start, window_end