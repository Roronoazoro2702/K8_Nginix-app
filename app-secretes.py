#!/usr/bin/env python3
# Application with embedded secrets - FOR TESTING PURPOSES ONLY
# This file contains intentional secrets for TruffleHog scanner testing

import os
import json
import requests
import boto3
import mysql.connector
from google.cloud import storage
from github import Github
from azure.identity import ClientSecretCredential
from stripe import Stripe

# Hardcoded AWS credentials
AWS_ACCESS_KEY = "AKIAIOSFODNN7EXAMPLE"
AWS_SECRET_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
AWS_ACCOUNT_ID = "123456789012"

# AWS Session token
AWS_SESSION_TOKEN = "AQoDYXdzEJr1K...EXAMPLETOKEN"

# Database credentials
DB_USERNAME = "admin"
DB_PASSWORD = "MySup3r$ecretP@ssw0rd!"
DB_HOST = "database.example.com"
DB_NAME = "production_db"

# Connection string with embedded credentials
MYSQL_CONNECTION = "mysql://root:password123@localhost:3306/mydatabase"
POSTGRES_URL = "postgresql://postgres:admin123@postgres.example.com:5432/production"
MONGO_URI = "mongodb+srv://admin:S3cretP%40ss!@mongodb.example.com/production?retryWrites=true&w=majority"

# API keys and tokens
GITHUB_TOKEN = "ghp_aBcDeFgHiJkLmNoPqRsTuVwXyZ0123456789"
GITHUB_SSH_KEY = """-----BEGIN OPENSSH PRIVATE KEY-----
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
-----END OPENSSH PRIVATE KEY-----"""

STRIPE_API_KEY = "sk_live_51HV3MBNwfEYasKTOXtf90p6rVm"
STRIPE_PUBLISHABLE_KEY = "pk_live_51HV3MBNwfEYasKTOXtf90p6rVm"

TWILIO_ACCOUNT_SID = "AC0123456789abcdef0123456789abcdef"
TWILIO_AUTH_TOKEN = "0123456789abcdef0123456789abcdef"

# Google Cloud
GOOGLE_API_KEY = "AIzaSyDZT0FgPxYpuYSdDFI9JhxDYCqXGFSPVkw"
GOOGLE_CLIENT_ID = "012345678901-abcdefghijklmnopqrstuvwxyz.apps.googleusercontent.com"
GOOGLE_CLIENT_SECRET = "GOCSPX-abcdefghijklmnopqrstuvwxyz"

# Azure credentials
AZURE_CONNECTION_STRING = "DefaultEndpointsProtocol=https;AccountName=mystorageaccount;AccountKey=0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ+/=;EndpointSuffix=core.windows.net"
AZURE_TENANT_ID = "01234567-89ab-cdef-0123-456789abcdef"
AZURE_CLIENT_ID = "01234567-89ab-cdef-0123-456789abcdef"
AZURE_CLIENT_SECRET = "Q~abcdefghijklmnopqrstuvwxyz0123456789ABCDEF"

# Slack
SLACK_BOT_TOKEN = "xoxb-0123456789012-0123456789012-abcdefghijklmnopqrstuvwx"
SLACK_APP_TOKEN = "xapp-1-ABCDEFGHIJKLMNOPQRSTUVWX-0123456789012-abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

# JWT tokens
JWT_SECRET = "jwt_super_secret_key_for_signing_tokens_1234567890"
AUTH_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"

# Private RSA Key
RSA_PRIVATE_KEY = """-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEAqAkL/hWh5AnHgj6IxOgFFkyPKmfAiKgQPHJVKzTX/OFdMUFH
Jte92bXTm3vH8JQtJOjPH1XVfG7/UwcBgxe5NlGgXbDwA+nT36gQm/BjLYMP3UiX
7RKhnlKn7xjIH8nDG9jIK0XBFSjXgLrZpvZPwA1CmZ5FxAct0iRJ0SUwOWg8i4zl
IDKdU4niaj67eXYPuJ631qXYYy94tGQhgI20xXnMNDIKgQfSBbP0yxbaTlYvrFE2
o2DQPgMJ6jQduXCgcl4eEqDusVkPFIcjUTv+TdYoQQe1GaIPoywjIGRBkcWrTDQw
tPGVdMdWxsXD62K1IQvD82+mYqLxGxNrMgjQiwIDAQABAoIBAE9ocnKeCuXqZ75+
brOj6yBS8t3AWv8ngFsyTjN8aiJ+1AkxOCyXOzQS6BiitJBLNl7cX6aZk95JFESL
FyEpSK2ozPrDd5ZfWJPZ1rD0YMW4D5HZvn2xNHFnvGQohtk8JVJqPQnyCQTBRZz1
JHkCyTYH8Q6lPBLJKCJQm9Uf+iYV3Vy8KR0lK8w3qzMmK1sGkQsKZTZQPtVFmGOc
8oJ/ofC48NvMFBLgx8L8QBKevByCszCG9EGPpK5KQx/LHW1k3vHkYDcCjEZXzfAD
GZXCJhJBALYP6YI+FUbdH0RCGKPKzWb9c4sZPpbBHfhIZAgPUJQNWXzEkgy2ULJs
AiGY/ikCgYEA1OeZ+tzCdXyJYvYoMcj4xrT0DVk7CmRHdC5Ub6K3tIXI2hZ5IFlO
cCSLjeIkAqX0MvkiSKyG2DvJFqT98TZ1EYsQiDUxl7vbKhFZG3IzdFPvuyyUBGDR
8oayUG6IlH3Y04E7QPCnXvZPYUuiENFIQwiLvbWLaXX37Tx2JkrCBB0CgYEAykzW
D/x8zXzGTjpgvYe1oFnCCRIzJBYyEQ5J5XrLfuZ+ZdE9NtWoyo6/KKpRQl0lqFAY
sjlvQjRgqjY+zYCyzht3AtQC7vyDWeNx5FnzZ9E6EB2tyn7AmdOXeozZJlf9U1Yk
i4Kc8l7AUW0/5ZMgKeBZxCMkJZlCyBsJn0PYuCcCgYBmCqH05I+g4KmA0KpaRFnl
ZhRP4aKLRGjEyVgZlS1Mwz9LrJVMqW9i1z+iFeNcJbIggI6nAzn0xzYZyMoxUCKL
i1O8V8JZmzAYyc8ISmpQpXnbUGi/o4qXqKszVcqlIUGtQZvQQTzlLSfzrBizhOVl
SXNuUcXi5v2KKQ1GOWkC5QKBgAf4Eu0LZGdmuAHXFNWfzYZOjZz5yI+7VoHm8VZs
1a1GeFrJa6JcSwxNxOYVMLPuDXBuCj2Q78HwAijzCsd1QmJLHdtmZAYW8fCmDfBi
ePZEHCfLgYvQgGk5V8TqjKQTnaqG8fFwxJBYe8WklLCipptxwG8/aLQTjOmFFkGl
QCL5AoGACHcb7RqTFwPxJWeSP8iqg4SjnMyD5cJKd9iKCFwRzaVCU3XQlOuGjGHD
vExo1IF4W5JtCY0TX9qU6yzUG2+AXkfIUFQc7Qx/Qop9HQeG86FoHUheRkxaJt8j
FtcFWEzPJT1JLCFxMY0J1CqFSQlLtfBJG+lN3nbCKu1tFQzFnAs=
-----END RSA PRIVATE KEY-----"""

# Base64 encoded certificate
SSL_CERTIFICATE = """LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURrekNDQW51Z0F3SUJBZ0lVZEdWNU5H
RmtNVFE0TldFMU1qQXlPREF3TWpBd0RRWUpLb1pJaHZjTkFRRUwKQlFBd1dURUxNQWtHQTFV
RUJoTUNWVk14RVRBUEJnTlZCQWdNQ0VOaGJHbG1iM0p1YVRFVE1CRUdBMVVFQnd3SwpVMkZ1
SUVaeVlXNWphWE5qYnpFUk1BOEdBMVVFQ2d3SVJYaGhiWEJzWlRFUE1BMEdBMVVFQ3d3R1RX
RnVZV2RsCk1CNFhEVEl6TURreE5qRTJNVE13TUZvWERUSTBNRGt4TlRFMk1UTXdNRm93V1RF
TE1Ba0dBMVVFQmhNQ1ZWTXgKRVRBUEJnTlZCQWdNQ0VOaGJHbG1iM0p1YVRFVE1CRUdBMVVF
Qnd3S1UyRnVJRVp5WVc1amFYTmpiekVSTUE4RwpBMVVFQ2d3SVJYaGhiWEJzWlRFUE1BMEdB
MVVFQ3d3R1RXRnVZV2RsTUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGCkFBT0NBUThBTUlJQkNn
S0NBUUVBdXdKR1pzSHB3ZjU0bjZEK21tK3pyU0lJcnVsUWFWSkovRUF4V2xFaktCTHgKY1BJ
QVNlV05GQlRlQWk5YkR5RG5vRk03SkQxU0tQd1gzK3YrQmU3azdPaEFEdEZLNUZ3b2ZBM0F3
Qy8wczBPMQoxNkZpTWlYZ2JQY3c1QVdCU0JVWmNXYmpjMk55dXQ2NWdPRHlzVlh4OFNIRXhZ
NmlGUjdHeFFpTjRxL0JWN2hWCk03aWtOaldLanRZYWtGNmNDRU41MENOcXpSZnhLQTlvSlFs
NXVGY0Yzb2pXbzQ0S3hnMnRibGFtU2d0RG0yc3oKWGZFbmtNaTRTOElnV1F5Q0E0c2lBUkpi
MytGckZUL2VjZWE1S2F0Y2x1SFhZcFJpK2UybUhVNFpUS1lrY3ZragplMVUzNGR2aFZ3eldu
d0lWSlYxbUZwRWM3K1cySCtSWnF3SURBUUFCbzFNd1VUQWRCZ05WSFE0RUZnUVVTcUJyCkF3
SjBFNUtHRlFvb2llK2FtUi94bWw4d0h3WURWUjBqQkJnd0ZvQVVTcUJyQXdKMEU1S0dGUW9v
aWUrYW1SCi94bWw4d0R3WURWUjBUQVFIL0JBVXdBd0VCL3pBTkJna3Foa2lHOXcwQkFRc0ZB
QU9DQVFFQUVqL3kzZExYClhhN05yNTExZHYwL05mVDBTVHJVVnphKytCdk1Fb25iTGsxZy9v
SzZtTnFQOGhTWDhZM0RQMVl5eHl1b05jZGoKMnZGK1loQzZwc1d0RGNsV3BtZFRNV3I0aVRH
N2EveURzQnFMbDZ2QnQxbW9sbVhXMlJSRWVFQ0VGU2ZBVlRPSwpTWVpQYmhTRlVIWGI4Z1p5
R1NLd2xCT0JiajkwR0NPZ2tYSDdqMm5WaFZaVVJpZWZGTkRTclpLY0taRXJUSWVFCnRDNVlV
anBHUU5LYm1VYjlvTGNQUnRpV0txQlcxRnJpbjhSb3ZPVklWZTFIWENTTjBwYURYVEpYTDVX
OXpBUnEKQkk1VGpjSGh5enFZMU5md3crVm96ZmFIMWlPdU9oRjNEZ2hBZmJ6Sk90VDhKVW5j
a09tOXQwTUFEYW5ldUpsMApyTzRnblptdDBRPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0t
LQo="""

# Digital Ocean API Token
DO_API_TOKEN = "dop_v1_01234567890123456789012345678901234567890123456789012345"

# NPM token
NPM_TOKEN = "npm_0123456789abcdef0123456789abcdef01234567"

# Sample function with hardcoded credentials
def connect_to_database():
    # Hardcoded database credentials
    username = "dbadmin"
    password = "Sup3r$3cur3P@ssw0rd!"
    
    conn = mysql.connector.connect(
        host="production-db.example.com",
        user=username,
        password=password,
        database="customer_data"
    )
    return conn

# Sample AWS S3 operation with hardcoded credentials
def upload_to_s3(file_path, bucket_name):
    s3_client = boto3.client(
        's3',
        aws_access_key_id='AKIAXVF3WDKZHGU7AB3X',
        aws_secret_access_key='t1I0QZSBrITvlrFUKkKvXqeSNvGvJ8d8kLiPWndZ'
    )
    s3_client.upload_file(file_path, bucket_name, os.path.basename(file_path))

# Sample OAuth Configuration
OAUTH_CONFIG = {
    'client_id': '01234567890-abcdefghijklmnopqrstuvwxyz',
    'client_secret': 'abcdefghijklmnopqrstuvwxyz01234567890',
    'redirect_uri': 'https://example.com/callback',
    'scope': 'read write',
    'auth_uri': 'https://provider.com/oauth2/auth',
    'token_uri': 'https://provider.com/oauth2/token'
}

# Firebase configuration
FIREBASE_CONFIG = {
    'apiKey': 'AIzaSyAbc123def456ghi789jkl012mno345pqr',
    'authDomain': 'project-id.firebaseapp.com',
    'databaseURL': 'https://project-id.firebaseio.com',
    'projectId': 'project-id',
    'storageBucket': 'project-id.appspot.com',
    'messagingSenderId': '123456789012',
    'appId': '1:123456789012:web:abc123def456ghi789jkl'
}

# Hidden in comments
# AWS key: AKIAIOSFODNN7EXAMPLE
# Secret: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

# Hidden in a multiline string
SECRET_CONFIG = """
{
  "api_key": "sk_test_51NZwobGZjG7VmCv9DmvWgQWIXwVygntS8",
  "webhook_secret": "whsec_0123456789abcdefghijklmnopqrstuvwxyz",
  "restricted_key": "rk_live_0123456789abcdefghijklmnopqrstuvwxyz",
  "admin_password": "h4ckm3if-y0u_c4n!"
}
"""

# Environment variable strings that might contain secrets
ENV_VARS = """
export MAILGUN_API_KEY=key-0123456789abcdef0123456789abcdef
export SENDGRID_API_KEY=SG.0123456789abcdef0123456789abcdef.0123456789abcdef0123456789abcdef
export JWT_SECRET=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
"""

if __name__ == "__main__":
    print("Starting application...")
    # Application code here
