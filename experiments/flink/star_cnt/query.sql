SELECT
    A.src AS src,
    COUNT(*) AS cnt,
    A.window_start AS ws,
    A.window_end AS we
FROM
    GraphWindowed AS A, GraphWindowed AS B, GraphWindowed AS C, GraphWindowed AS D
WHERE
    A.window_start = B.window_start
    AND A.window_start = C.window_start
    AND A.window_start = D.window_start
    AND A.src = B.src
    AND A.src = C.src
    AND A.src = D.src
GROUP BY A.src, A.window_start, A.window_end