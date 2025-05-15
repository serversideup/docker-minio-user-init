#!/bin/bash
set -e
MINIO_ACCESS_KEY_EXISTS=${MINIO_ACCESS_KEY_EXISTS:-false}

# Debug
debug_flag=""
if [ "$DEBUG" = "true" ]; then
    debug_flag="--debug"
    set -x
fi

mc_cmd="mc $debug_flag"
################################################################################
# Functions
################################################################################

cleanup() {
    echo "Shutdown requested, exiting gracefully..."
    exit 0
}

debug_print() {
    if [ "$DEBUG" = "true" ]; then
        echo "$1"
    fi
}

sleep_or_exit() {
    if [ "$SLEEP" = "true" ]; then
        echo "✅ MinIO user, bucket, and policy created successfully. Sleeping indefinitely..."
        # Start a background process and wait for it
        # This will sleep until a signal is received
        sleep infinity &
        wait $!
    else
        echo "✅ MinIO user, bucket, and policy created successfully. Exiting..."
        exit 0
    fi
}

check_alias_exists() {
    local alias_list
    alias_list=$($mc_cmd alias list)
    case "$alias_list" in
        *"$MINIO_ALIAS"*) return 0 ;;
        *) return 1 ;;
    esac
}

check_policy_exists() {
    local policy_list
    policy_list=$($mc_cmd admin policy list)
    case "$policy_list" in
        *"$MINIO_POLICY_NAME"*) return 0 ;;
        *) return 1 ;;
    esac
}

################################################################################
# Main
################################################################################

# Support CTRL+C
trap cleanup TERM INT

if [ "$MINIO_ACCESS_KEY_EXISTS" = "true" ]; then
    echo "NOTICE: The access key \"$MINIO_USER_ACCESS_KEY\" already exists. No changes will be made."
    sleep_or_exit
fi

# Ensure alias is set
if ! check_alias_exists; then
    echo "ERROR: Alias $MINIO_ALIAS not found"
    exit 1
fi

# Ensure bucket exists
$mc_cmd mb "$MINIO_ALIAS/$MINIO_USER_BUCKET_NAME" --ignore-existing

# Create policy if it doesn't exist
if ! check_policy_exists; then
    echo "NOTICE: Policy $MINIO_POLICY_NAME not found. Creating..."
    $mc_cmd admin policy create "$MINIO_ALIAS" "$MINIO_POLICY_NAME" "$MINIO_POLICY_PATH"
fi

# Create user and apply policy
$mc_cmd admin user add "$MINIO_ALIAS" "$MINIO_USER_ACCESS_KEY" "$MINIO_USER_SECRET_KEY"
$mc_cmd admin policy attach "$MINIO_ALIAS" "$MINIO_POLICY_NAME" --user "$MINIO_USER_ACCESS_KEY"

# Sleep or exit
sleep_or_exit