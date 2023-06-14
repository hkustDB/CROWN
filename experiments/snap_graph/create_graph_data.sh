#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")

data_path="${SCRIPT_PATH}"
cd "${data_path}"

# 1. bitcoin (from https://snap.stanford.edu/data/soc-sign-bitcoin-alpha.html)
rm -f bitcoin.txt
rm -f soc-sign-bitcoinalpha.csv
rm -f soc-sign-bitcoinalpha.csv.gz
curl -O https://snap.stanford.edu/data/soc-sign-bitcoinalpha.csv.gz > /dev/null 2>&1
gzip -d soc-sign-bitcoinalpha.csv.gz
# drop the last two column
sed -i "s/,[[:digit:]]\+,[[:digit:]]\+$//g" soc-sign-bitcoinalpha.csv
mv soc-sign-bitcoinalpha.csv bitcoin.txt

# 2. epinions (from https://snap.stanford.edu/data/soc-Epinions1.html)
rm -f epinions.txt
rm -f soc-Epinions1.txt
rm -f soc-Epinions1.txt.gz
curl -O https://snap.stanford.edu/data/soc-Epinions1.txt.gz > /dev/null 2>&1
gzip -d soc-Epinions1.txt.gz
tail -n +5 soc-Epinions1.txt > epinions.txt
rm -f soc-Epinions1.txt
sed -i "s/\t/,/g" epinions.txt

# 3. google (from https://snap.stanford.edu/data/web-Google.html)
rm -f google.txt
rm -f web-Google.txt
rm -f web-Google.txt.gz
curl -O https://snap.stanford.edu/data/web-Google.txt.gz > /dev/null 2>&1
gzip -d web-Google.txt.gz
tail -n +5 web-Google.txt > google.txt
rm -f web-Google.txt
sed -i "s/\t/,/g" google.txt

# 4. berkstan (from https://snap.stanford.edu/data/web-BerkStan.html)
rm -f berkstan.txt
rm -f web-BerkStan.txt
rm -f web-BerkStan.txt.gz
curl -O https://snap.stanford.edu/data/web-BerkStan.txt.gz > /dev/null 2>&1
gzip -d web-BerkStan.txt.gz
tail -n +5 web-BerkStan.txt > berkstan.txt
rm -f web-BerkStan.txt
sed -i "s/\t/,/g" berkstan.txt

