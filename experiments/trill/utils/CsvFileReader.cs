using System;
using System.Threading;
using System.IO;
using Microsoft.StreamProcessing;


namespace Csv {
    class CsvFileReader<R,P> {
        public static IStreamable<Empty, P> GetStartStreamable(string path, ulong punctuationTime, Func<string, R> lineToRow, Func<R, P> rowToPayload,
                Func<R, long> extractStart) {
            return new CsvObservable(path, lineToRow, rowToPayload, InputEventType.Start, extractStart, null)
                .ToStreamable(null, FlushPolicy.FlushOnPunctuation, PeriodicPunctuationPolicy.Time(punctuationTime));
        }

        public static IStreamable<Empty, P> GetIntervalStreamable(string path, ulong punctuationTime, Func<string, R> lineToRow, Func<R, P> rowToPayload,
                Func<R, long> extractStart, Func<R, long> extractEnd) {
            return new CsvObservable(path, lineToRow, rowToPayload, InputEventType.Interval, extractStart, extractEnd)
                .ToStreamable(null, FlushPolicy.FlushOnPunctuation, PeriodicPunctuationPolicy.Time(punctuationTime));
        }

        public static IStreamable<Empty, P> GetPointStreamable(string path, ulong punctuationTime, Func<string, R> lineToRow, Func<R, P> rowToPayload,
                Func<R, long> extractPoint) {
            return new CsvObservable(path, lineToRow, rowToPayload, InputEventType.Point, extractPoint, null)
                .ToStreamable(null, FlushPolicy.FlushOnPunctuation, PeriodicPunctuationPolicy.Time(punctuationTime));
        }

        public static IStreamable<Empty, P> GetStartOrEndStreamable(string path, ulong punctuationTime, Func<string, R> lineToRow, Func<R, P> rowToPayload,
                Func<R, long> extractStartOrEnd, Func<R, long> extractPoint) {
            return new CsvObservable(path, lineToRow, rowToPayload, InputEventType.StartOrEnd, extractStartOrEnd, extractPoint)
                .ToStreamable(null, FlushPolicy.FlushOnPunctuation, PeriodicPunctuationPolicy.Time(punctuationTime));
        }

        public static IStreamable<Empty, P> GetLatencyStreamable(string path, ulong punctuationTime, Func<string, R> lineToRow, Func<R, P> rowToPayload,
                Func<R, long> extractStartOrEnd, Func<R, long> extractPoint, List<Tuple<Edge, long>> insert, List<Tuple<Edge, long>> delete) {
            return new CsvObservable(path, lineToRow, rowToPayload, InputEventType.StartOrEnd, extractStartOrEnd, extractPoint)
                .ToStreamable(null, FlushPolicy.FlushOnPunctuation, PeriodicPunctuationPolicy.Time(punctuationTime));
        }

        private sealed class CsvObservable : IObservable<StreamEvent<P>> {
            private string path;
            private Func<string, R> lineToRow;
            private Func<R, P> rowToPayload;
            private InputEventType eventType;
            private Func<R, long> extractTime1;
            private Func<R, long> extractTime2;
            private List<Tuple<Edge, long>> insertList;
            private List<Tuple<Edge, long>> deleteList;

            public CsvObservable(string path, Func<string, R> lineToRow, Func<R, P> rowToPayload, 
                InputEventType eventType, Func<R, long> extractTime1, Func<R, long> extractTime2,
                List<Tuple<Edge, long>> insertList, List<Tuple<Edge, long>> deleteList) {
                this.path = path;
                this.lineToRow = lineToRow;
                this.rowToPayload = rowToPayload;
                this.eventType = eventType;
                this.extractTime1 = extractTime1;
                this.extractTime2 = extractTime2;
                this.insertList = insertList;
                this.deleteList = deleteList;
            }

            public IDisposable Subscribe(IObserver<StreamEvent<P>> observer) {
                return new Subscription(path, lineToRow, rowToPayload, eventType, extractTime1, extractTime2, observer);
            }

            private sealed class Subscription : IDisposable {
                private string path;
                private Func<string, R> lineToRow;
                private Func<R, P> rowToPayload;
                private InputEventType eventType;
                private Func<R, long> extractTime1;
                private Func<R, long> extractTime2;
                private IObserver<StreamEvent<P>> observer;
                private Thread readerThread;

                public Subscription(string path, Func<string, R> lineToRow, Func<R, P> rowToPayload,
                        InputEventType eventType, Func<R, long> extractTime1, Func<R, long> extractTime2, IObserver<StreamEvent<P>> observer) {
                    this.path = path;
                    this.lineToRow = lineToRow;
                    this.rowToPayload = rowToPayload;
                    this.eventType = eventType;
                    this.extractTime1 = extractTime1;
                    this.extractTime2 = extractTime2;
                    this.observer = observer;
                    
                    ThreadStart readerStart = new ThreadStart(ReaderThreadFun);
                    readerThread = new Thread(readerStart);
                    readerThread.Start();
                }

                public void Dispose() {
                    
                }

                private void ReaderThreadFun() {
                    foreach (string line in File.ReadLines(path)) { 
                        R row = lineToRow(line);
                        P payload = rowToPayload(row);

                        switch (eventType) {
                            case InputEventType.Start: {
                                this.observer.OnNext(StreamEvent.CreateStart(extractTime1(row), payload));
                                break;
                            }
                            case InputEventType.Interval: {
                                this.observer.OnNext(StreamEvent.CreateInterval(extractTime1(row), extractTime2(row), payload));
                                break;
                            }
                            case InputEventType.Point: {
                                this.observer.OnNext(StreamEvent.CreatePoint(extractTime1(row), payload));
                                break;
                            }
                            case InputEventType.StartOrEnd: {
                                bool isStart = (extractTime2(row) == 0);
                                if (isStart)
                                    this.observer.OnNext(StreamEvent.CreateStart(extractTime1(row), payload));
                                else
                                    this.observer.OnNext(StreamEvent.CreateEnd(extractTime1(row), extractTime2(row), payload));
                                break;
                            }
                        }
                            
                    } 

                    this.observer.OnNext(StreamEvent.CreatePunctuation<P>(long.MaxValue));
                    this.observer.OnCompleted();
                }
            }
        }
    }
}