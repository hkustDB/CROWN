using System;
using System.Collections.Generic;
using System.Reactive.Linq;
using Microsoft.StreamProcessing;
using Csv;

namespace Snb2_window
{
    class Query {
        public static Knows StringsToKnows(string[] strs) {
            bool k_explicitlyDeleted = strs[2].Equals("t");
            long k_person1id = Convert.ToInt64(strs[3]);
            long k_person2id = Convert.ToInt64(strs[4]);
            return new Knows(k_explicitlyDeleted, k_person1id, k_person2id);
        }

        public static Message StringsToMessage(string[] strs) {
            bool m_explicitlyDeleted = strs[2].Equals("t");
            long m_messageid = Convert.ToInt64(strs[3]);
            string m_ps_imagefile = strs[4];
            string m_locationip  = strs[5];
            string m_browserused  = strs[6];
            string m_ps_language  = strs[7];
            string m_content  = strs[8];
            long m_length = Convert.ToInt64(strs[9]);
            long m_creatorid = Convert.ToInt64(strs[10]);
            long m_locationid = Convert.ToInt64(strs[11]);
            long m_ps_forumid = -1;
            if (!strs[12].Equals("") && !strs[12].Equals("\\N")) 
                m_ps_forumid = Convert.ToInt64(strs[12]);
            long m_c_parentpostid = -1;
            if (!strs[13].Equals("") && !strs[13].Equals("\\N")) 
                m_c_parentpostid = Convert.ToInt64(strs[13]);
            long m_c_replyof = -1;
            if (!strs[14].Equals("") && !strs[14].Equals("\\N")) 
                m_c_replyof = Convert.ToInt64(strs[14]);
            return new Message(m_explicitlyDeleted, m_messageid, m_ps_imagefile, m_locationip, m_browserused, m_ps_language,
                m_content, m_length, m_creatorid, m_locationid, m_ps_forumid, m_c_parentpostid, m_c_replyof);
        }

        public static MessageTag StringsToMessageTag(string[] strs) {
            long mt_messageid = Convert.ToInt64(strs[2]);
            long mt_tagid = Convert.ToInt64(strs[3]);
            return new MessageTag(mt_messageid, mt_tagid);
        }

        public static Tag StringsToTag(string[] strs) {
            long t_tagid = Convert.ToInt64(strs[1]);
            string t_name = strs[2];
            string t_url = strs[3];
            long t_tagclassid = Convert.ToInt64(strs[4]);
            return new Tag(t_tagid, t_name, t_url, t_tagclassid);
        }

        public static long ExtractTime1(string[] strs) {
            return Convert.ToInt64(strs[0]);
        }

        public static List<string[]> Execute(string path, ulong punctuationTime, int filterCondition, int outputMode) {

            var knows1Stream = CsvFileReader<string[], Knows>.GetStartStreamable(path + "/trill.knows.window.csv", punctuationTime,
                line => line.Split("|"),
                StringsToKnows,
                ExtractTime1).Where(k => k.k_person1id < 100000).AlterEventLifetime(start => start, 180 * 24 * 3600);

            var knows2Stream = CsvFileReader<string[], Knows>.GetStartStreamable(path + "/trill.knows.window.csv", punctuationTime,
                line => line.Split("|"),
                StringsToKnows,
                ExtractTime1).AlterEventLifetime(start => start, 180 * 24 * 3600);

            var messageStream = CsvFileReader<string[], Message>.GetStartStreamable(path + "/trill.message.window.csv", punctuationTime,
                line => line.Split("|"),
                StringsToMessage,
                ExtractTime1).Where(m => m.m_c_replyof == -1).AlterEventLifetime(start => start, 180 * 24 * 3600);

            var messageTagStream = CsvFileReader<string[], MessageTag>.GetStartStreamable(path + "/trill.messagetag.window.csv", punctuationTime,
                line => line.Split("|"),
                StringsToMessageTag,
                ExtractTime1).AlterEventLifetime(start => start, 180 * 24 * 3600);

            var tagStream = CsvFileReader<string[], Tag>.GetStartStreamable(path + "/trill.tag.window.csv", punctuationTime,
                line => line.Split("|"),
                StringsToTag,
                ExtractTime1);

            var tagJoinMessageTag = tagStream.Join(messageTagStream, tag => tag.t_tagid, messageTag => messageTag.mt_tagid, 
                (t, mt) => new {t.t_tagid, mt.mt_messageid});

            var tagJoinMessageTagJoinMessage = tagJoinMessageTag.Join(messageStream, tjmt => tjmt.mt_messageid, m => m.m_messageid, 
                (tjmt, m) => new {m.m_creatorid, m.m_messageid, tjmt.t_tagid});

            var tjmtjm = tagJoinMessageTagJoinMessage.Join(knows2Stream, l => l.m_creatorid, k2 => k2.k_person2id, 
                (left, k2) => new {k2.k_person1id, k2.k_person2id, left.t_tagid, left.m_messageid});
            
            var result = tjmtjm.Join(knows1Stream, left => left.k_person1id, k1 => k1.k_person2id, 
                (left, k1) => new {f0 = k1.k_person1id, f1 = k1.k_person2id, f2 = left.k_person2id, f3 = left.t_tagid, f4 = left.m_messageid});

            var outputCount = 0;
            if (outputMode == 0) {
                result.ToStreamEventObservable().ForEachAsync(ev => {
                    // do nothing
                    outputCount += 1;
                    if (outputCount % 1000000 == 0)
                        Console.WriteLine("outputCount = " + outputCount);
                }).Wait();
                return null;
            } else if (outputMode == 1) {
                var list = new List<string[]>();
                result.ToStreamEventObservable().Select(ev => new String[]{ ev.ToString()} )
                    .Where(strs => strs != null)
                    .ForEachAsync(strs => list.Add(strs)).Wait();
                return list;
            } else {
                result.ToStreamEventObservable().Select(ev => new String[]{ ev.ToString()} )
                    .Where(strs => strs != null)
                    .ForEachAsync(strs => Console.WriteLine(String.Join(",", strs))).Wait();
                return null;
            }
        }
    }
}