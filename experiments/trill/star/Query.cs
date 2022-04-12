using System;
using System.Collections.Generic;
using System.Reactive.Linq;
using Microsoft.StreamProcessing;
using Csv;

namespace Star
{
    class Query {
        public static string[] StreamEventToStrings(StreamEvent<Path> ev) {
            if (ev.IsData) {
                return new string[] { 
                    ev.Kind.ToString(),
                    ev.StartTime.ToString(), 
                    ev.EndTime.ToString(),
                    ev.Payload.src.ToString(), 
                    ev.Payload.dst1.ToString(), 
                    ev.Payload.dst2.ToString(), 
                    ev.Payload.dst3.ToString(),
                    ev.Payload.dst4.ToString() 
                };
            } else if (ev.IsPunctuation) {
                return null;
            } else {
                throw new Exception("Invalid event: " + ev.ToString());
            }
        }

        public static List<string[]> Execute(string path, ulong punctuationTime, int filterCondition, int outputMode) {
            var stream1 = CsvFileReader<Row, Edge>.GetStartOrEndStreamable(path + "/data.csv", punctuationTime,
                line => { 
                    var strs = line.Split(",");
                    return new Row(int.Parse(strs[0]), int.Parse(strs[1]), int.Parse(strs[2]), int.Parse(strs[3]));
                },
                row => new Edge(row.src, row.dst),
                row => row.time1,
                row => row.time2);

            var stream2 = CsvFileReader<Row, Edge>.GetStartOrEndStreamable(path + "/data.csv", punctuationTime,
                line => { 
                    var strs = line.Split(",");
                    return new Row(int.Parse(strs[0]), int.Parse(strs[1]), int.Parse(strs[2]), int.Parse(strs[3]));
                },
                row => new Edge(row.src, row.dst),
                row => row.time1,
                row => row.time2);

            var stream3 = CsvFileReader<Row, Edge>.GetStartOrEndStreamable(path + "/data.csv", punctuationTime,
                line => { 
                    var strs = line.Split(",");
                    return new Row(int.Parse(strs[0]), int.Parse(strs[1]), int.Parse(strs[2]), int.Parse(strs[3]));
                },
                row => new Edge(row.src, row.dst),
                row => row.time1,
                row => row.time2);

            var stream4 = CsvFileReader<Row, Edge>.GetStartOrEndStreamable(path + "/data.csv", punctuationTime,
                line => { 
                    var strs = line.Split(",");
                    return new Row(int.Parse(strs[0]), int.Parse(strs[1]), int.Parse(strs[2]), int.Parse(strs[3]));
                },
                row => new Edge(row.src, row.dst),
                row => row.time1,
                row => row.time2).Where(edge => edge.dst > filterCondition);

            var joined1 = stream1.Join(stream2, l => l.src, r => r.src, (l, r) => new {src = l.src, dst1 = l.dst, dst2 = r.dst});
            var joined2 = stream3.Join(stream4, l => l.src, r => r.src, (l, r) => new {src = l.src, dst1 = l.dst, dst2 = r.dst});
            
            var star = joined1.Join(joined2, l => l.src, r => r.src, (l, r) => new Path(l.src, l.dst1, l.dst2, r.dst1, r.dst2));
            
            var outputCount = 0;
            if (outputMode == 0) {
                star.ToStreamEventObservable().ForEachAsync(ev => {
                    // do nothing
                    outputCount += 1;
                    if (outputCount % 1000000 == 0)
                        Console.WriteLine("outputCount = " + outputCount);
                }).Wait();
                return null;
            } else if (outputMode == 1) {
                var list = new List<string[]>();
                star.ToStreamEventObservable().Select(ev => StreamEventToStrings(ev))
                    .Where(strs => strs != null)
                    .ForEachAsync(strs => list.Add(strs)).Wait();
                return list;
            } else {
                star.ToStreamEventObservable().Select(ev => StreamEventToStrings(ev))
                    .Where(strs => strs != null)
                    .ForEachAsync(strs => Console.WriteLine(String.Join(",", strs))).Wait();
                return null;
            }
        }
    }
}