#!/bin/sh

# Start MinIO in background
minio server /data --console-address ":9001" &

# Wait until MinIO is ready (retry until connection works)
until mc alias set myminio http://localhost:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" 2>/dev/null; do
  echo "Waiting for MinIO to start..."
  sleep 3
  # Clean up temporary policy file
  rm -f /tmp/"${user}policy.json"

done

# Clean up temporary policy files
rm -f /tmp/fullsharedpolicy.json /tmp/readonlysharedpolicy.json

echo "MinIO is ready."

# 0. Create MinIO client alias
mc alias set myminio http://localhost:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"

# 1. Create shared bucket
mc mb myminio/shared

# 2. Create policy for shared bucket
cat > /tmp/fullsharedpolicy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::shared"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::shared/*"
      ]
    }
  ]
}
EOF

cat > /tmp/readonlysharedpolicy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::shared"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::shared/*"
      ]
    }
  ]
}
EOF

mc admin policy create myminio fullsharedpolicy /tmp/fullsharedpolicy.json
mc admin policy create myminio readonlysharedpolicy /tmp/readonlysharedpolicy.json

# read USERS and PASSWORDS from .env file and create users and buckets
IFS=',' read -r -a users <<< "$USERS"
IFS=',' read -r -a passwords <<< "$PASSWORDS"

# Create users and buckets
for i in "${!users[@]}"; do

  user="${users[$i]}"
  # Convert username to lowercase for bucket naming (S3 requirement)
  user_lower=$(echo "$user" | tr '[:upper:]' '[:lower:]')

  if [ -z "$user" ]; then
      echo "User at index $i is empty. Skipping..."
      continue
  fi

  if [ ${#user} -lt 3 ]; then
      echo "User '$user' at index $i is less than 3 characters long. Skipping..."
      continue
  fi

  if [ -z "${passwords[$i]}" ]; then
      echo "Password for user '$user' at index $i is empty. Skipping..."
      continue
  fi

  if [ ${#passwords[$i]} -lt 8 ]; then
      echo "Password for user '$user' at index $i is less than 8 characters long. Skipping..."
      continue
  fi

  if ! [[ "$user" =~ ^[a-zA-Z0-9]+$ ]]; then
      echo "User '$user' at index $i contains invalid characters. Only alphanumeric are allowed. Skipping..."
      continue
  fi

  if ! [[ "${passwords[$i]}" =~ ^[a-zA-Z0-9]+$ ]]; then
      echo "Password for user '$user' at index $i contains invalid characters. Only alphanumeric are allowed. Skipping..."
      continue
  fi
  
  password="${passwords[$i]}"

  # anonymize password for logging
  echo "Creating user: $user with password: [REDACTED]"

  # Create user
  mc admin user add myminio "$user" "$password"

  # Create bucket for the user (using lowercase name)
  mc mb myminio/private-"$user_lower"

  # create owner policy for the user
  cat > /tmp/"${user}policy.json" <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::private-${user_lower}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "arn:aws:s3:::private-${user_lower}/*"
      ]
    }
  ]
}
EOF

  mc admin policy create myminio "${user}policy" /tmp/"${user}policy.json"

  # Attach policy to user
  mc admin policy attach myminio "${user}policy" --user="$user"

  # Attach shared policy to user
  # mc admin policy attach myminio fullsharedpolicy --user="$user"

  # Attach readonly shared policy to user
  mc admin policy attach myminio readonlysharedpolicy --user="$user"

done

echo "MinIO setup completed. All users, buckets, and policies have been created."

# Wait for the backgrounded MinIO process to continue running
wait