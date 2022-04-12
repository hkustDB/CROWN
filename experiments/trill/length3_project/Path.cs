using System;

namespace Length3_project {
    class Path : IEquatable<Path> {
        public int via1;
        public int via2;

        public Path(int via1, int via2) {
            this.via1 = via1;
            this.via2 = via2;
        }

        public bool Equals(Path that) {
            return (that != null) && (that.via1 == this.via1) 
                && (that.via2 == this.via2);
        }

        public override bool Equals(object obj) => Equals(obj as Path);
        
        public override int GetHashCode() => (via1, via2).GetHashCode();

        public override string ToString() => $"({via1}, {via2})";
    }
}