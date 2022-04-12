using System;
using System.Collections.Generic;
using System.Reactive.Linq;
using Microsoft.StreamProcessing;
using Csv;

namespace Star_cnt
{
    class Query {
        static int inputSize = 500000;
        static int windowSize = Convert.ToInt32(0.2 * inputSize); 
        public static string[] StreamEventToStrings(StreamEvent<Result> ev) {
            if (ev.IsData) {
                return new string[] { 
                    ev.Kind.ToString(),
                    ev.StartTime.ToString(), 
                    ev.EndTime.ToString(),
                    ev.Payload.src.ToString(), 
                    ev.Payload.cnt.ToString()
                };
            } else if (ev.IsPunctuation) {
                return null;
            } else {
                throw new Exception("Invalid event: " + ev.ToString());
            }
        }

        public static List<string[]> Execute(string path, ulong punctuationTime, int filterCondition, int outputMode) {
            var stream1 = CsvFileReader<Row, Edge>.GetStartStreamable(path + "/data.csv", punctuationTime,
                line => { 
                    var strs = line.Split(",");
                    return new Row(int.Parse(strs[0]), int.Parse(strs[1]), int.Parse(strs[2]));
                },
                row => new Edge(row.src, row.dst),
                row => row.time1).AlterEventLifetime(start => start, windowSize);

            var stream2 = CsvFileReader<Row, Edge>.GetStartStreamable(path + "/data.csv", punctuationTime,
                line => { 
                    var strs = line.Split(",");
                    return new Row(int.Parse(strs[0]), int.Parse(strs[1]), int.Parse(strs[2]));
                },
                row => new Edge(row.src, row.dst),
                row => row.time1).AlterEventLifetime(start => start, windowSize);

            var stream3 = CsvFileReader<Row, Edge>.GetStartStreamable(path + "/data.csv", punctuationTime,
                line => { 
                    var strs = line.Split(",");
                    return new Row(int.Parse(strs[0]), int.Parse(strs[1]), int.Parse(strs[2]));
                },
                row => new Edge(row.src, row.dst),
                row => row.time1).AlterEventLifetime(start => start, windowSize);

            var stream4 = CsvFileReader<Row, Edge>.GetStartStreamable(path + "/data.csv", punctuationTime,
                line => { 
                    var strs = line.Split(",");
                    return new Row(int.Parse(strs[0]), int.Parse(strs[1]), int.Parse(strs[2]));
                },
                row => new Edge(row.src, row.dst),
                row => row.time1).AlterEventLifetime(start => start, windowSize);

            var joined1 = stream1.Join(stream2, l => l.src, r => r.src, (l, r) => new {src = l.src, dst1 = l.dst, dst2 = r.dst});
            var joined2 = stream3.Join(stream4, l => l.src, r => r.src, (l, r) => new {src = l.src, dst1 = l.dst, dst2 = r.dst});
            
            var star = joined1.Join(joined2, l => l.src, r => r.src, (l, r) => new {l.src});
            
            var cnt = star.GroupApply(p => p.src, data => data.Count(), (g, c) => new Result(g.Key, c));

            var outputCount = 0;
            if (outputMode == 0) {
                cnt.ToStreamEventObservable().ForEachAsync(ev => {
                    // do nothing
                    outputCount += 1;
                    if (outputCount % 100000 == 0)
                        Console.WriteLine("outputCount = " + outputCount);
                }).Wait();
                return null;
            } else if (outputMode == 1) {
                var list = new List<string[]>();
                cnt.ToStreamEventObservable().Select(ev => StreamEventToStrings(ev))
                    .Where(strs => strs != null)
                    .ForEachAsync(strs => list.Add(strs)).Wait();
                return list;
            } else {
                cnt.ToStreamEventObservable().Select(ev => StreamEventToStrings(ev))
                    .Where(strs => strs != null)
                    .ForEachAsync(strs => Console.WriteLine(String.Join(",", strs))).Wait();
                return null;
            }
        }
    }
}