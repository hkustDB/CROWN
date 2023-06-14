SELECT DISTINCT
    L.t0,
    L.t1,
    D.src,
    D.dst,
    R.t1,
    R.t2,
    D.window_start AS ws,
    D.window_end AS we
FROM
    Triangle AS L, GraphWindowed AS D, Triangle AS R
WHERE
    L.t2 = D.src AND D.dst = R.t0
    AND D.window_start = L.window_start
    AND D.window_start = R.window_start