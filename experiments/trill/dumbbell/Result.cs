using System;

namespace Dumbbell {
    class Result : IEquatable<Result> {
        public int a;
        public int b;

        public Result(int a, int b) {
            this.a = a;
            this.b = b;
        }

        public bool Equals(Result that) {
            return (that != null) && (that.a == this.a) && (that.b == this.b);
        }

        public override bool Equals(object obj) => Equals(obj as Result);
        
        public override int GetHashCode() => (a,b).GetHashCode();

        public override string ToString() => $"({a}, {b})";
    }
}