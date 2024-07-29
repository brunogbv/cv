FROM nginx:alpine

ARG SITE_NAME

# Copy custom Nginx configuration files
COPY nginx.conf /etc/nginx/nginx.conf
COPY sites-available/ /etc/nginx/sites-available/
RUN mkdir -p /etc/nginx/sites-enabled/ && \
  ln -s /etc/nginx/sites-available/$SITE_NAME /etc/nginx/sites-enabled/valerio.dev

# Expose ports
EXPOSE 80
EXPOSE 443
