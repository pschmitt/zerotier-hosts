# zerotier-hosts

# Requirements

- [bash](https://www.gnu.org/software/bash/)
- [jq](https://stedolan.github.io/jq/)

# Installation

Just grab `zerotier-hosts.sh`, `chmod +x` it and go.

# Usage

```
zerotier-hosts.sh --token API_TOKEN [--network NETWORK_NAME] [--suffix SUFFIX]
```

See `zerotier-hosts.sh --help` for more information.

# OpenWRT setup

## CronJob

Setup a cronjob to run this periodically:

```shell
# Update zerotier hosts file ever hour
0 * * * * /usr/bin/zerotier-hosts.sh --suffix wg --output /tmp/hosts.zerotier
```
