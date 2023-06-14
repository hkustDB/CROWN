using System;
using System.Collections.Generic;
using System.Reactive.Linq;
using Microsoft.StreamProcessing;
using Csv;

namespace Length4_filter
{
    class Query {
        public static string[] StreamEventToStrings(StreamEvent<Path> ev) {
            if (ev.IsData) {
                return new string[] { 
                    ev.Kind.ToString(),
                    ev.StartTime.ToString(), 
                    ev.EndTime.ToString(),
                    ev.Payload.src.ToString(), 
                    ev.Payload.via1.ToString(), 
                    ev.Payload.via2.ToString(), 
                    ev.Payload.via3.ToString(), 
                    ev.Payload.dst.ToString(), 
                };
            } else if (ev.IsPunctuation) {
                return null;
            } else {
                throw new Exception("Invalid event: " + ev.ToString());
            }
        }

        public static List<string[]> Execute(string path, ulong punctuationTime, int windowSize, int filterCondition, int outputMode) {
            Console.WriteLine("Length4_filter with filter value = " + filterCondition);
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
                row => row.time1).Where(edge => edge.dst > filterCondition).AlterEventLifetime(start => start, windowSize);

            var stream1JoinStream2 = stream1.Join(stream2, l => l.dst, r => r.src, (l, r) => new {src = l.src, via = l.dst, dst = r.dst});
            var stream4JoinStream3 = stream4.Join(stream3, s4 => s4.src, s3 => s3.dst, (s4, s3) => new {src = s3.src, via = s3.dst, dst = s4.dst});
            var length4 = stream4JoinStream3.Join(stream1JoinStream2, s43 => s43.src, s12 => s12.dst, (s43, s12) => new Path(s12.src, s12.via, s12.dst, s43.via, s43.dst));

            var outputCount = 0;
            if (outputMode == 0) {
                length4.ToStreamEventObservable().ForEachAsync(ev => {
                    // do nothing
                    outputCount += 1;
                    if (outputCount % 1000000 == 0)
                        Console.WriteLine("outputCount = " + outputCount);
                }).Wait();
                return null;
            } else if (outputMode == 1) {
                var list = new List<string[]>();
                length4.ToStreamEventObservable().Select(ev => StreamEventToStrings(ev))
                    .Where(strs => strs != null)
                    .ForEachAsync(strs => list.Add(strs)).Wait();
                return list;
            } else {
                length4.ToStreamEventObservable().Select(ev => StreamEventToStrings(ev))
                    .Where(strs => strs != null)
                    .ForEachAsync(strs => Console.WriteLine(String.Join(",", strs))).Wait();
                return null;
            }
        }
    }
}