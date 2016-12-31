wget http://github.com/shangjingbo1226/AutoPhrase/archive/master.zip
unzip master.zip
rm master.zip
mv AutoPhrase-master autophrase
tar -zcvf autophrase.tar.gz autophrase
rm -r autophrase
# sudo docker build -t remenberl/autophrase .