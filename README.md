<p align="center">
		<img src="https://raw.githubusercontent.com/serversideup/docker-minio-user-init/main/.github/header.png" width="1200" alt="Docker Images Logo">
</p>
<p align="center">
	<a href="https://github.com/serversideup/docker-minio-user-init/actions/workflows/publish_docker-images-production.yml"><img alt="Build Status" src="https://img.shields.io/github/actions/workflow/status/serversideup/docker-minio-user-init/.github%2Fworkflows%2Fpublish_docker-images-production.yml" /></a>
	<a href="https://github.com/serversideup/docker-minio-user-init/blob/main/LICENSE" target="_blank"><img src="https://badgen.net/github/license/serversideup/docker-minio-user-init" alt="License"></a>
	<a href="https://github.com/sponsors/serversideup"><img src="https://badgen.net/badge/icon/Support%20Us?label=GitHub%20Sponsors&color=orange" alt="Support us"></a>
	<a href="https://community.serversideup.net"><img alt="Discourse users" src="https://img.shields.io/discourse/users?color=blue&server=https%3A%2F%2Fcommunity.serversideup.net"></a>
  <a href="https://serversideup.net/discord"><img alt="Discord" src="https://img.shields.io/discord/910287105714954251?color=blueviolet"></a>
</p>

# Minio User Init Docker Image
This image is used to initialize a user and a bucket in Minio. This project is very helpful when you need to automatically provision users in a new MinIO instance, similar to how you would initialize a database with MySQL, PostgreSQL, etc.

 It's based off the [official Minio "mc" image](https://hub.docker.com/r/minio/mc) with some modifications to make it more flexible and configurable.

| Docker Image | Size |
|-------------|------|
| [serversideup/minio-user-init](https://hub.docker.com/r/serversideup/minio-user-init) | ![Docker Image Size](https://img.shields.io/docker/image-size/serversideup/minio-user-init/latest?style=flat-square) |

## Features

- Automatic user creation and policy assignment in MinIO
- Dynamic policy generation based on bucket and object permissions
- Customizable configuration via environment variables
- Support for existing user detection
- Debug mode for troubleshooting
- Native Docker health checks to ensure everything is working

### Works great for orchestrated deployments

We designed this image to work great in orchestrated deployments like Kubernetes, Docker Swarm, or even in Github Actions. Look how simple the syntax is:

```yaml
  minio-user-init:
    image: serversideup/minio-user-init:latest
    environment:
      MINIO_ADMIN_USER: "${MINIO_ADMIN_USER}"
      MINIO_ADMIN_PASSWORD: "${MINIO_ADMIN_PASSWORD}"
      MINIO_ALIAS: "myminio"
      MINIO_HOST: "https://minio.example.com:9000"
      MINIO_USER_ACCESS_KEY: "myaccesskey"
      MINIO_USER_SECRET_KEY: "mysecretkey"
      MINIO_USER_BUCKET_NAME: "mybucket"
      MINIO_USER_BUCKET_PERMISSIONS: "s3:ListBucket,s3:GetBucketLocation"
      MINIO_USER_OBJECT_PERMISSIONS: "s3:PutObject,s3:GetObject"
```

## Environment Variables

The following environment variables can be used to customize the MinIO user initialization:

| Variable | Description |  Default |
|----------|-------------|---------|
| `MINIO_ADMIN_USER` | Admin username for MinIO. If you're deploying a new instance, it will likely be the same as your `MINIO_ROOT_USER` when you first deployed MinIO. | ⚠️ Required |
| `MINIO_ADMIN_PASSWORD` | Admin password for MinIO. If you're deploying a new instance, it will likely be the same as your `MINIO_ROOT_PASSWORD` when you first deployed MinIO. | ⚠️ Required |
| `MINIO_HOST` | MinIO server URL | ⚠️ Required |
| `MINIO_USER_ACCESS_KEY` | The access key that uniquely identifies the new user, similar to a username. | ⚠️ Required |
| `MINIO_USER_SECRET_KEY` | Secret key for the new user. This key should be unique, greater than 12 characters, and a complex mixture of characters, numerals, and symbols. | ⚠️ Required |
| `MINIO_USER_BUCKET_NAME` | Name of the bucket to create | ⚠️ Required |
| `MINIO_ALIAS` | Alias for the MinIO server | `minio` |
| `MINIO_USER_BUCKET_PERMISSIONS` | Comma-separated list of bucket permissions | `s3:ListBucket,s3:GetBucketLocation,s3:ListBucketMultipartUploads` |
| `MINIO_USER_OBJECT_PERMISSIONS` | Comma-separated list of object permissions | `s3:PutObject,s3:GetObject,s3:DeleteObject,s3:ListMultipartUploadParts,s3:AbortMultipartUpload` |
| `MINIO_POLICY_PATH` | Path to the policy file. This file will be created if it doesn't exist or you can provide your own JSON by mounting to the `/policies` directory. | `/policies/readwrite-bucket-${MINIO_USER_BUCKET_NAME}.json` |
| `MINIO_POLICY_NAME` | Name of the policy you want to create/update/overwrite in MinIO. If you don't provide this, we just use the file name of your policy (without the `.json`). | `basename "$MINIO_POLICY_PATH" .json` (and trimmed of any special characters) |
| `DEBUG` | Enable debug mode | `false` |
| `SLEEP` | Keep container running after initialization | `true` |

### Default Permissions
This policy provides the following permissions:
- **Bucket Level**: Ability to list the bucket contents and get its location
- **Object Level**: Ability to upload and download objects

You can customize these permissions by setting the `MINIO_USER_BUCKET_PERMISSIONS` and `MINIO_USER_OBJECT_PERMISSIONS` environment variables.

By default, we create a policy that looks like this:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:ListBucketMultipartUploads"
      ],
      "Resource": [
        "arn:aws:s3:::${MINIO_USER_BUCKET_NAME}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListMultipartUploadParts",
        "s3:AbortMultipartUpload"
      ],
      "Resource": [
        "arn:aws:s3:::${MINIO_USER_BUCKET_NAME}/*"
      ]
    }
  ]
}
```

## Usage

1. Pull the Docker image:
   ```sh
   docker pull serversideup/minio-user-init:latest
   ```

2. Run the container with the required environment variables:

   ```sh
   docker run --rm \
    -e MINIO_ADMIN_USER="admin" \
    -e MINIO_ADMIN_PASSWORD="adminpassword" \
    -e MINIO_HOST="http://minio:9000" \
    -e MINIO_USER_ACCESS_KEY="myaccesskey" \
    -e MINIO_USER_SECRET_KEY="mysecretkey" \
    -e MINIO_USER_BUCKET_NAME="mybucket" \
   serversideup/minio-user-init:latest
   ```

## Resources

- **[Discord](https://serversideup.net/discord)** for friendly support from the community and the team.
- **[GitHub](https://github.com/serversideup/docker-minio-user-init)** for source code, bug reports, and project management.
- **[Get Professional Help](https://serversideup.net/professional-support)** - Get video + screen-sharing help directly from the core contributors.

## Contributing

As an open-source project, we strive for transparency and collaboration in our development process. We greatly appreciate any contributions members of our community can provide. Whether you're fixing bugs, proposing features, improving documentation, or spreading awareness - your involvement strengthens the project.

- **Bug Report**: If you're experiencing an issue while using these images, please [create an issue](https://github.com/serversideup/docker-minio-user-init/issues/new/choose).
- **Security Report**: Report critical security issues via [our responsible disclosure policy](https://www.notion.so/Responsible-Disclosure-Policy-421a6a3be1714d388ebbadba7eebbdc8).

Need help getting started? Join our Discord community and we'll help you out!

<a href="https://serversideup.net/discord"><img src="https://serversideup.net/wp-content/themes/serversideup/images/open-source/join-discord.svg" title="Join Discord"></a>

## Our Sponsors
All of our software is free an open to the world. None of this can be brought to you without the financial backing of our sponsors.

<p align="center"><a href="https://github.com/sponsors/serversideup"><img src="https://521public.s3.amazonaws.com/serversideup/sponsors/sponsor-box.png" alt="Sponsors"></a></p>

### Black Level Sponsors
<a href="https://sevalla.com"><img src="https://serversideup.net/wp-content/uploads/2024/10/sponsor-image.png" alt="Sevalla" width="546px"></a>

#### Bronze Sponsors
<!-- bronze -->No bronze sponsors yet. <a href="https://github.com/sponsors/serversideup">Become a sponsor →</a><!-- bronze -->

#### Individual Supporters
<!-- supporters --><a href="https://github.com/GeekDougle"><img src="https://github.com/GeekDougle.png" width="40px" alt="GeekDougle" /></a>&nbsp;&nbsp;<a href="https://github.com/JQuilty"><img src="https://github.com/JQuilty.png" width="40px" alt="JQuilty" /></a>&nbsp;&nbsp;<a href="https://github.com/MaltMethodDev"><img src="https://github.com/MaltMethodDev.png" width="40px" alt="MaltMethodDev" /></a>&nbsp;&nbsp;<!-- supporters -->

## About Us
We're [Dan](https://twitter.com/danpastori) and [Jay](https://twitter.com/jaydrogers) - a two person team with a passion for open source products. We created [Server Side Up](https://serversideup.net) to help share what we learn.

<div align="center">

| <div align="center">Dan Pastori</div>                  | <div align="center">Jay Rogers</div>                                 |
| ----------------------------- | ------------------------------------------ |
| <div align="center"><a href="https://twitter.com/danpastori"><img src="https://serversideup.net/wp-content/uploads/2023/08/dan.jpg" title="Dan Pastori" width="150px"></a><br /><a href="https://twitter.com/danpastori"><img src="https://serversideup.net/wp-content/themes/serversideup/images/open-source/twitter.svg" title="Twitter" width="24px"></a><a href="https://github.com/danpastori"><img src="https://serversideup.net/wp-content/themes/serversideup/images/open-source/github.svg" title="GitHub" width="24px"></a></div>                        | <div align="center"><a href="https://twitter.com/jaydrogers"><img src="https://serversideup.net/wp-content/uploads/2023/08/jay.jpg" title="Jay Rogers" width="150px"></a><br /><a href="https://twitter.com/jaydrogers"><img src="https://serversideup.net/wp-content/themes/serversideup/images/open-source/twitter.svg" title="Twitter" width="24px"></a><a href="https://github.com/jaydrogers"><img src="https://serversideup.net/wp-content/themes/serversideup/images/open-source/github.svg" title="GitHub" width="24px"></a></div>                                       |

</div>

### Find us at:

* **📖 [Blog](https://serversideup.net)** - Get the latest guides and free courses on all things web/mobile development.
* **🙋 [Community](https://community.serversideup.net)** - Get friendly help from our community members.
* **🤵‍♂️ [Get Professional Help](https://serversideup.net/professional-support)** - Get video + screen-sharing support from the core contributors.
* **💻 [GitHub](https://github.com/serversideup)** - Check out our other open source projects.
* **📫 [Newsletter](https://serversideup.net/subscribe)** - Skip the algorithms and get quality content right to your inbox.
* **🐥 [Twitter](https://twitter.com/serversideup)** - You can also follow [Dan](https://twitter.com/danpastori) and [Jay](https://twitter.com/jaydrogers).
* **❤️ [Sponsor Us](https://github.com/sponsors/serversideup)** - Please consider sponsoring us so we can create more helpful resources.

## Our products
If you appreciate this project, be sure to check out our other projects.

### 📚 Books
- **[The Ultimate Guide to Building APIs & SPAs](https://serversideup.net/ultimate-guide-to-building-apis-and-spas-with-laravel-and-nuxt3/)**: Build web & mobile apps from the same codebase.
- **[Building Multi-Platform Browser Extensions](https://serversideup.net/building-multi-platform-browser-extensions/)**: Ship extensions to all browsers from the same codebase.

### 🛠️ Software-as-a-Service
- **[Bugflow](https://bugflow.io/)**: Get visual bug reports directly in GitHub, GitLab, and more.
- **[SelfHost Pro](https://selfhostpro.com/)**: Connect Stripe or Lemonsqueezy to a private docker registry for self-hosted apps.

### 🌍 Open Source
- **[AmplitudeJS](https://521dimensions.com/open-source/amplitudejs)**: Open-source HTML5 & JavaScript Web Audio Library.
- **[Spin](https://serversideup.net/open-source/spin/)**: Laravel Sail alternative for running Docker from development → production.
- **[Financial Freedom](https://github.com/serversideup/financial-freedom)**: Open source alternative to Mint, YNAB, & Monarch Money.
