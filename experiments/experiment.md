# Experiments Todo Lists

## Full Join Queries

1. Line-3 Query (with optional filter):

```SQL
SELECT g1.src, g1.dst, g3.src, g3.dst 
FROM graph g1, graph g2, graph g3 
WHERE g1.dst = g2.src and g2.dst = g3.src
and g3.dst > nFilter
```

2. Line-4 Query (with optional filter):

```SQL
SELECT g1.src, g1.dst, g3.src, g3.dst, g4.dst 
FROM graph g1, graph g2, graph g3, graph g4
WHERE g1.dst = g2.src and g2.dst = g3.src and g3.dst = g4.src
and g4.dst > nFilter
```

3. Star Query (with optional filter):

```SQL
SELECT g1.src, g1.dst, g2.dst, g3.dst, g4.dst 
FROM graph g1, graph g2, graph g3, graph g4
WHERE g1.src = g2.src and g1.src = g3.src and g1.src = g4.src
and g4.dst > nFilter 
```

4. SNB Query 1: (inQ2)

```SQL
select p_personid, p_firstname, p_lastname, m_messageid, k_personid1
from person, message, knows
where
    p_personid = m_creatorid and
    k_personid2 = p_personid
```

5. SNB Query 2: (inQ6)

```SQL
select k1.k_person1id, k1.k_person2id, k2.k_person2id, t_tagid, m_messageid
from tag, message, message_tag, knows k1, knows k2
where
    m_messageid = mt_messageid and
    mt_tagid = t_tagid and
    k1.k_person2id = k2.k_person1id and
    m_creatorid = k2.k_person2id and
    m_c_replyof IS NULL and 
    k_person1id < 100000 and
    m_creationdate in sliding window size 30
```

6. SNB Query 3: (inQ9)

```SQL
select p_personid, p_firstname, p_lastname,
       m_messageid, k1.k_personid1, k1.k_personid2
from
  knows k1, knows k2, person, message
where
   k1.k_person1id < 100000
      and k1.k_person2id = k2.k_person1id
    and k2.k_personid2 <> k1.k_personid1
  p_personid = m_creatorid and p_personid = f.k_person2id and
  m_creationdate in sliding window size 30
```

## Projection Queries:

7. Line-3 Projection Query:
```SQL
SELECT g2.src, g2.dst 
FROM graph g1, graph g2, graph g3 
WHERE g1.dst = g2.src and g2.dst = g3.src
```

8. Line-4 Projection Query:
```SQL
SELECT g2.src, g2.dst, g3.dst
FROM graph g1, graph g2, graph g3, graph g4
WHERE g1.dst = g2.src and g2.dst = g3.src and g3.dst = g4.src
```

## Aggregation Queries:

9. Count Star Query:

```SQL
SELECT count(*), g1.src
FROM graph g1, graph g2, graph g3, graph g4
WHERE g1.src = g2.src and g1.src = g3.src and g1.src = g4.src
GROUP BY g1.src
```

10. SNB Q4: (inQ4)
```SQL
select t_name, t_tagid, count(distinct m_messageid)
from tag, message, message_tag, knows
where
    m_messageid = mt_messageid and
    mt_tagid = t_tagid and
    m_creatorid = k_person2id and
    m_c_replyof IS NULL and 
    k_person1id < 100000 and
    m_creationdate in window size 30 day
group by
t_name, t_tag_id
```

# Update Sequence

For all queries, if the window size is not given, then we test with window size 0.2\*N, where N is the total number of edges.

For the filter condition, set the default value to be 0.05\*N.

All input data should contain both input and output operations and sort in order.  For Flink, if it can accept the window operator, then only input should be given. 

# Enumeration

For single thread test, we compare ACQ, DBToaster_cpp, DYN, Trill, and Flink(if possible), for DBToaster_cpp, ACQ, DYN and DBToaster, request a full enumeration for every half-window;  in the meantime, also report the ACQ, Flink, Trill with delta enumeration (ACQ will perform two tests).

For distributed mode, we compare ACQ, Flink, and DBToaster_Spark, ACQ will perform full enumeration every half-window, as well as delta enumeration (two tests), Flink will perform delta enumeration.

# Selectitive

Reperform all experiments, with different nFilter change between 0.01\*N, 0.05\*N, 0.1\*N, 0.2\*N, 0.5\*N, 0.75\*N, N (0.05*\N and N can be skipped as they are covered in the previous experiments).

# Parallelism

Test all queries with different parallelism (1, 2, 4, 8, 16,32).

# Miscellaneous

1. For distributed experiments, ensure ACQ, DBToaster and Flink can use the same number of cores.  If possible, limits the number of cores these systems can access. 
2. For every query and every system, write the output to file once, but in the final experiments, drop all outputs to null.  If not enough disk, then move some files to cpu8.
3. If possible, tests ACQ and Flink with a cluster (which can submit a job from WebUI).
4. Test all queries with three graphs: soc-bitcoin (or Facebook, you can report both results and we will choose one), web-Google, and soc-epinions. 
