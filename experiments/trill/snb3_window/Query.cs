using System;
using System.Collections.Generic;
using System.Reactive.Linq;
using Microsoft.StreamProcessing;
using Csv;

namespace Snb3_window
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

        public static Person StringsToPerson(string[] strs) {
            bool p_explicitlyDeleted = strs[2].Equals("t");
            long p_personid = Convert.ToInt64(strs[3]);
            string p_firstname = strs[4];
            string p_lastname = strs[5];
            string p_gender = strs[6];
            string p_birthday = strs[7];
            string p_locationip = strs[8];
            string p_browserused = strs[9];
            long p_placeid = Convert.ToInt64(strs[10]);
            string p_language = strs[11];
            string p_email = strs[12];
            return new Person(p_explicitlyDeleted, p_personid, p_firstname, p_lastname, p_gender, p_birthday,
                p_locationip, p_browserused, p_placeid, p_language, p_email);
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
                ExtractTime1).AlterEventLifetime(start => start, 180 * 24 * 3600);

            var personStream = CsvFileReader<string[], Person>.GetStartStreamable(path + "/trill.person.window.csv", punctuationTime,
                line => line.Split("|"),
                StringsToPerson,
                ExtractTime1).AlterEventLifetime(start => start, 180 * 24 * 3600);

            var k1JoinK2 = knows1Stream.Join(knows2Stream, k1 => k1.k_person2id, k2 => k2.k_person1id, 
                (k1, k2) => new {k1_1 = k1.k_person1id, k1_2 = k1.k_person2id, k2_2 = k2.k_person2id})
                .Where(j => j.k1_1 != j.k2_2);

            var k1JoinK2JoinPerson = k1JoinK2.Join(personStream, left => left.k2_2, p => p.p_personid, 
                (left, p) => new {left.k1_1, left.k1_2, p.p_personid, p.p_firstname, p.p_lastname});

            var result = k1JoinK2JoinPerson.Join(messageStream, left => left.p_personid, m => m.m_creatorid, 
                (left, m) => new { left.p_personid, left.p_firstname, left.p_lastname, m.m_messageid, left.k1_1, left.k1_2});

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