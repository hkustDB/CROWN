using System;

namespace Star_cnt {
    class Result : IEquatable<Result> {
        public int src;
        public ulong cnt;

        public Result(int src, ulong cnt) {
            this.src = src;
            this.cnt = cnt;
        }

        public bool Equals(Result that) {
            return (that != null) && (that.src == this.src) && (that.cnt == this.cnt);
        }

        public override bool Equals(object obj) => Equals(obj as Result);
        
        public override int GetHashCode() => (src, cnt).GetHashCode();

        public override string ToString() => $"({src}, {cnt})";
    }
}