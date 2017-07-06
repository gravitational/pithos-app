FROM nginx:latest

ADD conf/nginx.conf /etc/nginx
RUN rm /etc/nginx/conf.d/default.conf
COPY conf/conf.d /etc/nginx/conf.d/
