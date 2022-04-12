CREATE VIEW personWindowed AS
SELECT
    p_personid,
    p_firstname,
    p_lastname,
    window_start,
    window_end
FROM TABLE(HOP(TABLE person, DESCRIPTOR(ts),
    INTERVAL '90' DAYS,
    INTERVAL '180' DAYS(3)))
GROUP BY p_personid, p_firstname, p_lastname, window_start, window_end