FROM node:20-alpine

RUN apk add --no-cache curl git

# Install Shopify CLI
RUN yarn global add @shopify/cli@latest @shopify/app@latest

RUN cat <<EOF > /usr/local/bin/xdg-open
#!/bin/sh
echo "xdg-open URL: \$@"
EOF

RUN chmod +x /usr/local/bin/xdg-open

WORKDIR /app
EXPOSE 8080
ENTRYPOINT ["shopify"]