using System;
using System.Collections.Generic;
using System.Reactive.Linq;
using Microsoft.StreamProcessing;
using Csv;

namespace TwoComb
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
                    ev.Payload.dst.ToString(),
                };
            } else if (ev.IsPunctuation) {
                return null;
            } else {
                throw new Exception("Invalid event: " + ev.ToString());
            }
        }

        public static List<string[]> Execute(string path, ulong punctuationTime, int windowSize, int filterCondition, int outputMode) {
            var stream1 = CsvFileReader<Row, Edge>.GetStartStreamable(path + "/trill.graph.csv", punctuationTime,
                line => {
                    var strs = line.Split(",");
                    return new Row(int.Parse(strs[0]), int.Parse(strs[1]), int.Parse(strs[2]));
                },
                row => new Edge(row.src, row.dst),
                row => row.time1).AlterEventLifetime(start => start, 180 * 24 * 3600);

            var stream2 = CsvFileReader<Row, Edge>.GetStartStreamable(path + "/trill.graph.csv", punctuationTime,
                line => {
                    var strs = line.Split(",");
                    return new Row(int.Parse(strs[0]), int.Parse(strs[1]), int.Parse(strs[2]));
                },
                row => new Edge(row.src, row.dst),
                row => row.time1).AlterEventLifetime(start => start, 180 * 24 * 3600);

            var stream3 = CsvFileReader<Row, Edge>.GetStartStreamable(path + "/trill.graph.csv", punctuationTime,
                line => {
                    var strs = line.Split(",");
                    return new Row(int.Parse(strs[0]), int.Parse(strs[1]), int.Parse(strs[2]));
                },
                row => new Edge(row.src, row.dst),
                row => row.time1).AlterEventLifetime(start => start, 180 * 24 * 3600);

            var streamV1 = CsvFileReader<Row, Vertex>.GetStartStreamable(path + "/trill.v1.csv", punctuationTime,
                line => {
                var strs = line.Split(",");
                return new Row(int.Parse(strs[0]), int.Parse(strs[1]), 0);
            },
            row => new Vertex(row.src),
            row => row.time1).AlterEventLifetime(start => start, 180 * 24 * 3600);

            var streamV2 = CsvFileReader<Row, Vertex>.GetStartStreamable(path + "/trill.v2.csv", punctuationTime,
                line => {
                var strs = line.Split(",");
                return new Row(int.Parse(strs[0]), 0, int.Parse(strs[1]));
            },
            row => new Vertex(row.dst),
            row => row.time1).AlterEventLifetime(start => start, 180 * 24 * 3600);

            stream1 = stream1.Join(streamV1, l => l.src, r => r.value, (l, r) => l);
            stream3 = stream3.Join(streamV2, l => l.dst, r => r.value, (l, r) => l);

            var length2 = stream1.Join(stream2, l => l.dst, r => r.src, (l, r) => new {src = l.src, via = l.dst, dst = r.dst});
            var length3 = length2.Join(stream3, l => l.dst, r => r.src, (l, r) => new Path(l.src, l.via, l.dst, r.dst));

            var outputCount = 0;
            if (outputMode == 0) {
                length3.ToStreamEventObservable().ForEachAsync(ev => {
                    // do nothing
                    outputCount += 1;
                    if (outputCount % 1000000 == 0)
                        Console.WriteLine("outputCount = " + outputCount);
                }).Wait();
                return null;
            } else if (outputMode == 1) {
                var list = new List<string[]>();
                length3.ToStreamEventObservable().Select(ev => StreamEventToStrings(ev))
                    .Where(strs => strs != null)
                    .ForEachAsync(strs => list.Add(strs)).Wait();
                return list;
            } else {
                length3.ToStreamEventObservable().Select(ev => StreamEventToStrings(ev))
                    .Where(strs => strs != null)
                    .ForEachAsync(strs => Console.WriteLine(String.Join(",", strs))).Wait();
                return null;
            }
        }
    }
}