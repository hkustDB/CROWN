using System;

namespace Snb3_window
{
    class Message  {
        public bool m_explicitlyDeleted;
        public long m_messageid;
        public string m_ps_imagefile;
        public string m_locationip;
        public string m_browserused;
        public string m_ps_language;
        public string m_content;
        public long m_length;
        public long m_creatorid;
        public long m_locationid;
        public long m_ps_forumid;
        public long  m_c_parentpostid;
        public long  m_c_replyof;

        public Message(bool m_explicitlyDeleted, long m_messageid, string m_ps_imagefile, string m_locationip, string m_browserused, 
            string m_ps_language, string m_content, long m_length, long m_creatorid, long m_locationid, long m_ps_forumid,
            long m_c_parentpostid, long m_c_replyof) {
            this.m_explicitlyDeleted = m_explicitlyDeleted;
            this.m_messageid = m_messageid;
            this.m_ps_imagefile = m_ps_imagefile;
            this.m_locationip = m_locationip;
            this.m_browserused = m_browserused;
            this.m_ps_language = m_ps_language;
            this.m_content = m_content;
            this.m_length = m_length;
            this.m_creatorid = m_creatorid;
            this.m_locationid = m_locationid;
            this.m_ps_forumid = m_ps_forumid;
            this.m_c_parentpostid = m_c_parentpostid;
            this.m_c_replyof = m_c_replyof;
        }

    }
}