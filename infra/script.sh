#!/bin/bash
set -ex

# Update system packages
dnf update -y
dnf install -y aws-cli jq httpd

# Export environment variables from SSM
export AWS_REGION=eu-west-2
export S3_BUCKET_NAME_TEMPLATE=$(aws ssm get-parameter --name "/blog-app/S3_BUCKET_NAME_TEMPLATE" --region $AWS_REGION --query "Parameter.Value" --output text)
export S3_BUCKET_NAME=$(aws ssm get-parameter --name "/blog-app/S3_BUCKET_NAME" --region $AWS_REGION --query "Parameter.Value" --output text)
export DB_PORT=$(aws ssm get-parameter --name "/blog-app/DB_PORT" --region $AWS_REGION --query "Parameter.Value" --output text)
export DB_USER=$(aws ssm get-parameter --name "/blog-app/DB_USER" --region $AWS_REGION --query "Parameter.Value" --output text)
export DB_NAME=$(aws ssm get-parameter --name "/blog-app/DB_NAME" --region $AWS_REGION --query "Parameter.Value" --output text)
export DB_HOST=$(aws ssm get-parameter --name "/blog-app/DB_HOST" --region $AWS_REGION --query "Parameter.Value" --output text)
export DB_PASS=$(aws ssm get-parameter --name "/blog-app/DB_PASS" --region $AWS_REGION --query "Parameter.Value" --output text)
export NODE_ENV=production

# Enable and start Apache
systemctl enable --now httpd

# Install Node.js 22 and PM2
curl -fsSL https://rpm.nodesource.com/setup_22.x | bash -
dnf install -y nodejs
npm install -g pm2

# Create app directory
mkdir -p /var/www/html/
cd /var/www/html

# Download artifact from S3
aws s3 cp s3://$S3_BUCKET_NAME_TEMPLATE/artifacts/Blog-App.tar.gz .

# Extract and clean up
tar -xzf Blog-App.tar.gz -C /var/www/html/
rm -f Blog-App.tar.gz

# Set permissions
chown -R ec2-user:ec2-user /var/www/html
chmod -R 755 /var/www/html





# Install Node.js dependencies
cd /var/www/html/Blog-App
npm install --omit=dev

# Start the app with PM2 using secure inline environment injection
sudo -u ec2-user \
DB_HOST=$DB_HOST \
DB_PORT=$DB_PORT \
DB_USER=$DB_USER \
DB_PASS=$DB_PASS \
DB_NAME=$DB_NAME \
AWS_REGION=$AWS_REGION \
S3_BUCKET_NAME_TEMPLATE=$S3_BUCKET_NAME_TEMPLATE \
S3_BUCKET_NAME=$S3_BUCKET_NAME \
NODE_ENV=$NODE_ENV \
pm2 start index.js --name Blog-App

# Save and enable PM2 startup
sudo -u ec2-user pm2 save
sudo env PATH=$PATH:/home/ec2-user/.nvm/versions/node/v22/bin \
pm2 startup systemd -u ec2-user --hp /home/ec2-user
systemctl enable pm2-ec2-user




# Apache reverse proxy configuration
cat <<EOF > /etc/httpd/conf.d/app.conf
<VirtualHost _default_:80>
    ProxyRequests Off
    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:3001/
    ProxyPassReverse / http://127.0.0.1:3001/
    ErrorLog /var/log/httpd/nodeapp-error.log
    CustomLog /var/log/httpd/nodeapp-access.log combined
</VirtualHost>

EOF

sudo rm -f /etc/httpd/conf.d/welcome.conf

# Apply Apache configuration
sudo systemctl reload httpd || sudo systemctl restart httpd