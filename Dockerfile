# Base image with known vulnerabilities - using an old Ubuntu version
FROM ubuntu:16.04

# Install vulnerable packages
RUN apt-get update && apt-get install -y \
    apache2=2.4.18-2ubuntu3.8 \
    mysql-server=5.7.33-0ubuntu0.16.04.1 \
    python=2.7.12-1~16.04 \
    python-pip=8.1.1-2ubuntu0.4 \
    openssh-server=1:7.2p2-4ubuntu2.8 \
    openssl=1.0.2g-1ubuntu4.15 \
    php7.0=7.0.33-0ubuntu0.16.04.16 \
    php7.0-mysql=7.0.33-0ubuntu0.16.04.16 \
    php7.0-xml=7.0.33-0ubuntu0.16.04.16 \
    php7.0-gd=7.0.33-0ubuntu0.16.04.16 \
    nodejs=4.2.6~dfsg-1ubuntu4.2 \
    npm=3.5.2-0ubuntu4 \
    nginx=1.10.3-0ubuntu0.16.04.5 \
    redis-server=2:3.0.6-1 \
    postgresql=9.5+173ubuntu0.2 \
    openjdk-8-jdk=8u292-b10-0ubuntu1~16.04.1 \
    curl=7.47.0-1ubuntu2.14 \
    wget=1.17.1-1ubuntu1.5 \
    vim=2:7.4.1689-3ubuntu1.3 \
    ruby=1:2.3.0+1 \
    ruby-dev=1:2.3.0+1 \
    --no-install-recommends

# Install vulnerable Python packages
RUN pip install \
    Django==1.8.18 \
    Flask==0.12.2 \
    Werkzeug==0.12.2 \
    requests==2.18.4 \
    cryptography==1.7.2 \
    PyYAML==3.12 \
    SQLAlchemy==1.1.11 \
    Jinja2==2.9.6

# Install vulnerable Ruby gems
RUN gem install \
    rails -v 4.2.7 \
    sinatra -v 1.4.7 \
    nokogiri -v 1.8.0 \
    rack -v 1.6.5

# Install vulnerable npm packages
RUN mkdir -p /app/node && cd /app/node && \
    npm init -y && \
    npm install --save \
    express@4.15.3 \
    moment@2.18.1 \
    lodash@4.17.4 \
    jquery@2.2.4 \
    bootstrap@3.3.7

# Configure vulnerable web server settings
RUN echo "SSLProtocol All -SSLv2 -SSLv3" >> /etc/apache2/apache2.conf && \
    echo "SSLCipherSuite HIGH:!aNULL:!MD5:!3DES" >> /etc/apache2/apache2.conf && \
    echo "server_tokens on;" >> /etc/nginx/nginx.conf

# Download known vulnerable application
RUN mkdir -p /var/www/html && \
    cd /var/www/html && \
    wget https://wordpress.org/wordpress-4.7.5.tar.gz && \
    tar -xzf wordpress-4.7.5.tar.gz && \
    rm wordpress-4.7.5.tar.gz

# Create large dummy files to reach 1GB size
RUN dd if=/dev/urandom of=/large_file_1.bin bs=1M count=300 && \
    dd if=/dev/urandom of=/large_file_2.bin bs=1M count=300 && \
    dd if=/dev/urandom of=/large_file_3.bin bs=1M count=300 && \
    dd if=/dev/urandom of=/large_file_4.bin bs=1M count=100

# Create a vulnerable PHP file (without embedded secrets)
RUN echo '<?php\n\
// Vulnerable code with SQL injection flaw\n\
function get_user($username) {\n\
    $db = new mysqli("localhost", "root", "password", "users");\n\
    $query = "SELECT * FROM users WHERE username = \'" . $username . "\'";\n\
    return $db->query($query);\n\
}\n\
\n\
// Vulnerable code with command injection flaw\n\
function ping_host($host) {\n\
    system("ping -c 1 " . $host);\n\
}\n\
\n\
// Vulnerable code with XSS flaw\n\
function display_comment($comment) {\n\
    echo "<div>" . $comment . "</div>";\n\
}\n\
?>' > /var/www/html/vulnerable.php

# Default command
CMD ["bash"]
