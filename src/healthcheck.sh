#!/bin/bash
set -e

# Debug mode
if [ "$DEBUG" = "true" ]; then
    set -x
fi

echo "Starting health check..."
echo "Checking for policy: $MINIO_POLICY_NAME"

# Check if user exists
echo "Checking MinIO user..."
user_json=$(mc admin user ls "$MINIO_ALIAS" --json)
# Extract accessKey from JSON using bash string manipulation
user_json=${user_json#*\"accessKey\":\"}
access_key=${user_json%%\"*}
if [ "$access_key" = "${MINIO_USER_ACCESS_KEY}" ]; then
    echo "✅ MinIO user found"
else
    echo "ERROR: MinIO user ${MINIO_USER_ACCESS_KEY} not found"
    exit 1
fi

# Check if policy exists
echo "Checking MinIO policy..."
policy_list=$(mc admin policy list "$MINIO_ALIAS")
case "$policy_list" in
    *"$MINIO_POLICY_NAME"*)
        echo "✅ MinIO policy found"
        ;;
    *)
        echo "ERROR: MinIO policy $MINIO_POLICY_NAME not found"
        exit 1
        ;;
esac

# Check if bucket exists
echo "Checking MinIO bucket..."
bucket_list=$(mc ls "$MINIO_ALIAS")
case "$bucket_list" in
    *"$MINIO_USER_BUCKET"*)
        echo "✅ MinIO bucket found"
        ;;
    *)
        echo "ERROR: MinIO bucket $MINIO_USER_BUCKET not found"
        exit 1
        ;;
esac

# All checks passed
echo "✅ Health check passed: User, policy, and bucket exist"
exit 0
