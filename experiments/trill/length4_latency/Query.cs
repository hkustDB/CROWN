using System;
using System.Collections;
using System.Collections.Generic;
using System.Reactive.Linq;
using Microsoft.StreamProcessing;
using Csv;

namespace Length4_latency
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
            var insert1 = new List<Tuple<Edge, long>>(510000);
            var insert2 = new List<Tuple<Edge, long>>(510000);
            var insert3 = new List<Tuple<Edge, long>>(510000);
            var insert4 = new List<Tuple<Edge, long>>(510000);
            var delete1 = new List<Tuple<Edge, long>>(510000);
            var delete2 = new List<Tuple<Edge, long>>(510000);
            var delete3 = new List<Tuple<Edge, long>>(510000);
            var delete4 = new List<Tuple<Edge, long>>(510000);

            var outputs = new List<LinkedList<Tuple<bool, Path, long>>>();
            for (int i = 0; i < 30; i++) {
                outputs.Add(new LinkedList<Tuple<bool, Path, long>>());
            }

            var stream1 = CsvFileReader<Row, Edge>.GetLatencyStreamable(path + "/data.csv", punctuationTime,
                line => { 
                    var strs = line.Split(",");
                    return new Row(int.Parse(strs[0]), int.Parse(strs[1]), int.Parse(strs[2]), int.Parse(strs[3]));
                },
                row => new Edge(row.src, row.dst),
                row => row.time1,
                row => row.time2, insert1, delete1);

            var stream2 = CsvFileReader<Row, Edge>.GetLatencyStreamable(path + "/data.csv", punctuationTime,
                line => { 
                    var strs = line.Split(",");
                    return new Row(int.Parse(strs[0]), int.Parse(strs[1]), int.Parse(strs[2]), int.Parse(strs[3]));
                },
                row => new Edge(row.src, row.dst),
                row => row.time1,
                row => row.time2, insert2, delete2);

            var stream3 = CsvFileReader<Row, Edge>.GetLatencyStreamable(path + "/data.csv", punctuationTime,
                line => { 
                    var strs = line.Split(",");
                    return new Row(int.Parse(strs[0]), int.Parse(strs[1]), int.Parse(strs[2]), int.Parse(strs[3]));
                },
                row => new Edge(row.src, row.dst),
                row => row.time1,
                row => row.time2, insert3, delete3);

            var stream4 = CsvFileReader<Row, Edge>.GetLatencyStreamable(path + "/data.csv", punctuationTime,
                line => { 
                    var strs = line.Split(",");
                    return new Row(int.Parse(strs[0]), int.Parse(strs[1]), int.Parse(strs[2]), int.Parse(strs[3]));
                },
                row => new Edge(row.src, row.dst),
                row => row.time1,
                row => row.time2, insert4, delete4).Where(edge => edge.dst > filterCondition);

            var stream1JoinStream2 = stream1.Join(stream2, l => l.dst, r => r.src, (l, r) => new {src = l.src, via = l.dst, dst = r.dst});
            var stream4JoinStream3 = stream4.Join(stream3, s4 => s4.src, s3 => s3.dst, (s4, s3) => new {src = s3.src, via = s3.dst, dst = s4.dst});
            var length4 = stream4JoinStream3.Join(stream1JoinStream2, s43 => s43.src, s12 => s12.dst, (s43, s12) => new Path(s12.src, s12.via, s12.dst, s43.via, s43.dst));

            var cnt = 0;
            var index = 0;
            if (outputMode == 0) {
                length4.ToStreamEventObservable().ForEachAsync(ev => {
                    if (ev.IsData) {
                        cnt += 1;
                        index = (cnt / 2000000);
                        if (ev.IsStart)
                            outputs[index].AddLast(new Tuple<bool, Path, long>(true, ev.Payload, DateTimeOffset.Now.ToUnixTimeMilliseconds()));
                        else if (ev.IsEnd)
                            outputs[index].AddLast(new Tuple<bool, Path, long>(false, ev.Payload, DateTimeOffset.Now.ToUnixTimeMilliseconds()));
                    }
                }).Wait();

                Console.WriteLine("processing end.");
                
                var insertMap1 = build(insert1);
                var insertMap2 = build(insert2);
                var insertMap3 = build(insert3);
                var insertMap4 = build(insert4);

                var deleteMap1 = build(delete1);
                var deleteMap2 = build(delete2);
                var deleteMap3 = build(delete3);
                var deleteMap4 = build(delete4);

                for (int i = 0; i < 30; i++) {
                    long totalLatency = 0L;
                    long outputCnt = 0;
                    foreach (var item in outputs[i]) {
                        var isInsert = item.Item1;
                        var p = item.Item2;
                        var ts = item.Item3;

                        if (isInsert) {
                            var ts1 = insertMap1[new Edge(p.src, p.via1)];
                            var ts2 = insertMap2[new Edge(p.via1, p.via2)];
                            var ts3 = insertMap3[new Edge(p.via2, p.via3)];
                            var ts4 = insertMap4[new Edge(p.via3, p.dst)];

                            var latestTs = Math.Max(ts1, Math.Max(ts2, Math.Max(ts3, ts4)));

                            if (ts > latestTs)
                                totalLatency += (ts - latestTs);

                            outputCnt +=1;
                        } else {
                            var ts1 = deleteMap1[new Edge(p.src, p.via1)];
                            var ts2 = deleteMap2[new Edge(p.via1, p.via2)];
                            var ts3 = deleteMap3[new Edge(p.via2, p.via3)];
                            var ts4 = deleteMap4[new Edge(p.via3, p.dst)];

                            var latestTs = Math.Max(ts1, Math.Max(ts2, Math.Max(ts3, ts4)));

                            if (ts > latestTs)
                                totalLatency += (ts - latestTs);
                            outputCnt +=1;
                        }                        
                    }

                    Console.WriteLine("i = " + i);
                    Console.WriteLine("cnt = " + outputCnt);
                    Console.WriteLine("total = " + totalLatency);
                    if (outputCnt != 0)
                        Console.WriteLine("avg latancy = " + (totalLatency / outputCnt));
                    Console.WriteLine("");
                }
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

        public static Dictionary<Edge, long> build(List<Tuple<Edge, long>> list) {
            var result = new Dictionary<Edge, long>();
            foreach (var item in list)
            {
                if (result.ContainsKey(item.Item1))
                    Console.WriteLine("duplicate " + item.Item1.ToString());

                result.Add(item.Item1, item.Item2);
            }
            return result;
        }
    }
}