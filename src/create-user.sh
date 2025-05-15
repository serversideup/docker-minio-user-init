#!/bin/bash
set -e
MINIO_USER_EXISTS=${MINIO_USER_EXISTS:-false}

# Debug
debug_flag=""
if [ "$DEBUG" = "true" ]; then
    debug_flag="--debug"
    set -x
fi

mc_cmd="mc $debug_flag"
minio_policy_name=$(basename "$MINIO_POLICY_PATH" .json | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]-_')
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
        echo "NOTICE: Sleeping indefinitely..."
        sleep infinity
    else
        echo "NOTICE: Exiting..."
        exit 0
    fi
}

################################################################################
# Main
################################################################################

# Support CTRL+C
trap cleanup TERM INT

if [ "$MINIO_USER_EXISTS" = "true" ]; then
    echo "NOTICE: User $MINIO_USER_USERNAME already exists. No changes will be made."
    sleep_or_exit
fi

# Ensure alias is set
if ! $mc_cmd alias list | grep -q "$MINIO_ALIAS"; then
    echo "ERROR: Alias $MINIO_ALIAS not found"
    exit 1
fi

# Ensure bucket exists
$mc_cmd mb "$MINIO_ALIAS/$MINIO_BUCKET_NAME" --ignore-existing

# Create policy if it doesn't exist
if ! $mc_cmd admin policy list | grep -q "$minio_policy_name"; then
    echo "NOTICE: Policy $minio_policy_name not found. Creating..."
    $mc_cmd admin policy create "$MINIO_ALIAS" "$minio_policy_name" "$MINIO_POLICY_PATH"
fi

# Create user and apply policy
$mc_cmd admin user create "$MINIO_ALIAS" "$MINIO_USER_USERNAME" "$minio_policy_name"
$mc_cmd admin policy attach "$MINIO_ALIAS" "$minio_policy_name" "$MINIO_USER_USERNAME"

# Sleep or exit
sleep_or_exit