using System;

namespace Snb2_arbitrary
{
    class Tag  {
        public long t_tagid;
        public string t_name;
        public string t_url;
        public long t_tagclassid;

        public Tag(long t_tagid, string t_name, string t_url, long t_tagclassid) {
            this.t_tagid = t_tagid;
            this.t_name = t_name;
            this.t_url = t_url;
            this.t_tagclassid = t_tagclassid;
        }
    }
}