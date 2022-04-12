using System;

namespace Star {
    class Path : IEquatable<Path> {
        public int src;
        public int dst1;
        public int dst2;
        public int dst3;
        public int dst4;

        public Path(int src, int dst1, int dst2, int dst3, int dst4) {
            this.src = src;
            this.dst1 = dst1;
            this.dst2 = dst2;
            this.dst3 = dst3;
            this.dst4 = dst4;
        }

        public bool Equals(Path that) {
            return (that != null) && (that.src == this.src) && (that.dst1 == this.dst1) 
                && (that.dst2 == this.dst2) && (that.dst3 == this.dst3) && (that.dst4 == this.dst4);
        }

        public override bool Equals(object obj) => Equals(obj as Path);
        
        public override int GetHashCode() => (src, dst1, dst2, dst3).GetHashCode();

        public override string ToString() => $"({src}, {dst1}, {dst2}, {dst3}, {dst4})";
    }
}