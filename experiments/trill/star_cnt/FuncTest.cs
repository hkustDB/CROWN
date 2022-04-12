using Xunit;
using System;
using System.IO;
using System.Linq;
using System.Reactive.Linq;
using System.Collections.Generic;
using System.Configuration;

namespace Star_cnt.Test {
    public class FuncTest {
        [Fact]
        public void TestFunc() {
            string path = ConfigurationManager.AppSettings["star.func.path"];
            var result1 = this.TrivialApproach(path);
            var result2 = this.TrillApproach(path);

            Assert.Equal(result1.Keys.Count, result2.Keys.Count);
            foreach (KeyValuePair<int, long> entry in result1) {
                Assert.Equal(entry.Value, result2[entry.Key]);
            }
        }

        private Dictionary<int, long> TrivialApproach(string path) {
            Dictionary<int, LinkedList<int>> edges = new Dictionary<int, LinkedList<int>>();
            foreach (string line in File.ReadLines(path + "/data.csv")) {
                string[] fields = line.Split(",");
                if (int.Parse(fields[1]) == 0) {
                    // insert
                    int src = int.Parse(fields[2]);
                    int dst = int.Parse(fields[3]);
                    if (!edges.ContainsKey(src))
                        edges.Add(src, new LinkedList<int>());
                    edges[src].AddLast(dst);
                } else {
                    // delete
                    int src = int.Parse(fields[2]);
                    int dst = int.Parse(fields[3]);
                    edges[src].Remove(dst);
                }
            }

            Dictionary<int, long> dict = edges.Keys.Select(src => {
                var dsts = edges[src];
                long size = dsts.Count();
                return new {src, cnt = size * size * size * size};
            }).ToDictionary(kv => kv.src, kv => kv.cnt);
   
            return dict;
        }

        private Dictionary<int, long> TrillApproach(string path) {
            Dictionary<int, long> dict = new Dictionary<int, long>();
            List<string[]> result = Query.Execute(path, 1, -1, 1);
            result.ForEach(strs => {
                Assert.True(strs[0].Equals("Start") || strs[0].Equals("End"));
                bool isStart = strs[0].Equals("Start");
                int src = int.Parse(strs[3]);
                long cnt = long.Parse(strs[4]);
                if (isStart)
                    dict[src] = cnt;
                else 
                    dict[src] = 0;
            });

            return dict;
        }
    }
}