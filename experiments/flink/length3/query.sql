SELECT
    A.src AS src,
    A.dst AS via1,
    C.src AS via2,
    C.dst AS dst,
    A.window_start AS ws,
    A.window_end AS we
FROM
    GraphWindowed AS A, GraphWindowed AS B, GraphWindowed AS C
WHERE
    A.window_start = B.window_start
    AND B.window_start = C.window_start
    AND A.dst = B.src
    AND B.dst = C.src