sudo bash update.sh -y 

wget https://nginx.org/packages/ubuntu/pool/nginx/n/nginx/nginx_1.22.1-1~jammy_arm64.deb

sudo dpkg -i nginx_1.22.1-1~jammy_arm64.deb

rm nginx_1.22.1-1~jammy_arm64.deb

sudo mkdir -p /etc/nginx/{sites-available,sites-enabled}

sudo systemctl enable nginx
sudo systemctl start nginx