-- Interactive 


create table message (
    /*
     * m_ps_ denotes field specific to posts
     * m_c_  denotes field specific to comments
     * other m_ fields are common to posts and messages
     * Note: to distinguish between "post" and "comment" records:
     *   - m_c_replyof IS NULL for all "post" records
     *   - m_c_replyof IS NOT NULL for all "comment" records
     */
    m_creationdate timestamp with time zone not null,
    m_deletionDate timestamp with time zone not null, 
    m_explicitlyDeleted boolean not null,
    m_messageid bigint not null,
    m_ps_imagefile varchar,
    m_locationip varchar not null,
    m_browserused varchar not null,
    m_ps_language varchar,
    m_content text,
    m_length int not null,
    m_creatorid bigint not null,
    m_locationid bigint not null,
    m_ps_forumid bigint, -- null for comments
    m_c_parentpostid bigint, 
    m_c_replyof bigint -- null for posts
);

create table forum (
   f_creationdate timestamp with time zone not null,
   f_deletionDate timestamp with time zone not null, 
   f_explicitlyDeleted boolean not null,
   f_forumid bigint not null,
   f_title varchar not null,
   f_moderatorid bigint not null
);

create table forum_person (
   fp_joindate timestamp with time zone not null,
   fp_deletionDate timestamp with time zone not null,
   fp_explicitlyDeleted boolean not null,
   fp_forumid bigint not null,
   fp_personid bigint not null
);

create table forum_tag (
    ft_creationDate timestamp with time zone not null,
    ft_deletionDate timestamp with time zone not null,
   ft_forumid bigint not null,
   ft_tagid bigint not null
);

create table organisation (
   o_organisationid bigint not null,
   o_type varchar not null,
   o_name varchar not null,
   o_url varchar not null,
   o_placeid bigint not null
);

create table person (
   p_creationdate timestamp with time zone not null,
   p_deletionDate timestamp with time zone not null,
   p_explicitlyDeleted boolean not null,
   p_personid bigint not null,
   p_firstname varchar not null,
   p_lastname varchar not null,
   p_gender varchar not null,
   p_birthday date not null,
   p_locationip varchar not null,
   p_browserused varchar not null,
   p_placeid bigint not null,
   p_language varchar not null,
   p_email varchar not null
);

create table person_email (
   pe_personid bigint not null,
   pe_email varchar not null
);


create table person_tag (
   pt_creationdate timestamp with time zone not null,
   pt_deletionDate timestamp with time zone not null,
   pt_personid bigint not null,
   pt_tagid bigint not null
);

create table knows (
   k_creationdate timestamp with time zone not null,
   k_deletionDate timestamp with time zone not null,
   k_explicitlyDeleted boolean not null,
   k_person1id bigint not null,
   k_person2id bigint not null
);

create table likes (
   l_creationdate timestamp with time zone not null,
   l_deletionDate timestamp with time zone not null,
   l_explicitlyDeleted boolean not null, 
   l_personid bigint not null,
   l_messageid bigint not null
);

create table person_language (
   plang_personid bigint not null,
   plang_language varchar not null
);

create table person_university (
   pu_personid bigint not null,
   pu_organisationid bigint not null,
   pu_classyear int not null
);

create table person_company (
   pc_personid bigint not null,
   pc_organisationid bigint not null,
   pc_workfrom int not null
);

create table place (
   pl_placeid bigint not null,
   pl_name varchar not null,
   pl_url varchar not null,
   pl_type varchar not null,
   pl_containerplaceid bigint -- null for continents
);

create table message_tag (
    mt_creationdate timestamp with time zone not null,
    mt_deletionDate timestamp with time zone not null, 
    mt_messageid bigint not null,
    mt_tagid bigint not null
)

create table message_tag (
   mt_messageid bigint not null,
   mt_tagid bigint not null
);

create table tagclass (
   tc_tagclassid bigint not null,
   tc_name varchar not null,
   tc_url varchar not null,
   tc_subclassoftagclassid bigint -- null for the root tagclass (Thing)
);

create table tag (
   t_tagid bigint not null,
   t_name varchar not null,
   t_url varchar not null,
   t_tagclassid bigint not null
);



/* Q1. Transitive friends with certain name
\set personId 4398046511333
\set firstName '\'Jose\''
 */
select
  id,
  p_lastname,
  min (dist) as dist,
  p_birthday,
  p_creationdate,
  p_gender,
  p_browserused,
  p_locationip,
  (select array_agg(pe_email) from person_email where pe_personid = id group by pe_personid) as emails,
  (select array_agg(plang_language) from person_language where plang_personid = id group by plang_personid) as languages,
  p1.pl_name,
  (select array_agg(ARRAY[o2.o_name, pu_classyear::text, p2.pl_name]) from person_university, organisation o2, place p2  where pu_personid = id and pu_organisationid = o2.o_organisationid and o2.o_placeid = p2.pl_placeid group by pu_personid) as university,
       (select array_agg(ARRAY[o3.o_name, pc_workfrom::text, p3.pl_name]) from person_company, organisation o3, place p3 where pc_personid = id and pc_organisationid = o3.o_organisationid and o3.o_placeid = p3.pl_placeid group by pc_personid) as company
from
    (
    select k_person2id as id, 1 as dist from knows, person where k_person1id = :personId and p_personid = k_person2id and p_firstname = :firstName
    union all
    select b.k_person2id as id, 2 as dist from knows a, knows b, person
    where a.k_person1id = :personId
      and b.k_person1id = a.k_person2id
      and p_personid = b.k_person2id
      and p_firstname = :firstName
      and p_personid != :personId -- excluding start person
    union all
    select c.k_person2id as id, 3 as dist from knows a, knows b, knows c, person
    where a.k_person1id = :personId
      and b.k_person1id = a.k_person2id
      and b.k_person2id = c.k_person1id
      and p_personid = c.k_person2id
      and p_firstname = :firstName
      and p_personid != :personId -- excluding start person
    ) tmp, person, place p1
  where
    p_personid = id and
    p_placeid = p1.pl_placeid
  group by id, p_lastname, p_birthday, p_creationdate, p_gender, p_browserused, p_locationip, p1.pl_name
  order by dist, p_lastname, id LIMIT 20
;


/* Q2. Recent messages by your friends
\set personId 10995116278009
\set maxDate '\'2010-10-16\''
 */
select p_personid, p_firstname, p_lastname, m_messageid, COALESCE(m_ps_imagefile, m_content), m_creationdate
from person, message, knows
where
    p_personid = m_creatorid and
    m_creationdate <= :maxDate and
    k_person1id = :personId and
    k_person2id = p_personid
order by m_creationdate desc, m_messageid asc
limit 20
;


/* Q3. Friends and friends of friends that have been to given countries
\set personId 6597069766734
\set countryXName '\'Sweden\''
\set countryYName '\'Kazakhstan\''
\set startDate '\'2010-06-01\''::date
\set durationDays 28
 */
select p_personid, p_firstname, p_lastname, ct1, ct2, total
from
 ( select k_person2id
   from knows
   where
   k_person1id = :personId
   union
   select k2.k_person2id
   from knows k1, knows k2
   where
   k1.k_person1id = :personId and k1.k_person2id = k2.k_person1id and k2.k_person2id <> :personId
 ) f,  person, place p1, place p2,
 (
  select chn.m_c_creatorid, ct1, ct2, ct1 + ct2 as total
  from
   (
      select m_creatorid as m_c_creatorid, count(*) as ct1 from message, place
      where
        m_locationid = pl_placeid and pl_name = :countryXName and
        m_creationdate >= :startDate and  m_creationdate < (:startDate + INTERVAL '1 days' * :durationDays)
      group by m_c_creatorid
   ) chn,
   (
      select m_creatorid as m_c_creatorid, count(*) as ct2 from message, place
      where
        m_locationid = pl_placeid and pl_name = :countryYName and
        m_creationdate >= :startDate and  m_creationdate < (:startDate + INTERVAL '1 days' * :durationDays)
      group by m_creatorid --m_c_creatorid
   ) ind
  where CHN.m_c_creatorid = IND.m_c_creatorid
 ) cpc
where
f.k_person2id = p_personid and p_placeid = p1.pl_placeid and
p1.pl_containerplaceid = p2.pl_placeid and p2.pl_name <> :countryXName and p2.pl_name <> :countryYName and
f.k_person2id = cpc.m_c_creatorid
order by 6 desc, 1
limit 20
;


/* Q4. New topics
\set personId 10995116277918
\set startDate '\'2010-10-01\''::date
\set durationDays 31
 */
select t_name, count(*)
from tag, message, message_tag recent, knows
where
    m_messageid = mt_messageid and
    mt_tagid = t_tagid and
    m_creatorid = k_person2id and
    m_c_replyof IS NULL and -- post, not comment
    k_person1id = :personId and
    m_creationdate >= :startDate and  m_creationdate < (:startDate + INTERVAL '1 days' * :durationDays) and
    not exists (
        select * from
  (select distinct mt_tagid from message, message_tag, knows
        where
    k_person1id = :personId and
        k_person2id = m_creatorid and
        m_c_replyof IS NULL and -- post, not comment
        mt_messageid = m_messageid and
        m_creationdate < :startDate) tags
  where  tags.mt_tagid = recent.mt_tagid)
group by t_name
order by 2 desc, t_name
limit 10
;


/* Q5 New groups
\set personId 6597069766734
\set minDate '\'2010-11-01\''::date
 */
select f_title, count(m_messageid)
from (
select f_title, f_forumid, f.k_person2id
from forum, forum_person,
 ( select k_person2id
   from knows
   where
   k_person1id = :personId
   union
   select k2.k_person2id
   from knows k1, knows k2
   where
   k1.k_person1id = :personId and k1.k_person2id = k2.k_person1id and k2.k_person2id <> :personId
 ) f
where f_forumid = fp_forumid and fp_personid = f.k_person2id and
      fp_joindate >= :minDate
) tmp left join message
on tmp.f_forumid = m_ps_forumid and m_creatorid = tmp.k_person2id
group by f_forumid, f_title
order by 2 desc, f_forumid
limit 20
;


/* Q6. Tag co-occurrence
\set personId 4398046511333
\set tagName '\'Carl_Gustaf_Emil_Mannerheim\''
 */
select t_name, count(*)
from tag, message_tag, message,
 ( select k_person2id
   from knows
   where
   k_person1id = :personId
   union
   select k2.k_person2id
   from knows k1, knows k2
   where
   k1.k_person1id = :personId and k1.k_person2id = k2.k_person1id and k2.k_person2id <> :personId
 ) f
where
m_creatorid = f.k_person2id and
m_c_replyof IS NULL and -- post, not comment
m_messageid = mt_messageid and
mt_tagid = t_tagid and
t_name <> :tagName and
exists (select * from tag, message_tag where mt_messageid = m_messageid and mt_tagid = t_tagid and t_name = :tagName)
group by t_name
order by 2 desc, t_name
limit 10
;


/* Q7. Recent likers
\set personId 4398046511268
 */
 select p_personid, p_firstname, p_lastname, l.l_creationdate, m_messageid,
    COALESCE(m_ps_imagefile, m_content),
    CAST(EXTRACT(EPOCH FROM (l.l_creationdate - m_creationdate)) AS INTEGER) / 60 as minutesLatency,
    (case when exists (select 1 from knows where k_person1id = :personId and k_person2id = p_personid) then 0 else 1 end) as isnew
from
  (select l_personid, max(l_creationdate) as l_creationdate
   from likes, message
   where
     m_messageid = l_messageid and
     m_creatorid = :personId
   group by l_personid
   order by 2 desc
   limit 20
  ) tmp, message, person, likes as l
where
    p_personid = tmp.l_personid and
    tmp.l_personid = l.l_personid and
    tmp.l_creationdate = l.l_creationdate and
    l.l_messageid = m_messageid
order by 4 desc, 1
;


/* Q8. Recent replies
\set personId 143
 */
select p1.m_creatorid, p_firstname, p_lastname, p1.m_creationdate, p1.m_messageid, p1.m_content
  from message p1, message p2, person
  where
      p1.m_c_replyof = p2.m_messageid and
      p2.m_creatorid = :personId and
      p_personid = p1.m_creatorid
order by p1.m_creationdate desc, 5
limit 20
;


/* Q9. Recent messages by friends or friends of friends
\set personId 4398046511268
\set maxDate '\'2010-11-16\''::date
 */
select p_personid, p_firstname, p_lastname,
       m_messageid, COALESCE(m_ps_imagefile, m_content), m_creationdate
from
  ( select k_person2id
    from knows
    where k_person1id = :personId
    union
    select k2.k_person2id
    from knows k1, knows k2
    where k1.k_person1id = :personId
      and k1.k_person2id = k2.k_person1id
      and k2.k_person2id <> :personId
  ) f, person, message
where
  p_personid = m_creatorid and p_personid = f.k_person2id and
  m_creationdate < :maxDate
order by m_creationdate desc, m_messageid asc
limit 20
;


/* Q10. Friend recommendation
\set personId 4398046511333
\set month 5
 */
select p_personid, p_firstname, p_lastname,
       ( select count(distinct m_messageid)
         from message, message_tag pt1
         where
         m_creatorid = p_personid and
         m_c_replyof IS NULL and -- post, not comment
         m_messageid = mt_messageid and
         exists (select * from person_tag where pt_personid = :personId and pt_tagid = pt1.mt_tagid)
       ) -
       ( select count(*)
         from message
         where
         m_creatorid = p_personid and
         m_c_replyof IS NULL and -- post, not comment
         not exists (select * from person_tag, message_tag where pt_personid = :personId and pt_tagid = mt_tagid and mt_messageid = m_messageid)
       ) as score,
       p_gender, pl_name
from person, place,
 ( select distinct k2.k_person2id
   from knows k1, knows k2
   where
   k1.k_person1id = :personId and k1.k_person2id = k2.k_person1id and k2.k_person2id <> :personId and
   not exists (select * from knows where k_person1id = :personId and k_person2id = k2.k_person2id)
 ) f
where
p_placeid = pl_placeid and
p_personid = f.k_person2id and
(
    (extract(month from p_birthday) = :month and (case when extract(day from p_birthday) >= 21 then true else false end))
    or
    (extract(month from p_birthday) = :month % 12 + 1 and (case when extract(day from p_birthday) <  22 then true else false end))
)
order by score desc, p_personid
limit 10
;


/* Q11. Job referral
\set personId 10995116277918
\set countryName '\'Hungary\''
\set workFromYear 2011
 */
select p_personid,p_firstname, p_lastname, o_name, pc_workfrom
from person, person_company, organisation, place,
 ( select k_person2id
   from knows
   where
   k_person1id = :personId
   union
   select k2.k_person2id
   from knows k1, knows k2
   where
   k1.k_person1id = :personId and k1.k_person2id = k2.k_person1id and k2.k_person2id <> :personId
 ) f
where
    p_personid = f.k_person2id and
    p_personid = pc_personid and
    pc_organisationid = o_organisationid and
    pc_workfrom < :workFromYear and
    o_placeid = pl_placeid and
    pl_name = :countryName
order by pc_workfrom, p_personid, o_name desc
limit 10
;


/* Q12. Expert search
\set personId 10995116278009
\set tagClassName '\'Monarch\''
 */
with recursive extended_tags(s_subtagclassid,s_supertagclassid) as (
    select tc_tagclassid, tc_tagclassid from tagclass
    UNION
    select tc.tc_tagclassid, t.s_supertagclassid from tagclass tc, extended_tags t
        where tc.tc_subclassoftagclassid=t.s_subtagclassid
)
select p_personid, p_firstname, p_lastname, array_agg(distinct t_name), count(*)
from person, message p1, knows, message p2, message_tag, 
    (select distinct t_tagid, t_name from tag where (t_tagclassid in (
          select distinct s_subtagclassid from extended_tags k, tagclass
        where tc_tagclassid = k.s_supertagclassid and tc_name = :tagClassName) 
   )) selected_tags
where
  k_person1id = :personId and 
  k_person2id = p_personid and 
  p_personid = p1.m_creatorid and 
  p1.m_c_replyof = p2.m_messageid and 
  p2.m_c_replyof is null and
  p2.m_messageid = mt_messageid and 
  mt_tagid = t_tagid
group by p_personid, p_firstname, p_lastname
order by 5 desc, 1
limit 20
;


/* Q13. Single shortest path
\set person1Id 8796093022390
\set person2Id 8796093022357
 */
WITH RECURSIVE search_graph(link, depth, path) AS (
        SELECT :person1Id::bigint, 0, ARRAY[:person1Id::bigint]::bigint[]
      UNION ALL
          (WITH sg(link,depth) as (select * from search_graph) -- Note: sg is only the diff produced in the previous iteration
          SELECT distinct k_person2id, x.depth+1, array_append(path, k_person2id)
          FROM knows, sg x
          WHERE 1=1
          and x.link = k_person1id
          and k_person2id <> ALL (path)
          -- stop if we have reached person2 in the previous iteration
          and not exists(select * from sg y where y.link = :person2Id::bigint)
          -- skip reaching persons reached in the previous iteration
          and not exists(select * from sg y where y.link = k_person2id)
        )
)
select max(depth) from (
select depth from search_graph where link = :person2Id::bigint
union select -1) tmp;
;


/* Q14. Trusted connection paths
\set person1Id 8796093022357
\set person2Id 8796093022390
 */
WITH start_node(v) AS (
    SELECT :person1Id::bigint
)
select * from (
    WITH RECURSIVE
    search_graph(link, depth, path) AS (
            (SELECT v::bigint, 0, ARRAY[]::bigint[][] from start_node)
          UNION ALL
            (WITH sg(link,depth) as (select * from search_graph)
            SELECT distinct k_person2id, x.depth + 1,path || ARRAY[[x.link, k_person2id]]
            FROM knows, sg x
            WHERE x.link = k_person1id and not exists(select * from sg y where y.link = :person2Id::bigint) and not exists( select * from sg y where y.link=k_person2id)
            )
    ),
    paths(pid,path) AS (
        SELECT row_number() OVER (), path FROM search_graph where link = :person2Id::bigint
    ),
    edges(id,e) AS (
        SELECT pid, array_agg(path[d1][d2])
        FROM  paths, generate_subscripts(path,1) d1,generate_subscripts(path,2) d2
        GROUP  BY pid,d1
    ),
    unique_edges(e) AS (
        SELECT DISTINCT e from edges
    ),
    weights(we, score) as (
        select e,sum(score) from (
            select e, pid1, pid2, max(score) as score from (
                select e, 1 as score, p1.m_messageid as pid1, p2.m_messageid as pid2 from edges, message p1, message p2 where (p1.m_creatorid=e[1] and p2.m_creatorid=e[2] and p2.m_c_replyof=p1.m_messageid and p1.m_c_replyof is null)
                union all
                select e, 1 as score, p1.m_messageid as pid1, p2.m_messageid as pid2 from edges, message p1, message p2 where (p1.m_creatorid=e[2] and p2.m_creatorid=e[1] and p2.m_c_replyof=p1.m_messageid and p1.m_c_replyof is null)
                union all
                select e, 0.5 as score, p1.m_messageid as pid1, p2.m_messageid as pid2 from edges, message p1, message p2 where (p1.m_creatorid=e[1] and p2.m_creatorid=e[2] and p2.m_c_replyof=p1.m_messageid and p1.m_c_replyof is not null)
                union all
                select e, 0.5 as score, p1.m_messageid as pid1, p2.m_messageid as pid2  from edges, message p1, message p2 where (p1.m_creatorid=e[2] and p2.m_creatorid=e[1] and p2.m_c_replyof=p1.m_messageid and p1.m_c_replyof is not null)
            ) pps group by e,pid1,pid2
        ) tmp
        group by e
    ),
    weightedpaths(path,score) as (
        select path, coalesce(sum(score),0) from paths, edges left join weights on we=e where pid=id group by id,path
    )
    select path,score from weightedpaths order by score desc)
x  order by score desc;
;





/* IS1. Profile of a person
\set personId 10995116277794
 */
select p_firstname, p_lastname, p_birthday, p_locationip, p_browserused, p_placeid, p_gender,  p_creationdate
from person
where p_personid = :personId;
;


/* IS2. Recent messages of a person
\set personId 10995116277795
 */
with recursive cposts(m_messageid, m_content, m_ps_imagefile, m_creationdate, m_c_replyof, m_creatorid) AS (
      select m_messageid, m_content, m_ps_imagefile, m_creationdate, m_c_replyof, m_creatorid
      from message
      where m_creatorid = :personId
      order by m_creationdate desc
      limit 10
), parent(postid,replyof,orig_postid,creator) AS (
      select m_messageid, m_c_replyof, m_messageid, m_creatorid from cposts
    UNION ALL
      select m_messageid, m_c_replyof, orig_postid, m_creatorid
      from message,parent
      where m_messageid=replyof
)
select p1.m_messageid, COALESCE(m_ps_imagefile, m_content, ''), p1.m_creationdate,
       p2.m_messageid, p2.p_personid, p2.p_firstname, p2.p_lastname
from 
     (select m_messageid, m_content, m_ps_imagefile, m_creationdate, m_c_replyof from cposts
     ) p1
     left join
     (select orig_postid, postid as m_messageid, p_personid, p_firstname, p_lastname
      from parent, person
      where replyof is null and creator = p_personid
     )p2  
     on p2.orig_postid = p1.m_messageid
      order by m_creationdate desc, p2.m_messageid desc;
;


/* IS3. Friends of a person
\set personId 10995116277794
 */
select p_personid, p_firstname, p_lastname, k_creationdate
from knows, person
where k_person1id = :personId and k_person2id = p_personid
order by k_creationdate desc, p_personid asc;
;


/* IS4. Content of a message
\set messageId 206158431836
 */
select COALESCE(m_ps_imagefile, m_content, ''), m_creationdate
from message
where m_messageid = :messageId;
;


/* IS5. Creator of a message
\set messageId 206158431836
 */
select p_personid, p_firstname, p_lastname
from message, person
where m_messageid = :messageId and m_creatorid = p_personid;
;


/* IS6. Forum of a message
\set messageId 206158431836
 */
WITH RECURSIVE chain(parent, child) as(
    SELECT m_c_replyof, m_messageid FROM message where m_messageid = :messageId
    UNION ALL
    SELECT p.m_c_replyof, p.m_messageid FROM message p, chain c where p.m_messageid = c.parent 
)
select f_forumid, f_title, p_personid, p_firstname, p_lastname
from message, person, forum
where m_messageid = (select coalesce(min(parent), :messageId) from chain)
  and m_ps_forumid = f_forumid and f_moderatorid = p_personid;
;


/* IS7. Replies of a message
\set messageId 206158432794
 */
select p2.m_messageid, p2.m_content, p2.m_creationdate, p_personid, p_firstname, p_lastname,
    (case when exists (
                       select 1 from knows
               where p1.m_creatorid = k_person1id and p2.m_creatorid = k_person2id)
      then TRUE
      else FALSE
      end)
from message p1, message p2, person
where
  p1.m_messageid = :messageId and p2.m_c_replyof = p1.m_messageid and p2.m_creatorid = p_personid
order by p2.m_creationdate desc, p2.m_creatorid asc;
;
insert into person_company (
    pc_personid
  , pc_organisationid
  , pc_workfrom
)
values
(
    :personId
  , :organizationId
  , :worksFromYear
);
insert into person_email (
    pe_personid
  , pe_email
)
values
(
    :personId
  , :email
);
insert into person_language (
    plang_personid
  , plang_language
)
values
(
    :personId
  , :language
);
insert into person_tag (
    pt_personid
  , pt_tagid
)
values
(
    :personId
  , :tagId
);
insert into person_university (
    pu_personid
  , pu_organisationid
  , pu_classyear
)
values
(
    :personId
  , :organizationId
  , :studiesFromYear
);
insert into person (
    p_personid
  , p_firstname
  , p_lastname
  , p_gender
  , p_birthday
  , p_creationdate
  , p_locationip
  , p_browserused
  , p_placeid
)
values
(
    :personId
  , :personFirstName
  , :personLastName
  , :gender
  , :birthday
  , :creationDate
  , :locationIP
  , :browserUsed
  , :cityId
);
insert into likes (
    l_personid
  , l_messageid
  , l_creationdate
)
values
(
    :personId
  , :postId
  , :creationDate
);
insert into likes (
    l_personid
  , l_messageid
  , l_creationdate
)
values
(
    :personId
  , :commentId
  , :creationDate
);
insert into forum_tag (
    ft_forumid
  , ft_tagid
)
values
(
    :forumId
  , :tagId
);
insert into forum (
    f_forumid
  , f_title
  , f_creationdate
  , f_moderatorid
)
values
(
    :forumId
  , :forumTitle
  , :creationDate
  , :moderatorPersonId
);
insert into forum_person (
    fp_forumid
  , fp_personid
  , fp_joindate
)
values
(
    :forumId
  , :personId
  , :joinDate
);
insert into message_tag (
    mt_messageid
  , mt_tagid
)
values
(
    :postId
  , :tagId
);
insert into message (
    -- only post-related fields are filled explicitly
    m_messageid
  , m_ps_imagefile
  , m_creationdate
  , m_locationip
  , m_browserused
  , m_ps_language
  , m_content
  , m_length
  , m_creatorid
  , m_locationid
  , m_ps_forumid
)
values
(
    :postId
  , CASE :imageFile WHEN '' THEN NULL ELSE :imageFile END
  , :creationDate
  , :locationIP
  , :browserUsed
  , :language
  , CASE :content WHEN '' THEN NULL ELSE :content END
  , :length
  , :authorPersonId
  , :countryId
  , :forumId
);
insert into message_tag (
    mt_messageid
  , mt_tagid
)
values
(
    :commentId
  , :tagId
);
insert into message (
    -- only comment-related fields are filled explicitly
    m_messageid
  , m_creationdate
  , m_locationip
  , m_browserused
  , m_content
  , m_length
  , m_creatorid
  , m_locationid
  , m_c_replyof
)
values
(
    :commentId
  , :creationDate
  , :locationIP
  , :browserUsed
  , :content
  , :length
  , :authorPersonId
  , :countryId
  , :replyToCommentId + :replyToPostId + 1 -- replyToCommentId is -1 if the message is a reply to a post and vica versa (see spec)
);
insert into knows (
    k_person1id
  , k_person2id
  , k_creationdate
)
values
(
    :person1Id
  , :person2Id
  , :creationDate
),
(
    :person2Id
  , :person1Id
  , :creationDate
);
