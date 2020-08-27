FROM nginx:latest

## add permissions
RUN chown -R 1000:1000 /var/cache/nginx && \
    chown -R 1000:1000 /var/log/nginx && \
    chown -R 1000:1000 /etc/nginx/conf.d
RUN touch /var/run/nginx.pid && \
    chown -R 1000:1000 /var/run/nginx.pid

ADD conf/nginx.conf /etc/nginx
RUN rm /etc/nginx/conf.d/default.conf
COPY conf/conf.d /etc/nginx/conf.d/
