using System;

namespace Length3_filter2 {
    class Path : IEquatable<Path> {
        public int src;
        public int via1;
        public int via2;
        public int dst;

        public Path(int src, int via1, int via2, int dst) {
            this.src = src;
            this.via1 = via1;
            this.via2 = via2;
            this.dst = dst;
        }

        public bool Equals(Path that) {
            return (that != null) && (that.src == this.src) && (that.via1 == this.via1) 
                && (that.via2 == this.via2) && (that.dst == this.dst);
        }

        public override bool Equals(object obj) => Equals(obj as Path);
        
        public override int GetHashCode() => (src, via1, via2, dst).GetHashCode();

        public override string ToString() => $"({src}, {via1}, {via2}, {dst})";
    }
}