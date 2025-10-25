# 旧Nginx
SSH 连接 ：

ssh -i ~/.ssh/id_ed25519 ubuntu@ec2-3-87-86-188.compute-1.amazonaws.com


上传密钥过去
scp -i ~/.ssh/id_ed25519 /root/EC2-Common-Key.pem ubuntu@ec2-3-87-86-188.compute-1.amazonaws.com:/home/ubuntu/


上传官网文件过去
scp -i "~/EC2-Common-Key.pem" /home/ubuntu/dist.zip ubuntu@172.31.18.91:/home/ubuntu/


scp -i "~/EC2-Common-Key.pem" /home/ubuntu/nginx/conf/nginx.conf ubuntu@172.31.18.91:/home/ubuntu/nginx/conf

scp -i "~/EC2-Common-Key.pem" /home/ubuntu/nginx/ssl/keypass.txt  ubuntu@172.31.18.91:/home/ubuntu/nginx/ssl
scp -i "~/EC2-Common-Key.pem" /home/ubuntu/nginx/ssl/ledouyx.com.crt  ubuntu@172.31.18.91:/home/ubuntu/nginx/ssl
scp -i "~/EC2-Common-Key.pem" /home/ubuntu/nginx/ssl/ledouyx.com.key  ubuntu@172.31.18.91:/home/ubuntu/nginx/ssl


# Nginx-DB-EC2

SSH 连接 ：

ssh -i "~/Desktop/Projects//EC2-Common-Key.pem" ubuntu@ec2-54-159-54-177.compute-1.amazonaws.com

上传文件：示例

scp -i "~/Desktop/Projects/EC2-Common-Key.pem" ~/Desktop/Projects/EC2-Common-Key.pem ubuntu@ec2-54-159-54-177.compute-1.amazonaws.com:/home/ubuntu/

## 部署 Nginx

mkdir -p /home/ubuntu/nginx/conf /home/ubuntu/nginx/ssl /home/ubuntu/nginx/html

docker run -d \
  --name nginx \
  -p 80:80 \
  -p 443:443 \
  -v /home/ubuntu/nginx/conf/nginx.conf:/etc/nginx/nginx.conf \
  -v /home/ubuntu/nginx/ssl:/etc/nginx/ssl \
  -v /home/ubuntu/nginx/html:/usr/share/nginx/html \
  --restart=always \
  nginx:1.25.3



## 部署官网

cd ~
sudo apt install unzip
unzip dist.zip

cp -r ./dist/* ./nginx/html/




# Chef-Backend-EC2 
目前在 default 安全组开墙

SSH 连接：
ssh -i "~/Desktop/Projects/EC2-Common-Key.pem" ubuntu@ec2-34-229-156-60.compute-1.amazonaws.com