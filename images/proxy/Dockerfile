FROM nginx:latest

## add permissions
RUN chown -R nginx /var/cache/nginx && \
    chown -R nginx /var/log/nginx && \
    chown -R nginx /etc/nginx/conf.d
RUN touch /var/run/nginx.pid && \
    chown -R nginx /var/run/nginx.pid

ADD conf/nginx.conf /etc/nginx
RUN rm /etc/nginx/conf.d/default.conf
COPY conf/conf.d /etc/nginx/conf.d/
