sudo bash update.sh -y 

wget https://nginx.org/packages/ubuntu/pool/nginx/n/nginx/nginx_1.22.1-1~jammy_arm64.deb || exit 1
sudo dpkg -i -y nginx_1.22.1-1~jammy_arm64.deb
rm -f nginx_1.22.1-1~jammy_arm64.deb

sudo mkdir -p /etc/nginx/{sites-available,sites-enabled}

sudo systemctl enable nginx
sudo systemctl start nginx