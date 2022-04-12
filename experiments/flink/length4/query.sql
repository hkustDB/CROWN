SELECT
    A.src AS src,
    A.dst AS via1,
    B.dst AS via2,
    C.dst AS via3,
    D.dst AS dst,
    A.window_start AS ws,
    A.window_end AS we
FROM
    GraphWindowed AS A, GraphWindowed AS B, GraphWindowed AS C, GraphWindowed AS D
WHERE
    A.window_start = B.window_start
    AND A.window_start = C.window_start
    AND A.window_start = D.window_start
    AND A.dst = B.src
    AND B.dst = C.src
    AND C.dst = D.src