SELECT
    A.src AS src,
    A.dst AS dst1,
    B.dst AS dst2,
    C.dst AS dst3,
    D.dst AS dst4,
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
    AND D.dst > ${filter.condition.value}