using System;

namespace Dumbbell {
    class Result : IEquatable<Result> {
        public int a;
        public int b;
        public int c;
        public int d;
        public int e;
        public int f;

        public Result(int a, int b, int c, int d, int e, int f) {
            this.a = a;
            this.b = b;
            this.c = c;
            this.d = d;
            this.e = e;
            this.f = f;
        }

        public bool Equals(Result that) {
            return (that != null) && (that.a == this.a) && (that.b == this.b) 
            && (that.c == this.c) && (that.d == this.d) && (that.e == this.e) && (that.f == this.f);
        }

        public override bool Equals(object obj) => Equals(obj as Result);
        
        public override int GetHashCode() => (a,b,c,d,e,f).GetHashCode();

        public override string ToString() => $"({a}, {b}, {c}, {d}, {e}, {f})";
    }
}