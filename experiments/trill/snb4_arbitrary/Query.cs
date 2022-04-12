using System;
using System.Collections.Generic;
using System.Reactive.Linq;
using Microsoft.StreamProcessing;
using Csv;

namespace Snb4_arbitrary
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

        public static long ExtractTime2(string[] strs) {
            return Convert.ToInt64(strs[1]);
        }

        public static List<string[]> Execute(string path, ulong punctuationTime, int filterCondition, int outputMode) {

            var knowsStream = CsvFileReader<string[], Knows>.GetIntervalStreamable(path + "/trill.knows.arbitrary.csv", punctuationTime,
                line => line.Split("|"),
                StringsToKnows,
                ExtractTime1,
                ExtractTime2).Where(k => k.k_person1id < 100000);

            var messageStream = CsvFileReader<string[], Message>.GetIntervalStreamable(path + "/trill.message.arbitrary.csv", punctuationTime,
                line => line.Split("|"),
                StringsToMessage,
                ExtractTime1,
                ExtractTime2).Where(m => m.m_c_replyof == -1);

            var messageTagStream = CsvFileReader<string[], MessageTag>.GetIntervalStreamable(path + "/trill.messagetag.arbitrary.csv", punctuationTime,
                line => line.Split("|"),
                StringsToMessageTag,
                ExtractTime1,
                ExtractTime2);

            var tagStream = CsvFileReader<string[], Tag>.GetStartStreamable(path + "/trill.tag.arbitrary.csv", punctuationTime,
                line => line.Split("|"),
                StringsToTag,
                ExtractTime1);

            var join0 = knowsStream.Join(messageStream, k => k.k_person2id, m => m.m_creatorid, 
                (k, m) => new {m.m_messageid});

            var join1 = tagStream.Join(messageTagStream, t => t.t_tagid, mt => mt.mt_tagid, 
                (t, mt) => new {t.t_name, t.t_tagid, mt.mt_messageid});

            var result = join0.Join(join1, j0 => j0.m_messageid, j1 => j1.mt_messageid, 
                (j0, j1) => new {j0.m_messageid, j1.t_name, j1.t_tagid})
                .GroupApply(p => p, data => data.Distinct()).Stitch();
            
            var cnt = result.GroupApply(g => new {g.t_name, g.t_tagid}, 
                evs => evs.Count(), (g, c) => new {g.Key.t_name, g.Key.t_tagid, cnt = c});

            var outputCount = 0;
            if (outputMode == 0) {
                cnt.ToStreamEventObservable().ForEachAsync(ev => {
                    // do nothing
                    outputCount += 1;
                    if (outputCount % 1000000 == 0)
                        Console.WriteLine("outputCount = " + outputCount);
                }).Wait();
                return null;
            } else if (outputMode == 1) {
                var list = new List<string[]>();
                cnt.ToStreamEventObservable().Select(ev => new String[]{ ev.ToString()} )
                    .Where(strs => strs != null)
                    .ForEachAsync(strs => list.Add(strs)).Wait();
                return list;
            } else {
                cnt.ToStreamEventObservable().Select(ev => new String[]{ ev.ToString()} )
                    .Where(strs => strs != null)
                    .ForEachAsync(strs => Console.WriteLine(String.Join(",", strs))).Wait();
                return null;
            }
        }
    }
}