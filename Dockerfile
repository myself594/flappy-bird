# 多阶段构建：第一阶段用 Godot 导出 Web 版本
FROM barichello/godot-ci:4.5 AS builder

WORKDIR /game

# 复制项目文件
COPY . .

# 创建输出目录
RUN mkdir -p build/web

# 导出 Web 版本
RUN godot --headless --export-release "Web" build/web/index.html

# 第二阶段：使用 Nginx 托管静态文件
FROM nginx:alpine

# 复制导出的 Web 文件到 Nginx
COPY --from=builder /game/build/web /usr/share/nginx/html

# 配置 Nginx 支持 SharedArrayBuffer (Godot 4 需要)
RUN echo 'server { \
    listen 80; \
    server_name localhost; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        add_header Cross-Origin-Opener-Policy same-origin; \
        add_header Cross-Origin-Embedder-Policy require-corp; \
        try_files $uri $uri/ =404; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
