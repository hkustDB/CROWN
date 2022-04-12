using Xunit;
using System;
using System.IO;
using System.Linq;
using System.Reactive.Linq;
using System.Collections.Generic;
using System.Configuration;

namespace Length3_project.Test {
    public class FuncTest {
        [Fact]
        public void TestFunc() {
            string path = ConfigurationManager.AppSettings["length3_project.func.path"];
            var result1 = this.TrivialApproach(path);
            var result2 = this.TrillApproach(path);

            Assert.Equal(result1.Keys.Count, result2.Keys.Count);
            foreach (KeyValuePair<Path, int> entry in result1) {
                Assert.Equal(entry.Value, result2[entry.Key]);
            }
        }

        private Dictionary<Path, int> TrivialApproach(string path) {
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

            LinkedList<int> empty = new LinkedList<int>();
            IEnumerable<Path> result = edges.Keys.SelectMany(
                src => edges[src].SelectMany(
                    via1 => edges.GetValueOrDefault(via1, empty).SelectMany(
                        via2 => edges.GetValueOrDefault(via2, empty).Select(
                            dst => new Path(via1, via2)))));
    
            return result.Distinct().ToDictionary(p => p, p => 1);
        }

        private Dictionary<Path, int> TrillApproach(string path) {
            Dictionary<Path, int> count = new Dictionary<Path, int>();
            List<string[]> result = Query.Execute(path, 1, -1, 1);
            result.ForEach(strs => {
                Assert.True(strs[0].Equals("Start") || strs[0].Equals("End"));
                bool isStart = strs[0].Equals("Start");
                Path p = new Path(int.Parse(strs[3]), int.Parse(strs[4]));
                if (isStart) {
                    count[p] = count.GetValueOrDefault(p, 0) + 1;
                } else {
                    count[p] = count[p] - 1;
                }
            });

            return count.Where(kv => kv.Value != 0).ToDictionary(kv => kv.Key, kv => kv.Value);
        }
    }
}