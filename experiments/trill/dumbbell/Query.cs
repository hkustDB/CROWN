using System;
using System.Collections.Generic;
using System.Reactive.Linq;
using Microsoft.StreamProcessing;
using Csv;

namespace Dumbbell
{
    class Query {
        public static string[] StreamEventToStrings(StreamEvent<Result> ev) {
            if (ev.IsData) {
                return new string[] { 
                    ev.Kind.ToString(),
                    ev.StartTime.ToString(), 
                    ev.EndTime.ToString(),
                    ev.Payload.a.ToString(), 
                    ev.Payload.b.ToString()
                };
            } else if (ev.IsPunctuation) {
                return null;
            } else {
                throw new Exception("Invalid event: " + ev.ToString());
            }
        }

        public static List<string[]> Execute(string path, ulong punctuationTime, int windowSize, int filterCondition, int outputMode) {
            var streamGraph = CsvFileReader<Row, Edge>.GetStartStreamable(path + "/data.csv", punctuationTime,
                line => { 
                    var strs = line.Split(",");
                    return new Row(int.Parse(strs[0]), int.Parse(strs[1]), int.Parse(strs[2]));
                },
                row => new Edge(row.src, row.dst),
                row => row.time1).AlterEventLifetime(start => start, windowSize);

            var streamAngle = streamGraph.Join(streamGraph, l => l.dst, r => r.src, (l,r) => new {a = l.src, b = l.dst, c = r.dst, ca = new {r.dst, l.src}});
            var streamTriangle = streamAngle
                .Join(streamGraph, (l,r) => new {a = l.a, b = l.b, c = l.c, src = r.src, dst = r.dst})
                .Where(t => t.a == t.dst && t.c == t.src)
                .Select(t => new {a = t.a, b = t.b, c = t.c});

            var joinedLeft = streamTriangle.Join(streamGraph, l => l.c, r => r.src, (l, r) => new {a = l.a, b = l.b, c = l.c, dst = r.dst});
            var joinedRight = joinedLeft.Join(streamTriangle, l => l.dst, r => r.a, (l, r) => new Result(l.c, r.a));
            
            var distinct = joinedRight.GroupApply(p => p, data => data.Distinct(), (group, value) => value).Stitch();

            var outputCount = 0;
            if (outputMode == 0) {
                distinct.ToStreamEventObservable().ForEachAsync(ev => {
                    // do nothing
                    if (ev.IsData)
                        outputCount += 1;
                    if (outputCount % 1000 == 0)
                        Console.WriteLine(ev.ToString());
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