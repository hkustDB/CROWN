using System;

namespace Snb4_arbitrary
{
    class Knows {
        public bool k_explicitlyDeleted;
        public long k_person1id;
        public long k_person2id;

        public Knows(bool k_explicitlyDeleted, long k_person1id, long k_person2id) {
            this.k_explicitlyDeleted = k_explicitlyDeleted;
            this.k_person1id = k_person1id;
            this.k_person2id = k_person2id;
        }
    } 
}