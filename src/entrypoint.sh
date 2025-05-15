#!/bin/bash
set -e
MINIO_USER_EXISTS=false

if [ "$DEBUG" = "true" ]; then
    set -x
fi

################################################################################
# Functions
################################################################################

create_policy() {
    policy_path="$1"

    # Convert comma-separated permissions to JSON array format
    bucket_permissions=""
    object_permissions=""

    # Process bucket permissions
    if [ -n "$MINIO_USER_BUCKET_PERMISSIONS" ]; then
        IFS=',' read -r -a BUCKET_PERM_ARRAY <<< "$MINIO_USER_BUCKET_PERMISSIONS"
        for perm in "${BUCKET_PERM_ARRAY[@]}"; do
            # Trim whitespace
            perm=$(echo "$perm" | tr -d ' ')
            if [ -z "$bucket_permissions" ]; then
                bucket_permissions="\"$perm\""
            else
                bucket_permissions="$bucket_permissions, \"$perm\""
            fi
        done
    fi

    # Process object permissions
    if [ -n "$MINIO_USER_OBJECT_PERMISSIONS" ]; then
        IFS=',' read -r -a OBJECT_PERM_ARRAY <<< "$MINIO_USER_OBJECT_PERMISSIONS"
        for perm in "${OBJECT_PERM_ARRAY[@]}"; do
            # Trim whitespace
            perm=$(echo "$perm" | tr -d ' ')
            if [ -z "$object_permissions" ]; then
                object_permissions="\"$perm\""
            else
                object_permissions="$object_permissions, \"$perm\""
            fi
        done
    fi

    # Create policy JSON dynamically with the processed permissions
    cat > "$policy_path" << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        $bucket_permissions
      ],
      "Resource": [
        "arn:aws:s3:::$MINIO_USER_BUCKET_NAME"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        $object_permissions
      ],
      "Resource": [
        "arn:aws:s3:::$MINIO_USER_BUCKET_NAME/*"
      ]
    }
  ]
}
EOF
    
}

exit_and_execute_docker_command() {
    export MINIO_USER_EXISTS
    exec "$@"
}

debug_print() {
    if [ "$DEBUG" = "true" ]; then
        echo "$1"
    fi
}

validate_environment_variables() {
    # Validate required environment variables
    required_vars="
        MINIO_ADMIN_USER
        MINIO_ADMIN_PASSWORD
        MINIO_ALIAS
        MINIO_HOST
        MINIO_POLICY_PATH
        MINIO_USER_ACCESS_KEY
        MINIO_USER_BUCKET_NAME
        MINIO_USER_BUCKET_PERMISSIONS
        MINIO_USER_OBJECT_PERMISSIONS
        MINIO_USER_SECRET_KEY
        MINIO_USER_USERNAME
    "

    for var in $required_vars; do
        if [ -z "$(eval echo \$$var)" ]; then
            echo "Error: $var environment variable is not set"
            exit 1
        fi
    done

    # Ensure path ends in .json
    if [[ "$MINIO_POLICY_PATH" != *.json ]]; then
        echo "Error: MINIO_POLICY_PATH must end in .json"
        exit 1
    fi
}

set_mc_alias() {
    debug_print "Setting mc alias..."
    mc alias set "$MINIO_ALIAS" "$MINIO_HOST" "$MINIO_ADMIN_USER" "$MINIO_ADMIN_PASSWORD"
    debug_print "Set alias with: mc alias set $MINIO_ALIAS $MINIO_HOST $MINIO_ADMIN_USER **********"
}

validate_minio_connection() {
    debug_print "Validating MinIO connection..."
    if ! mc admin info "$MINIO_ALIAS" &>/dev/null; then
        echo "Error: Unable to connect to MinIO instance at $MINIO_HOST"
        echo "Please check the hostname and admin credentials"
        exit 1
    fi
    debug_print "Successfully connected to MinIO instance"
}

################################################################################
# Main
################################################################################

validate_environment_variables

cat <<"EOF"
 ____________________
< Let's initialize a MinIO user, eh? >
 --------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
EOF
echo "🌐 MinIO Host: $MINIO_HOST"
echo "🔑 MinIO Access Key: $MINIO_ACCESS_KEY"
echo "📝 Policy Path: $MINIO_POLICY_PATH"
echo "🛠️ MinIO Version:"
mc --version
echo "-----------------------------------------------------------"

set_mc_alias
validate_minio_connection

# Check to see if user exists
if mc admin user ls "$MINIO_ALIAS" | grep -q "$MINIO_USER_USERNAME"; then
    echo "NOTICE: Detected that user $MINIO_USER_USERNAME already exists."
    MINIO_USER_EXISTS=true
    exit_and_execute_docker_command "$@"
fi

if [ ! -f "$MINIO_POLICY_PATH" ]; then
    echo "Creating policy file: $MINIO_POLICY_PATH"
    create_policy "$MINIO_POLICY_PATH"
    if [ "$DEBUG" = "true" ]; then
        cat "$MINIO_POLICY_PATH"
    fi
else
    debug_print "Policy file already exists: $MINIO_POLICY_PATH"
fi

exit_and_execute_docker_command "$@"