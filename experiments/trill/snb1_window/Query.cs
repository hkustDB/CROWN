using System;
using System.Collections.Generic;
using System.Reactive.Linq;
using Microsoft.StreamProcessing;
using Csv;

namespace Snb1_window
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

        public static List<string[]> Execute(string path, ulong punctuationTime, int windowSize, int filterCondition, int outputMode) {

            var knowsStream = CsvFileReader<string[], Knows>.GetStartStreamable(path + "/trill.knows.window.csv", punctuationTime,
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


            var personJoinKnows = knowsStream.Join(personStream, knows => knows.k_person2id, person => person.p_personid, 
                (know, person) => new {f0 = person.p_personid, f1=person.p_firstname, f2 = person.p_lastname, f3 = know.k_person1id});
            
            var result = personJoinKnows.Join(messageStream, pjk => pjk.f0, m => m.m_creatorid, 
                (pjk, m) => new { p_personid = pjk.f0, p_firstname = pjk.f1, p_lastname = pjk.f2, m_messageid = m.m_messageid, k_personid1 = pjk.f3});

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