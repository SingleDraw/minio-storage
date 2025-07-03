#!/bin/bash

# read environment variables from .env file
if [ -f .env ]; then
 set -a
 source .env
 set +a
else
 echo ".env file not found. Please create a .env file with the required variables."
 exit 1
fi

IFS=',' read -r -a users <<< "$USERS"
IFS=',' read -r -a passwords <<< "$PASSWORDS"

# Create users and buckets
for i in "${!users[@]}"; do
  user="${users[$i]}"
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
  echo "Creating user: $user with password: $password"

done

echo "Users and passwords have been read from the .env file."