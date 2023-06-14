using System;

namespace Length4_latency {
    class Path : IEquatable<Path> {
        public int src;
        public int via1;
        public int via2;
        public int via3;
        public int dst;

        public Path(int src, int via1, int via2, int via3, int dst) {
            this.src = src;
            this.via1 = via1;
            this.via2 = via2;
            this.via3 = via3;
            this.dst = dst;
        }

        public bool Equals(Path that) {
            return (that != null) && (that.src == this.src) && (that.via1 == this.via1) 
                && (that.via2 == this.via2) && (that.via3 == this.via3) && (that.dst == this.dst);
        }

        public override bool Equals(object obj) => Equals(obj as Path);
        
        public override int GetHashCode() => (src, via1, via2, via3, dst).GetHashCode();

        public override string ToString() => $"({src}, {via1}, {via2}, {via3}, {dst})";
    }
}