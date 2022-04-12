using System;

namespace Length2 {
    public class Edge : IEquatable<Edge> {
        public int src;
        public int dst;

        public Edge(int src, int dst) {
            this.src = src;
            this.dst = dst;
        }

        public bool Equals(Edge that) {
            return (that != null) && (that.src == this.src) && (that.dst == this.dst);
        }

        public override bool Equals(object obj) => Equals(obj as Edge);
        
        public override int GetHashCode() => (src, dst).GetHashCode();

        public override string ToString() => $"({src}, {dst})";
    }
}