using System;
using System.IO;
using System.Reactive.Linq;
using Microsoft.StreamProcessing;

namespace Csv {
    class CsvFileWriter<T> {
        public static void WriteToFile(string path, IObservable<StreamEvent<T>> observable, 
                Func<StreamEvent<T>, string[]> convert) {
            using(StreamWriter writer = new StreamWriter(path)) {
                observable.ForEachAsync(ev => {
                    string[] strings = convert(ev);
                    if (strings != null) {
                        string line = String.Join(",", strings);
                        writer.WriteLine(line);
                    }
                }).Wait();
            }
        }
    }
}