CREATE VIEW Triangle AS
SELECT
    A.dst AS t0, B.dst AS t1, C.dst AS t2,
    A.window_start AS window_start,
    A.window_end AS window_end
FROM GraphWindowed AS A, GraphWindowed AS B, GraphWindowed AS C
WHERE A.dst = B.src AND B.dst = C.src AND C.dst = A.src
    AND A.window_start = B.window_start
    AND A.window_start = C.window_start
    AND A.dst > ${filter.condition.value}
    AND B.dst > ${filter.condition.value}
    AND C.dst > ${filter.condition.value}