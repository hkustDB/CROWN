using System;

namespace Snb3_arbitrary
{
    class Person  {
        public bool p_explicitlyDeleted;
        public long p_personid;
        public string p_firstname;
        public string p_lastname;
        public string p_gender;
        public string p_birthday;
        public string p_locationip;
        public string p_browserused;
        public long p_placeid;
        public string p_language;
        public string p_email;

        public Person(bool p_explicitlyDeleted, long p_personid, string p_firstname, string p_lastname, string p_gender, 
            string p_birthday, string p_locationip, string p_browserused, long p_placeid, string p_language, string p_email) {
            this.p_explicitlyDeleted = p_explicitlyDeleted;
            this.p_personid = p_personid;
            this.p_firstname = p_firstname;
            this.p_lastname = p_lastname;
            this.p_gender = p_gender;
            this.p_birthday = p_birthday;
            this.p_locationip = p_locationip;
            this.p_browserused = p_browserused;
            this.p_placeid = p_placeid;
            this.p_language = p_language;
            this.p_email = p_email;
        }
    }
}