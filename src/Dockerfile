# syntax=docker/dockerfile:1
# check=skip=SecretsUsedInArgOrEnv
FROM minio/mc:latest

ENV DEBUG=false \
    MINIO_ADMIN_USER='' \
    MINIO_ADMIN_PASSWORD='' \
    MINIO_ALIAS=minio \
    MINIO_HOST='' \
    MINIO_USER_ACCESS_KEY='' \
    MINIO_USER_BUCKET_NAME='' \
    MINIO_USER_BUCKET_PERMISSIONS='s3:ListBucket,s3:GetBucketLocation,s3:ListBucketMultipartUploads' \
    MINIO_USER_OBJECT_PERMISSIONS='s3:PutObject,s3:GetObject,s3:DeleteObject,s3:ListMultipartUploadParts,s3:AbortMultipartUpload' \
    MINIO_USER_SECRET_KEY='' \  
    MINIO_USER_ACCESS_KEY='' \
    SLEEP=true
    

RUN mkdir -p /policies
COPY --chmod=700 entrypoint.sh /entrypoint.sh
COPY --chmod=700 create-user.sh /create-user.sh
COPY --chmod=700 healthcheck.sh /healthcheck.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD ["/create-user.sh"]

HEALTHCHECK --interval=168h --timeout=10s --start-period=5s --retries=3 \
    CMD ["/healthcheck.sh"]