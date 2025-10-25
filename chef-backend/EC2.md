# Nginx-DB-EC2

SSH 连接 ：

ssh -i "~/Desktop/Projects//EC2-Common-Key.pem" ubuntu@ec2-54-159-54-177.compute-1.amazonaws.com

上传文件：

scp -i "~/Desktop/Projects/EC2-Common-Key.pem" ~/Desktop/Projects/EC2-Common-Key.pem ubuntu@ec2-54-159-54-177.compute-1.amazonaws.com:/home/ubuntu/


# Chef-Backend-EC2 
目前在 default 安全组开墙

在 Nginx-DB-EC2 执行：
ssh -i "~/EC2-Common-Key.pem" ubuntu@172.31.27.30