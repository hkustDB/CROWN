using System;

namespace TwoComb {
    public class Vertex : IEquatable<Vertex> {
        public int value;

        public Vertex(int value) {
            this.value = value;
        }

        public bool Equals(Vertex that) {
            return (that != null) && (that.value == this.value);
        }

        public override bool Equals(object obj) => Equals(obj as Vertex);

        public override int GetHashCode() => (value).GetHashCode();

        public override string ToString() => $"({value})";
    }
}