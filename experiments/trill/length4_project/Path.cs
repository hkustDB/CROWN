using System;

namespace Length4_project {
    class Path : IEquatable<Path> {
        public int via1;
        public int via2;
        public int via3;

        public Path(int via1, int via2, int via3) {
            this.via1 = via1;
            this.via2 = via2;
            this.via3 = via3;
        }

        public bool Equals(Path that) {
            return (that != null) && (that.via1 == this.via1) 
                && (that.via2 == this.via2) && (that.via3 == this.via3);
        }

        public override bool Equals(object obj) => Equals(obj as Path);
        
        public override int GetHashCode() => (via1, via2, via3).GetHashCode();

        public override string ToString() => $"({via1}, {via2}, {via3})";
    }
}