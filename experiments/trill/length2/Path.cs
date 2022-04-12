using System;

namespace Length2 {
    class Path : IEquatable<Path> {
        public int src;
        public int via;
        public int dst;

        public Path(int src, int via, int dst) {
            this.src = src;
            this.via = via;
            this.dst = dst;
        }

        public bool Equals(Path that) {
            return (that != null) && (that.src == this.src) && (that.via == this.via) && (that.dst == this.dst);
        }

        public override bool Equals(object obj) => Equals(obj as Path);
        
        public override int GetHashCode() => (src, via, dst).GetHashCode();

        public override string ToString() => $"({src}, {via}, {dst})";
    }
}