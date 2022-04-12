using System;
using System.Configuration;
using System.Reflection;
using System.Reactive.Linq;
using System.IO;

namespace Experiments
{
    class Program
    {
        static int Main(string[] args) {
            if (args.Length < 2)
                printUsage();
            else {
                string experiment = args[0];
                string executionTimeLog = args[1];
                ulong punctuationTime = (ulong)Convert.ToDouble(args[2]);
                int filterCondition = Convert.ToInt32(args[3]);
                bool withOutput = String.Equals(args[4], "withOutput=true");
                string path = ConfigurationManager.AppSettings[experiment + ".perf.path"];
                exec(experiment, executionTimeLog, path, punctuationTime, filterCondition, withOutput);
            }
            return 0;
        }

        private static void printUsage() {
            Console.WriteLine("Usage: experiments-trill experimentName executionTimeLog punctuationTime [withOutput]");
            System.Environment.Exit(1);
        }

        private static void exec(string experiment, string executionTimeLog, string path, ulong punctuationTime, int filterCondition, bool withOutput) {
            Assembly assembly = Assembly.GetExecutingAssembly();
            string ns = char.ToUpper(experiment[0]) + experiment.Substring(1);
            Type type = assembly.GetType(ns + ".Query");
            MethodInfo methodInfo = type.GetMethod("Execute");

            long start = DateTimeOffset.Now.ToUnixTimeMilliseconds();
            var mode = 0;
            if (withOutput)
                mode = 2;
            methodInfo.Invoke(null, new object[] { path, punctuationTime, filterCondition , mode});
        
            long end = DateTimeOffset.Now.ToUnixTimeMilliseconds();
            long total = end - start;

            string[] lines = { (total / 1000f).ToString("f2") };
            File.WriteAllLines(executionTimeLog, lines);
            Console.WriteLine("experiment " + experiment + " finished. Execution time: " + (total / 1000f).ToString("f2"));
        }
    }
}
