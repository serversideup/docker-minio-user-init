#!/bin/bash
set -e

# Debug mode
if [ "$DEBUG" = "true" ]; then
    set -x
fi

echo "Starting health check..."

# Get policy name from path
minio_policy_name=$(basename "$MINIO_POLICY_PATH" .json | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]-_')
echo "Checking for policy: $minio_policy_name"

# Check if alias exists
echo "Checking MinIO alias..."
alias_list=$(mc alias list)
case "$alias_list" in
    *"$MINIO_ALIAS"*) 
        echo "✅ MinIO alias found"
        ;;
    *)
        echo "ERROR: MinIO alias $MINIO_ALIAS not found"
        exit 1
        ;;
esac

# Check if user exists
echo "Checking MinIO user..."
user_list=$(mc admin user ls "$MINIO_ALIAS")
case "$user_list" in
    *"$MINIO_USER_ACCESS_KEY"*)
        echo "✅ MinIO user found"
        ;;
    *)
        echo "ERROR: MinIO user $MINIO_USER_ACCESS_KEY not found"
        exit 1
        ;;
esac

# Check if policy exists
echo "Checking MinIO policy..."
policy_list=$(mc admin policy list "$MINIO_ALIAS")
case "$policy_list" in
    *"$minio_policy_name"*)
        echo "✅ MinIO policy found"
        ;;
    *)
        echo "ERROR: MinIO policy $minio_policy_name not found"
        exit 1
        ;;
esac

# Check if bucket exists
echo "Checking MinIO bucket..."
bucket_list=$(mc ls "$MINIO_ALIAS")
case "$bucket_list" in
    *"$MINIO_USER_BUCKET_NAME"*)
        echo "✅ MinIO bucket found"
        ;;
    *)
        echo "ERROR: MinIO bucket $MINIO_USER_BUCKET_NAME not found"
        exit 1
        ;;
esac

# All checks passed
echo "✅ Health check passed: User, policy, and bucket exist"
exit 0
