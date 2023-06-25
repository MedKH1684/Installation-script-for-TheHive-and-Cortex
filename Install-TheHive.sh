#!/bin/bash

#Install TheHive 
sudo apt-get install -y curl 

#Install JVM 
sudo apt-get install -y openjdk-8-jre-headless 
sudo -c 'echo JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64" >> /etc/environment' 
sudo export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64" 

#Install Cassandra 
echo "deb https://debian.cassandra.apache.org 311x main" | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list 
sudo deb https://debian.cassandra.apache.org 311x main 
curl https://downloads.apache.org/cassandra/KEYS | sudo apt-key add - 
sudo apt-get update 
sudo apt-get install -y cassandra 

#Configure Cassandra 
cqlsh localhost 9042 -e "UPDATE system.local SET cluster_name = 'thp' where key='local';" 
nodetool flush 
sudo cp /etc/cassandra/cassandra.yaml /etc/cassandra/cassandra.yaml.bak 
sudo sed -i "s|cluster_name: 'Test Cluster'|cluster_name: 'thp'|g" /etc/cassandra/cassandra.yaml 
sudo systemctl restart cassandra 

#Install TheHive4 
#Create Lucene folder for indexes 
sudo mkdir -p /opt/thp/thehive/index 
sudo chown thehive:thehive -R /opt/thp/thehive/index 

#File Storage 
sudo mkdir -p /opt/thp/thehive/files 
sudo chown -R thehive:thehive /opt/thp/thehive/files 

#theHive 
curl https://raw.githubusercontent.com/TheHive-Project/TheHive/master/PGP-PUBLIC-KEY | sudo apt-key add - 
echo 'deb https://deb.thehive-project.org release main' | sudo tee -a /etc/apt/sources.list.d/thehive-project.list 
sudo apt-get update 
sudo apt-get install thehive4 

#configure theHive 
thehive_ip=127.0.0.1 
cluster_name=thp 
local_datacenter=datacenter1 
sudo cp /etc/thehive/application.conf /etc/thehive/application.conf.bak 
sudo sed -i 's+// backend: cql+backend: cql+g' /etc/thehive/application.conf 
sudo sed -i "0,/\/\/ hostname: \[\"ip1\", \"ip2\"\]/s//hostname: [\"$thehive_ip\"]/g" /etc/thehive/application.conf 
sudo sed -i '0,/\ \ \ \ \ \ cluster-name: thp/s///g' /etc/thehive/application.conf 
sudo sed -i '0,/\ \ \ \ \ \ keyspace: thehive/s///g' /etc/thehive/application.conf 
sudo sed -i "/cql {/a \ \ \ \ \ \ cluster-name: $cluster_name\n\ \ \ \ \ \ keyspace: thehive\n\ \ \ \ \ \ local-datacenter: $local_datacenter\n\ \ \ \ \ \ read-consistency-level: ONE\n\ \ \ \ \ \ write-consistency-level: ONE" /etc/thehive/application.conf 
sudo sed -i 's|// provider: localfs|provider: localfs|g' /etc/thehive/application.conf 
sudo sed -i 's|// localfs.location: .*|localfs.location: /opt/thp/thehive/files|' /etc/thehive/application.conf 
sudo systemctl restart thehive 

#Login/Password : admin@thehive.local:secret 
