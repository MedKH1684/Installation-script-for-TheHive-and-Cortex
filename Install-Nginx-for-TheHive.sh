#!/bin/bash

thehive_ip=127.0.0.1 

#Generate self-signed certificate using OpenSSL 
mkdir ~/TheHive 
cd  ~/TheHive 
openssl req -newkey rsa:2048 -new -nodes -x509 -days 3650 -keyout key.pem -out cert.pem 

#Install + Configure nginx reverse proxy 
sudo apt-get install -y nginx 
sudo systemctl start nginx 
sudo systemctl enable nginx 

#cert + key folder 
sudo mkdir /etc/nginx/ssl 
sudo cp /home/thehive/TheHive/cert.pem /etc/nginx/ssl/thehive_cert.pem 
sudo cp /home/thehive/TheHive/key.pem /etc/nginx/ssl/thehive_key.pem 

#configuration for the SSL + reverse proxy 
sudo sh -c "echo 'server { 
  listen 443 ssl; 
  server_name thehive.example.com; 
  ssl on; 
  ssl_certificate       ssl/thehive_cert.pem; 
  ssl_certificate_key   ssl/thehive_key.pem; 
  proxy_connect_timeout   600; 
  proxy_send_timeout      600; 
  proxy_read_timeout      600; 
  send_timeout            600; 
  client_max_body_size    2G; 
  proxy_buffering off; 
  client_header_buffer_size 8k; 
  location / { 
    add_header              Strict-Transport-Security \"max-age=31536000; includeSubDomains\"; 
    proxy_pass              http://$thehive_ip:9000/; 
    proxy_http_version      1.1; 
  } 
}' > /etc/nginx/sites-enabled/thehive.conf" 
sudo nginx -s reload 
