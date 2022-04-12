SELECT
    A.src AS src,
    A.dst AS via,
    B.dst AS dst,
    A.window_start AS ws,
    A.window_end AS we
FROM
    GraphWindowed AS A, GraphWindowed AS B
WHERE
    A.window_start = B.window_start
    AND A.dst = B.src