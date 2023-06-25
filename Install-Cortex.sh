#!/bin/bash

#requirements 
sudo apt install -y wget gnupg apt-transport-https git ca-certificates ca-certificates-java curl  software-properties-common python3-pip 

#ElasticSearch Installation 
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch |  sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg 
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/7.x/apt stable main" |  sudo tee /etc/apt/sources.list.d/elastic-7.x.list  
sudo apt-get update 
sudo apt install -y elasticsearch    

#Configure ElasticSearch 
sudo sh -c "echo 'http.host: 127.0.0.1 
transport.host: 127.0.0.1 
cluster.name: hive 
thread_pool.search.queue_size: 100000 
xpack.security.enabled: false 
script.allowed_types: \"inline,stored\"' >> /etc/elasticsearch/elasticsearch.yml" 

#Ressources Config 
sudo sh -c "echo '-Dlog4j2.formatMsgNoLookups=true 
-Xms2g 
-Xmx2g' >> /etc/elasticsearch/jvm.options.d/jvm.options" 

#start EasticSearch 
sudo service elasticsearch start 

#Cortex 
wget -O- "https://raw.githubusercontent.com/TheHive-Project/Cortex/master/PGP-PUBLIC-KEY"  | sudo apt-key add - 
wget -qO- https://raw.githubusercontent.com/TheHive-Project/Cortex/master/PGP-PUBLIC-KEY |  sudo gpg --dearmor -o /usr/share/keyrings/thehive-project.gpg 
echo 'deb https://deb.thehive-project.org release main' | sudo tee -a /etc/apt/sources.list.d/thehive-project.list 
sudo apt update 
sudo apt install cortex 

#Configure Cortex 
#Secret key configuration 
sudo sh -c 'cat > /etc/cortex/secret.conf << _EOF_ 
play.http.secret.key="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)" 
_EOF_' 
sudo sed -i 's/#play.http.secret.key="\*\*\*CHANGEME\*\*\*"/include "\/etc\/cortex\/secret.conf"/g' /etc/cortex/application.conf 

#Store & run programs on the host: Some system packages are required to run Analyzers&Responders programs successfully + Run you own Analyzers & Responders 
sudo cp /etc/cortex/application.conf /etc/cortex/application.conf.bak 
sudo apt install -y --no-install-recommends python3-pip python3-dev ssdeep libfuzzy-dev libfuzzy2 libimage-exiftool-perl libmagic1 build-essential git libssl-dev 
sudo pip3 install -U pip setuptools 
cd /opt 
sudo git clone https://github.com/TheHive-Project/Cortex-Analyzers 
sudo chown -R cortex:cortex /opt/Cortex-Analyzers  
for I in $(find Cortex-Analyzers -name 'requirements.txt'); do sudo -H pip3 install -r $I || true; done 
cd /opt 
sudo mkdir -p Custom-Analyzers/{analyzers,responder} 
sudo chown -R cortex:cortex /opt/Cortex-Analyzers 
sudo sed -i 's/#"\/absolute\/path\/of\/analyzers"/,"\/opt\/Cortex-Analyzers\/analyzers"\n\ \ \ \ ,"\/opt\/Custom-Analyzers\/analyzers"/g' /etc/cortex/application.conf 
sudo sed -i 's/#"\/absolute\/path\/of\/responders"/,"\/opt\/Cortex-Analyzers\/responders"\n\ \ \ \ ,"\/opt\/Custom-Analyzers\/responders"/g' /etc/cortex/application.conf 

#start Cortex service 
sudo service cortex start 
