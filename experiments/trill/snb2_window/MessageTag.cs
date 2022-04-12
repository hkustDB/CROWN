using System;

namespace Snb2_window
{
    class MessageTag  {
        public long mt_messageid;
        public long mt_tagid;

        public MessageTag(long mt_messageid, long mt_tagid) {
            this.mt_messageid = mt_messageid;
            this.mt_tagid = mt_tagid;
        }
    }
}