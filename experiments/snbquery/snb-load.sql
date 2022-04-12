-- Populate forum table
COPY forum FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Forum/part_0_0.csv' WITH DELIMITER '|' CSV HEADER;

-- Populate forum_person table
COPY forum_person FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Forum_hasMember_Person/part_0_0.csv' WITH DELIMITER '|' CSV HEADER;
COPY forum_person FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Forum_hasMember_Person/part_0_1.csv' WITH DELIMITER '|' CSV HEADER;
COPY forum_person FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Forum_hasMember_Person/part_0_2.csv' WITH DELIMITER '|' CSV HEADER;
COPY forum_person FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Forum_hasMember_Person/part_0_3.csv' WITH DELIMITER '|' CSV HEADER;
COPY forum_person FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Forum_hasMember_Person/part_0_4.csv' WITH DELIMITER '|' CSV HEADER;
COPY forum_person FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Forum_hasMember_Person/part_0_5.csv' WITH DELIMITER '|' CSV HEADER;
COPY forum_person FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Forum_hasMember_Person/part_0_6.csv' WITH DELIMITER '|' CSV HEADER;


-- Populate forum_tag table
COPY forum_tag FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Forum_hasTag_Tag/part_0_0.csv' WITH DELIMITER '|' CSV HEADER;

-- Populate organisation table
COPY organisation FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/static/Organisation/part_0_0.csv' WITH DELIMITER '|' CSV HEADER;

-- Populate person table
COPY person FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Person/part_0_0.csv' WITH DELIMITER '|' CSV HEADER;

-- Populate person_email table
COPY person_email FROM '/data/dynamic/person_email_emailaddress_0_0.csv' WITH DELIMITER '|' CSV HEADER;

-- Populate person_tag table
COPY person_tag FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Person_hasInterest_Tag/part_0_0.csv' WITH DELIMITER '|' CSV HEADER;

-- Populate knows table
COPY knows ( k_creationdate, k_deletiondate, k_explicitlyDeleted, k_person1id, k_person2id) FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Person_knows_Person/part_0_0.csv' WITH DELIMITER '|' CSV HEADER;
COPY knows ( k_creationdate, k_deletiondate, k_explicitlyDeleted, k_person2id, k_person1id) FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Person_knows_Person/part_0_0.csv' WITH DELIMITER '|' CSV HEADER;

-- Populate likes table
COPY likes FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Person_likes_Post/part_0_0.csv' WITH DELIMITER '|' CSV HEADER;
COPY likes FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Person_likes_Post/part_0_1.csv' WITH DELIMITER '|' CSV HEADER;
COPY likes FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Person_likes_Post/part_0_2.csv' WITH DELIMITER '|' CSV HEADER;
COPY likes FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Person_likes_Comment/part_0_0.csv' WITH DELIMITER '|' CSV HEADER;
COPY likes FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Person_likes_Comment/part_0_1.csv' WITH DELIMITER '|' CSV HEADER;
COPY likes FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Person_likes_Comment/part_0_2.csv' WITH DELIMITER '|' CSV HEADER;
COPY likes FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Person_likes_Comment/part_0_3.csv' WITH DELIMITER '|' CSV HEADER;
COPY likes FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Person_likes_Comment/part_0_4.csv' WITH DELIMITER '|' CSV HEADER;
COPY likes FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Person_likes_Comment/part_0_5.csv' WITH DELIMITER '|' CSV HEADER;


-- Populate person_language table
COPY person_language FROM '/data/dynamic/person_speaks_language_0_0.csv' WITH DELIMITER '|' CSV HEADER;

-- Populate person_university table
COPY person_university FROM '/data/dynamic/person_studyAt_organisation_0_0.csv' WITH DELIMITER '|' CSV HEADER;

-- Populate person_company table
COPY person_company FROM '/data/dynamic/person_workAt_organisation_0_0.csv' WITH DELIMITER '|' CSV HEADER;

-- Populate place table
COPY place FROM '/data/static/place_0_0.csv' WITH DELIMITER '|' CSV HEADER;

-- Populate message_tag table
COPY message_tag FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Post_hasTag_Tag/part_0_0.csv' WITH DELIMITER '|' CSV HEADER;
COPY message_tag FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Post_hasTag_Tag/part_0_1.csv' WITH DELIMITER '|' CSV HEADER;
COPY message_tag FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Forum_hasTag_Tag/part_0_0.csv' WITH DELIMITER '|' CSV HEADER;

-- Populate tagclass table
COPY tagclass FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/static/TagClass/part_0_0.csv' WITH DELIMITER '|' CSV HEADER;

-- Populate tag table
COPY tag FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/static/Tag/part_0_0.csv' WITH DELIMITER '|' CSV HEADER;


-- PROBLEMATIC

-- Populate message table
COPY message (m_creationdate, m_deletionDate, m_explicitlyDeleted, m_messageid, m_locationip, m_browserused, m_content, m_length, m_creatorid, m_locationid, m_c_parentpostid, m_c_replyof) FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Comment/part_0_0.csv' WITH (DELIMITER '|', HEADER, FORMAT csv);
COPY message (m_creationdate, m_deletionDate, m_explicitlyDeleted, m_messageid, m_locationip, m_browserused, m_content, m_length, m_creatorid, m_locationid, m_c_parentpostid, m_c_replyof) FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Comment/part_0_1.csv' WITH (DELIMITER '|', HEADER, FORMAT csv);
COPY message (m_creationdate, m_deletionDate, m_explicitlyDeleted, m_messageid, m_locationip, m_browserused, m_content, m_length, m_creatorid, m_locationid, m_c_parentpostid, m_c_replyof) FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Comment/part_0_2.csv' WITH (DELIMITER '|', HEADER, FORMAT csv);
COPY message (m_creationdate, m_deletionDate, m_explicitlyDeleted, m_messageid, m_locationip, m_browserused, m_content, m_length, m_creatorid, m_locationid, m_c_parentpostid, m_c_replyof) FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Comment/part_0_3.csv' WITH (DELIMITER '|', HEADER, FORMAT csv);
COPY message (m_creationdate, m_deletionDate, m_explicitlyDeleted, m_messageid, m_locationip, m_browserused, m_content, m_length, m_creatorid, m_locationid, m_c_parentpostid, m_c_replyof) FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Comment/part_0_4.csv' WITH (DELIMITER '|', HEADER, FORMAT csv);
COPY message (m_creationdate, m_deletionDate, m_explicitlyDeleted, m_messageid, m_locationip, m_browserused, m_content, m_length, m_creatorid, m_locationid, m_c_parentpostid, m_c_replyof) FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Comment/part_0_5.csv' WITH (DELIMITER '|', HEADER, FORMAT csv);
COPY message (m_creationdate, m_deletionDate, m_explicitlyDeleted, m_messageid, m_locationip, m_browserused, m_content, m_length, m_creatorid, m_locationid, m_c_parentpostid, m_c_replyof) FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Comment/part_0_6.csv' WITH (DELIMITER '|', HEADER, FORMAT csv);
COPY message (m_creationdate, m_deletionDate, m_explicitlyDeleted, m_messageid, m_locationip, m_browserused, m_content, m_length, m_creatorid, m_locationid, m_c_parentpostid, m_c_replyof) FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Comment/part_0_7.csv' WITH (DELIMITER '|', HEADER, FORMAT csv);

COPY message (m_creationdate, m_deletionDate, m_explicitlyDeleted, m_messageid, m_ps_imagefile, m_locationip, m_browserused, m_ps_language, m_content, m_length, m_creatorid, m_ps_forumid, m_locationid) FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Post/part_0_0.csv' WITH (DELIMITER '|', HEADER, FORMAT csv);
COPY message (m_creationdate, m_deletionDate, m_explicitlyDeleted, m_messageid, m_ps_imagefile, m_locationip, m_browserused, m_ps_language, m_content, m_length, m_creatorid, m_ps_forumid, m_locationid) FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Post/part_0_1.csv' WITH (DELIMITER '|', HEADER, FORMAT csv);
COPY message (m_creationdate, m_deletionDate, m_explicitlyDeleted, m_messageid, m_ps_imagefile, m_locationip, m_browserused, m_ps_language, m_content, m_length, m_creatorid, m_ps_forumid, m_locationid) FROM '/home/data/continuous/benchmarks/ldbc_snb_datagen_spark/out/csv/raw/composite-merged-fk/dynamic/Post/part_0_2.csv' WITH (DELIMITER '|', HEADER, FORMAT csv);

COPY message (m_messageid, m_ps_imagefile, m_creationdate, m_locationip, m_browserused, m_ps_language, m_content, m_length, m_creatorid, m_ps_forumid, m_locationid) FROM '/data/dynamic/post_0_0.csv' WITH (DELIMITER '|', HEADER, FORMAT csv);
COPY message FROM '/data/dynamic/comment_0_0-postgres.csv' WITH (DELIMITER '|', HEADER, FORMAT csv);

CREATE view country AS SELECT city.pl_placeid AS ctry_city, ctry.pl_name AS ctry_name FROM place city, place ctry WHERE city.pl_containerplaceid = ctry.pl_placeid AND ctry.pl_type = 'country';
