using System;
using System.Collections.Generic;
using System.Reactive.Linq;
using Microsoft.StreamProcessing;
using Csv;

namespace Length3_project
{
    class Query {
        static int inputSize = 500000;
        static int windowSize = Convert.ToInt32(0.2 * inputSize); 
        public static string[] StreamEventToStrings(StreamEvent<Path> ev) {
            if (ev.IsData) {
                return new string[] { 
                    ev.Kind.ToString(),
                    ev.StartTime.ToString(), 
                    ev.EndTime.ToString(),
                    ev.Payload.via1.ToString(), 
                    ev.Payload.via2.ToString()
                };
            } else if (ev.IsPunctuation) {
                return null;
            } else {
                throw new Exception("Invalid event: " + ev.ToString());
            }
        }

        public static List<string[]> Execute(string path, ulong punctuationTime, int filterCondition, int outputMode) {
            Console.WriteLine("Length3_filter with filter value = " + filterCondition);
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
                row => row.time1).Where(ev => ev.dst > filterCondition).AlterEventLifetime(start => start, windowSize);

            var length2 = stream1.Join(stream2, l => l.dst, r => r.src, (l, r) => new {src = l.src, via = l.dst, dst = r.dst});
            var length3Projected = length2.Join(stream3, l => l.dst, r => r.src, (l, r) => new Path(l.via, l.dst));
            
            var distinct = length3Projected.GroupApply(p => p, data => data.Distinct(), (group, value) => value).Stitch();
            
            var outputCount = 0;
            if (outputMode == 0) {
                distinct.ToStreamEventObservable().ForEachAsync(ev => {
                    // do nothing
                    outputCount += 1;
                    if (outputCount % 100000 == 0)
                        Console.WriteLine("outputCount = " + outputCount);
                }).Wait();
                return null;
            } else if (outputMode == 1) {
                var list = new List<string[]>();
                distinct.ToStreamEventObservable().Select(ev => StreamEventToStrings(ev))
                    .Where(strs => strs != null)
                    .ForEachAsync(strs => list.Add(strs)).Wait();
                return list;
            } else {
                distinct.ToStreamEventObservable().Select(ev => StreamEventToStrings(ev))
                    .Where(strs => strs != null)
                    .ForEachAsync(strs => Console.WriteLine(String.Join(",", strs))).Wait();
                return null;
            }
        }
    }
}