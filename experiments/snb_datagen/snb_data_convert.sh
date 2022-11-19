#!/bin/bash

SF="0_003"
BASE_PATH="/path/to/snb_datagen_base"
SRC_PATH="/path/to/snb_datagen_base/ldbc_snb_datagen_spark/out/graphs/csv/raw/composite-merged-fk"
TARGET_PATH="${BASE_PATH}/SF_${SF}"

PG_USERNAME="user"
PG_PORT="5432"
PG_DATABASE="snb_sf${SF}"
psql_cmd="/path/to/postgresql/bin/psql"

echo "SF = ${SF}"
echo "create snb data under ${TARGET_PATH}/"

mkdir -p "${TARGET_PATH}"

echo "create tables in pg"
${psql_cmd} -p "${PG_PORT}" -U "${PG_USERNAME}" -d "${PG_DATABASE}" -f ./create_tables.sql

rm -f pg_tmp.sql
touch pg_tmp.sql


comment_files=$(find "${SRC_PATH}/dynamic/Comment" -name "part*.csv" | head)
for comment_file in ${comment_files[@]}; do
	echo "copy message from ${comment_file}"
	echo "COPY message (m_creationdate, m_deletionDate, m_explicitlyDeleted, m_messageid, m_locationip, m_browserused, m_content, m_length, m_creatorid, m_locationid, m_c_parentpostid, m_c_replyof) FROM '${comment_file}' WITH DELIMITER '|' CSV HEADER;" >> pg_tmp.sql
done

post_files=$(find "${SRC_PATH}/dynamic/Post" -name "part*.csv" | head)
for post_file in ${post_files[@]}; do
  echo "copy message from ${post_file}"
  echo "COPY message (m_creationdate, m_deletionDate, m_explicitlyDeleted, m_messageid, m_ps_imagefile, m_locationip, m_browserused, m_ps_language, m_content, m_length, m_creatorid, m_ps_forumid, m_locationid) FROM '${post_file}' WITH DELIMITER '|' CSV HEADER;" >> pg_tmp.sql
done

person_files=$(find "${SRC_PATH}/dynamic/Person" -name "part*.csv" | head)
for person_file in ${person_files[@]}; do
  echo "copy person from ${person_file}"
  echo "COPY person FROM '${person_file}' WITH DELIMITER '|' CSV HEADER;" >> pg_tmp.sql
done

knows_files=$(find "${SRC_PATH}/dynamic/Person_knows_Person" -name "part*.csv" | head)
for knows_file in ${knows_files[@]}; do
  echo "copy knows from ${knows_file}"
  echo "COPY knows ( k_creationdate, k_deletiondate, k_explicitlyDeleted, k_person1id, k_person2id) FROM '${knows_file}' WITH DELIMITER '|' CSV HEADER;" >> pg_tmp.sql
  echo "COPY knows ( k_creationdate, k_deletiondate, k_explicitlyDeleted, k_person2id, k_person1id) FROM '${knows_file}' WITH DELIMITER '|' CSV HEADER;" >> pg_tmp.sql
done

message_tag_files=$(find "${SRC_PATH}/dynamic/Post_hasTag_Tag" -name "part*.csv" | head)
for message_tag_file in ${message_tag_files[@]}; do
  echo "copy message_tag from ${message_tag_file}"
  echo "COPY message_tag FROM '${message_tag_file}' WITH DELIMITER '|' CSV HEADER;" >> pg_tmp.sql
done

message_tag2_files=$(find "${SRC_PATH}/dynamic/Forum_hasTag_Tag" -name "part*.csv" | head)
for message_tag2_file in ${message_tag2_files[@]}; do
  echo "copy message_tag from ${message_tag2_file}"
  echo "COPY message_tag FROM '${message_tag2_file}' WITH DELIMITER '|' CSV HEADER;" >> pg_tmp.sql
done

tag_files=$(find "${SRC_PATH}/static/Tag" -name "part*.csv" | head)
for tag_file in ${tag_files[@]}; do
  echo "copy tag from ${tag_file}"
  echo "COPY tag FROM '${tag_file}' WITH DELIMITER '|' CSV HEADER;" >> pg_tmp.sql
done

echo "execute load data sql"
${psql_cmd} -p "${PG_PORT}" -U "${PG_USERNAME}" -d "${PG_DATABASE}" -f ./pg_tmp.sql

echo "execute convert data sql"
${psql_cmd} -p "${PG_PORT}" -U "${PG_USERNAME}" -d "${PG_DATABASE}" -f ./convert_data.sql

psql_result=$(${psql_cmd} -p "${PG_PORT}" -U "${PG_USERNAME}" -d "${PG_DATABASE}" -f ./get_tag_timestamp.sql)
tag_timestamp=$(echo ${psql_result} | awk -v FS=" " '{print $3}')
echo "pick tag_timestamp as ${tag_timestamp}"

trill_data_path="${TARGET_PATH}/trill"
mkdir -p "${trill_data_path}"
mkdir -p "${trill_data_path}/snb1_arbitrary"
mkdir -p "${trill_data_path}/snb2_arbitrary"
mkdir -p "${trill_data_path}/snb3_arbitrary"
mkdir -p "${trill_data_path}/snb4_arbitrary"
mkdir -p "${trill_data_path}/snb1_window"
mkdir -p "${trill_data_path}/snb2_window"
mkdir -p "${trill_data_path}/snb3_window"
mkdir -p "${trill_data_path}/snb4_window"
echo "save trill data to ${trill_data_path}"
rm -f pg_tmp.sql
touch pg_tmp.sql

echo "COPY (select CAST (extract(EPOCH FROM message.m_creationdate) AS BIGINT), CAST (extract(EPOCH FROM message.m_deletionDate) AS BIGINT), (CASE WHEN m_explicitlyDeleted = TRUE THEN 'true' ELSE 'false' END), m_messageid, m_ps_imagefile, m_locationip, m_browserused, m_ps_language, m_content, m_length, m_creatorid, m_locationid, m_ps_forumid, m_c_parentpostid,m_c_replyof from message where message.m_deletionDate > message.m_creationdate order by m_creationdate) to '${trill_data_path}/snb1_arbitrary/trill.message.arbitrary.csv' DELIMITER '|';" >> pg_tmp.sql
echo "COPY (select  CAST (extract(EPOCH FROM p_creationdate) AS BIGINT), CAST (extract(EPOCH FROM p_deletiondate) AS BIGINT), (CASE WHEN p_explicitlyDeleted = TRUE THEN 'true' ELSE 'false' END), person.p_personid, person.p_firstname, person.p_lastname, person.p_gender, person.p_birthday, person.p_locationip, person.p_browserused, person.p_placeid, person.p_language, person.p_email from person where p_deletiondate > p_creationdate order by p_creationdate) to '${trill_data_path}/snb1_arbitrary/trill.person.arbitrary.csv' DELIMITER '|';" >> pg_tmp.sql
echo "COPY (select  CAST (extract(EPOCH FROM k_creationdate) AS BIGINT), CAST (extract(EPOCH FROM k_deletiondate) AS BIGINT), (CASE WHEN k_explicitlyDeleted = TRUE THEN 'true' ELSE 'false' END), knows.k_person1id, knows.k_person2id from knows where k_deletiondate > k_creationdate order by k_creationdate) TO '${trill_data_path}/snb1_arbitrary/trill.knows.arbitrary.csv' DELIMITER '|';" >> pg_tmp.sql
echo "COPY (select  CAST (extract(EPOCH FROM mt_creationdate) AS BIGINT), CAST (extract(EPOCH FROM mt_deletiondate) AS BIGINT), message_tag.mt_messageid, message_tag.mt_tagid from message_tag where mt_deletiondate > mt_creationdate order by mt_creationdate) TO '${trill_data_path}/snb1_arbitrary/trill.messagetag.arbitrary.csv' DELIMITER '|';" >> pg_tmp.sql
echo "COPY (select ${tag_timestamp}, t_tagid, t_name, t_url, t_tagclassid from tag) to '${trill_data_path}/snb1_arbitrary/trill.tag.arbitrary.csv' DELIMITER '|';" >> pg_tmp.sql

${psql_cmd} -p "${PG_PORT}" -U "${PG_USERNAME}" -d "${PG_DATABASE}" -f ./pg_tmp.sql

cp ${trill_data_path}/snb1_arbitrary/* ${trill_data_path}/snb2_arbitrary/
cp ${trill_data_path}/snb1_arbitrary/* ${trill_data_path}/snb3_arbitrary/
cp ${trill_data_path}/snb1_arbitrary/* ${trill_data_path}/snb4_arbitrary/

cp ${trill_data_path}/snb1_arbitrary/trill.message.arbitrary.csv ${trill_data_path}/snb1_window/trill.message.window.csv
cp ${trill_data_path}/snb1_arbitrary/trill.person.arbitrary.csv ${trill_data_path}/snb1_window/trill.person.window.csv
cp ${trill_data_path}/snb1_arbitrary/trill.knows.arbitrary.csv ${trill_data_path}/snb1_window/trill.knows.window.csv
cp ${trill_data_path}/snb1_arbitrary/trill.messagetag.arbitrary.csv ${trill_data_path}/snb1_window/trill.messagetag.window.csv
cp ${trill_data_path}/snb1_arbitrary/trill.tag.arbitrary.csv ${trill_data_path}/snb1_window/trill.tag.window.csv

cp ${trill_data_path}/snb1_window/* ${trill_data_path}/snb2_window/
cp ${trill_data_path}/snb1_window/* ${trill_data_path}/snb3_window/
cp ${trill_data_path}/snb1_window/* ${trill_data_path}/snb4_window/
echo "finish trill snb data"


flink_data_path="${TARGET_PATH}/flink"
mkdir -p "${flink_data_path}"
mkdir -p "${flink_data_path}/snb1_arbitrary"
mkdir -p "${flink_data_path}/snb2_arbitrary"
mkdir -p "${flink_data_path}/snb3_arbitrary"
mkdir -p "${flink_data_path}/snb4_arbitrary"
mkdir -p "${flink_data_path}/snb1_window"
mkdir -p "${flink_data_path}/snb2_window"
mkdir -p "${flink_data_path}/snb3_window"
mkdir -p "${flink_data_path}/snb4_window"
echo "save flink data to ${flink_data_path}"
rm -f pg_tmp.sql
touch pg_tmp.sql

# flink window
echo "COPY (select CAST (extract(EPOCH FROM message.m_creationdate) * 1000 AS BIGINT) as m_op_time, (CASE WHEN message.m_explicitlyDeleted = TRUE THEN 'true' ELSE 'false' END), message.m_messageid, message.m_ps_imagefile,message.m_locationip,message.m_browserused,message.m_ps_language,message.m_content,message.m_length,message.m_creatorid,message.m_locationid,message.m_ps_forumid,message.m_c_parentpostid,message.m_c_replyof from message order by m_op_time asc) to '${flink_data_path}/snb1_window/flink.message.window.csv' DELIMITER '|';" >> pg_tmp.sql
echo "COPY (select CAST (extract(EPOCH FROM p_creationdate) * 1000 AS BIGINT) as p_op_time, (CASE WHEN p_explicitlyDeleted = TRUE THEN 'true' ELSE 'false' END), person.p_personid,person.p_firstname,person.p_lastname,person.p_gender,person.p_birthday,person.p_locationip,person.p_browserused,person.p_placeid,person.p_language,person.p_email from person  order by p_op_time asc) to '${flink_data_path}/snb1_window/flink.person.window.csv' DELIMITER '|';" >> pg_tmp.sql
echo "COPY (select CAST (extract(EPOCH FROM k_creationdate) * 1000 AS BIGINT) as k_op_time, (CASE WHEN k_explicitlyDeleted = TRUE THEN 'true' ELSE 'false' END),knows.k_person1id,knows.k_person2id from knows order by k_op_time asc) to '${flink_data_path}/snb1_window/flink.knows.window.csv' DELIMITER '|';" >> pg_tmp.sql
echo "COPY (select CAST (extract(EPOCH FROM mt_creationdate) * 1000 AS BIGINT) as mt_op_time, message_tag.mt_messageid,message_tag.mt_tagid from message_tag order by mt_op_time asc) to '${flink_data_path}/snb1_window/flink.messagetag.window.csv' DELIMITER '|';" >> pg_tmp.sql
echo "COPY (select * from tag) to '${flink_data_path}/snb1_window/flink.tag.window.csv' DELIMITER '|';" >> pg_tmp.sql

${psql_cmd} -p "${PG_PORT}" -U "${PG_USERNAME}" -d "${PG_DATABASE}" -f ./pg_tmp.sql


echo "convert flink ts"
rm -f ${TARGET_PATH}/flink.tmp.csv
scala ./FlinkTimestampConvertor.scala ${flink_data_path}/snb1_window/flink.message.window.csv ${TARGET_PATH}/flink.tmp.csv
cp -f ${TARGET_PATH}/flink.tmp.csv ${flink_data_path}/snb1_window/flink.message.window.csv

scala ./FlinkTimestampConvertor.scala ${flink_data_path}/snb1_window/flink.person.window.csv ${TARGET_PATH}/flink.tmp.csv
cp -f ${TARGET_PATH}/flink.tmp.csv ${flink_data_path}/snb1_window/flink.person.window.csv

scala ./FlinkTimestampConvertor.scala ${flink_data_path}/snb1_window/flink.knows.window.csv ${TARGET_PATH}/flink.tmp.csv
cp -f ${TARGET_PATH}/flink.tmp.csv ${flink_data_path}/snb1_window/flink.knows.window.csv

scala ./FlinkTimestampConvertor.scala ${flink_data_path}/snb1_window/flink.messagetag.window.csv ${TARGET_PATH}/flink.tmp.csv
cp -f ${TARGET_PATH}/flink.tmp.csv ${flink_data_path}/snb1_window/flink.messagetag.window.csv

rm -f ${TARGET_PATH}/flink.tmp.csv

cp ${flink_data_path}/snb1_window/* ${flink_data_path}/snb2_window/
cp ${flink_data_path}/snb1_window/* ${flink_data_path}/snb3_window/
cp ${flink_data_path}/snb1_window/* ${flink_data_path}/snb4_window/

# flink arbitrary
rm -f pg_tmp.sql
touch pg_tmp.sql

echo "COPY (select (CASE WHEN m_op = 1 THEN '+' ELSE '-' END), (CASE WHEN m_explicitlyDeleted = TRUE THEN 'true' ELSE 'false' END), m_messageid, m_ps_imagefile, m_locationip, m_browserused, m_ps_language, m_content, m_length, m_creatorid, m_locationid, m_ps_forumid, m_c_parentpostid,m_c_replyof from messageT order by m_op_time asc, m_op desc) to '${flink_data_path}/snb1_arbitrary/flink.message.arbitrary.csv' DELIMITER '|';" >> pg_tmp.sql
echo "COPY (select (CASE WHEN p_op = 1 THEN '+' ELSE '-' END), (CASE WHEN p_explicitlyDeleted = TRUE THEN 'true' ELSE 'false' END), p_personid, p_firstname, p_lastname, p_gender, p_birthday, p_locationip, p_browserused, p_placeid, p_language, p_email from personT order by p_op_time asc, p_op desc) to '${flink_data_path}/snb1_arbitrary/flink.person.arbitrary.csv' DELIMITER '|';" >> pg_tmp.sql
echo "COPY (select (CASE WHEN k_op = 1 THEN '+' ELSE '-' END), (CASE WHEN k_explicitlyDeleted = TRUE THEN 'true' ELSE 'false' END), k_personid1, k_personid2 from knowsT order by k_op_time asc, k_op desc) to '${flink_data_path}/snb1_arbitrary/flink.knows.arbitrary.csv' DELIMITER '|';" >> pg_tmp.sql
echo "COPY (select (CASE WHEN mt_op = 1 THEN '+' ELSE '-' END), mt_messageid, mt_tagid from message_tagT order by mt_op_time asc, mt_op desc) to '${flink_data_path}/snb1_arbitrary/flink.messagetag.arbitrary.csv' DELIMITER '|';" >> pg_tmp.sql
echo "COPY (select * from tag) to '${flink_data_path}/snb1_arbitrary/flink.tag.arbitrary.csv' DELIMITER '|';" >> pg_tmp.sql

${psql_cmd} -p "${PG_PORT}" -U "${PG_USERNAME}" -d "${PG_DATABASE}" -f ./pg_tmp.sql


cp ${flink_data_path}/snb1_arbitrary/* ${flink_data_path}/snb2_arbitrary/
cp ${flink_data_path}/snb1_arbitrary/* ${flink_data_path}/snb3_arbitrary/
cp ${flink_data_path}/snb1_arbitrary/* ${flink_data_path}/snb4_arbitrary/

echo "finish flink snb data"

# first create raw data for acq(D/F), dbt(spark/cpp)
raw_window_data_path="${TARGET_PATH}/raw_window"
raw_arbitrary_data_path="${TARGET_PATH}/raw_arbitrary"
raw_output_data_path="${TARGET_PATH}/tmp_output"
mkdir -p "${raw_window_data_path}"
mkdir -p "${raw_arbitrary_data_path}"
mkdir -p "${raw_output_data_path}"

acq_data_path="${TARGET_PATH}/crown"
mkdir -p "${acq_data_path}"
mkdir -p "${acq_data_path}/snb1_arbitrary"
mkdir -p "${acq_data_path}/snb2_arbitrary"
mkdir -p "${acq_data_path}/snb3_arbitrary"
mkdir -p "${acq_data_path}/snb4_arbitrary"
mkdir -p "${acq_data_path}/snb1_window"
mkdir -p "${acq_data_path}/snb2_window"
mkdir -p "${acq_data_path}/snb3_window"
mkdir -p "${acq_data_path}/snb4_window"

dbt_data_path="${TARGET_PATH}/dbtoaster"
mkdir -p "${dbt_data_path}"
mkdir -p "${dbt_data_path}/snb1_arbitrary"
mkdir -p "${dbt_data_path}/snb2_arbitrary"
mkdir -p "${dbt_data_path}/snb3_arbitrary"
mkdir -p "${dbt_data_path}/snb4_arbitrary"
mkdir -p "${dbt_data_path}/snb1_window"
mkdir -p "${dbt_data_path}/snb2_window"
mkdir -p "${dbt_data_path}/snb3_window"
mkdir -p "${dbt_data_path}/snb4_window"

dbtcpp_data_path="${TARGET_PATH}/dbtoaster_cpp"
mkdir -p "${dbtcpp_data_path}"
mkdir -p "${dbtcpp_data_path}/snb1_arbitrary"
mkdir -p "${dbtcpp_data_path}/snb2_arbitrary"
mkdir -p "${dbtcpp_data_path}/snb3_arbitrary"
mkdir -p "${dbtcpp_data_path}/snb4_arbitrary"
mkdir -p "${dbtcpp_data_path}/snb1_window"
mkdir -p "${dbtcpp_data_path}/snb2_window"
mkdir -p "${dbtcpp_data_path}/snb3_window"
mkdir -p "${dbtcpp_data_path}/snb4_window"

# window
rm -f pg_tmp.sql
touch pg_tmp.sql

echo "COPY (select * from messageW order by m_op_time asc, m_op desc) to '${raw_window_data_path}/message' DELIMITER '|';" >> pg_tmp.sql
echo "COPY (select * from personW order by p_op_time asc, p_op desc) to '${raw_window_data_path}/person' DELIMITER '|';" >> pg_tmp.sql
echo "COPY (select * from knowsW order by k_op_time asc, k_op desc) to '${raw_window_data_path}/knows' DELIMITER '|';" >> pg_tmp.sql
echo "COPY (select * from message_tagW order by mt_op_time asc, mt_op desc) to '${raw_window_data_path}/messagetag' DELIMITER '|';" >> pg_tmp.sql
echo "COPY (select ${tag_timestamp}, t_tagid, t_name, t_url, t_tagclassid from tag) to '${raw_window_data_path}/tag' DELIMITER '|';" >> pg_tmp.sql

${psql_cmd} -p "${PG_PORT}" -U "${PG_USERNAME}" -d "${PG_DATABASE}" -f ./pg_tmp.sql
cp "${raw_window_data_path}/knows" "${raw_window_data_path}/knows1"
cp "${raw_window_data_path}/knows" "${raw_window_data_path}/knows2"

# snb1
scala ./SnbDataConvertor.scala "${raw_window_data_path}" "knows,message,person" "180" "100" "${raw_output_data_path}" "window"
mv ${raw_output_data_path}/dbtoaster_cpp* "${dbtcpp_data_path}/snb1_window/"
mv ${raw_output_data_path}/dbtoaster* "${dbt_data_path}/snb1_window/"
mv ${raw_output_data_path}/enum* "${dbt_data_path}/snb1_window/"
mv ${raw_output_data_path}/data.csv "${acq_data_path}/snb1_window/"

# snb2
scala ./SnbDataConvertor.scala "${raw_window_data_path}" "knows1,knows2,message,messagetag,tag" "180" "100" "${raw_output_data_path}" "window"
mv ${raw_output_data_path}/dbtoaster_cpp* "${dbtcpp_data_path}/snb2_window/"
mv ${raw_output_data_path}/dbtoaster* "${dbt_data_path}/snb2_window/"
mv ${raw_output_data_path}/enum* "${dbt_data_path}/snb2_window/"
mv ${raw_output_data_path}/data.csv "${acq_data_path}/snb2_window/"

# snb3
scala ./SnbDataConvertor.scala "${raw_window_data_path}" "knows1,knows2,message,person" "180" "100" "${raw_output_data_path}" "window"
mv ${raw_output_data_path}/dbtoaster_cpp* "${dbtcpp_data_path}/snb3_window/"
mv ${raw_output_data_path}/dbtoaster* "${dbt_data_path}/snb3_window/"
mv ${raw_output_data_path}/enum* "${dbt_data_path}/snb3_window/"
mv ${raw_output_data_path}/data.csv "${acq_data_path}/snb3_window/"

# snb4
scala ./SnbDataConvertor.scala "${raw_window_data_path}" "knows,message,messagetag,tag" "180" "100" "${raw_output_data_path}" "window"
mv ${raw_output_data_path}/dbtoaster_cpp* "${dbtcpp_data_path}/snb4_window/"
mv ${raw_output_data_path}/dbtoaster* "${dbt_data_path}/snb4_window/"
mv ${raw_output_data_path}/enum* "${dbt_data_path}/snb4_window/"
mv ${raw_output_data_path}/data.csv "${acq_data_path}/snb4_window/"

# arbitrary
rm -f pg_tmp.sql
touch pg_tmp.sql

echo "COPY (select * from messageT order by m_op_time asc, m_op desc) to '${raw_arbitrary_data_path}/message' DELIMITER '|';" >> pg_tmp.sql
echo "COPY (select * from personT order by p_op_time asc, p_op desc) to '${raw_arbitrary_data_path}/person' DELIMITER '|';" >> pg_tmp.sql
echo "COPY (select * from knowsT order by k_op_time asc, k_op desc) to '${raw_arbitrary_data_path}/knows' DELIMITER '|';" >> pg_tmp.sql
echo "COPY (select * from message_tagT order by mt_op_time asc, mt_op desc) to '${raw_arbitrary_data_path}/messagetag' DELIMITER '|';" >> pg_tmp.sql
echo "COPY (select ${tag_timestamp}, t_tagid, t_name, t_url, t_tagclassid from tag) to '${raw_arbitrary_data_path}/tag' DELIMITER '|';" >> pg_tmp.sql

${psql_cmd} -p "${PG_PORT}" -U "${PG_USERNAME}" -d "${PG_DATABASE}" -f ./pg_tmp.sql
cp "${raw_arbitrary_data_path}/knows" "${raw_arbitrary_data_path}/knows1"
cp "${raw_arbitrary_data_path}/knows" "${raw_arbitrary_data_path}/knows2"

# snb1
scala ./SnbDataConvertor.scala "${raw_arbitrary_data_path}" "knows,message,person" "180" "100" "${raw_output_data_path}" "arbitrary"
mv ${raw_output_data_path}/dbtoaster_cpp* "${dbtcpp_data_path}/snb1_arbitrary/"
mv ${raw_output_data_path}/dbtoaster* "${dbt_data_path}/snb1_arbitrary/"
mv ${raw_output_data_path}/enum* "${dbt_data_path}/snb1_arbitrary/"
mv ${raw_output_data_path}/data.csv "${acq_data_path}/snb1_arbitrary/"

# snb2
scala ./SnbDataConvertor.scala "${raw_arbitrary_data_path}" "knows1,knows2,message,messagetag,tag" "180" "100" "${raw_output_data_path}" "arbitrary"
mv ${raw_output_data_path}/dbtoaster_cpp* "${dbtcpp_data_path}/snb2_arbitrary/"
mv ${raw_output_data_path}/dbtoaster* "${dbt_data_path}/snb2_arbitrary/"
mv ${raw_output_data_path}/enum* "${dbt_data_path}/snb2_arbitrary/"
mv ${raw_output_data_path}/data.csv "${acq_data_path}/snb2_arbitrary/"

# snb3
scala ./SnbDataConvertor.scala "${raw_arbitrary_data_path}" "knows1,knows2,message,person" "180" "100" "${raw_output_data_path}" "arbitrary"
mv ${raw_output_data_path}/dbtoaster_cpp* "${dbtcpp_data_path}/snb3_arbitrary/"
mv ${raw_output_data_path}/dbtoaster* "${dbt_data_path}/snb3_arbitrary/"
mv ${raw_output_data_path}/enum* "${dbt_data_path}/snb3_arbitrary/"
mv ${raw_output_data_path}/data.csv "${acq_data_path}/snb3_arbitrary/"

# snb4
scala ./SnbDataConvertor.scala "${raw_arbitrary_data_path}" "knows,message,messagetag,tag" "180" "100" "${raw_output_data_path}" "arbitrary"
mv ${raw_output_data_path}/dbtoaster_cpp* "${dbtcpp_data_path}/snb4_arbitrary/"
mv ${raw_output_data_path}/dbtoaster* "${dbt_data_path}/snb4_arbitrary/"
mv ${raw_output_data_path}/enum* "${dbt_data_path}/snb4_arbitrary/"
mv ${raw_output_data_path}/data.csv "${acq_data_path}/snb4_arbitrary/"