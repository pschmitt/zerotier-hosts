#!/usr/bin/env bash

usage() {
  echo "Usage: $(basename "$0") ARGS"
  echo
  echo "ARGS:"
  echo "  -a, --api       API endpoint to use (default: https://api.zerotier.com/api/v1)"
  echo "  -h, --help      Show this help"
  echo "  -n, --network   Network name to use (default: the first network)"
  echo "  -o, --output    Output file (default: stdout)"
  echo "  -s, --suffix    Suffix to append to hostnames (default: zt)"
  echo "  -t, --token     API token to use (default: read from $PWD/token)"
}

zt_api() {
  local api_host=${ZEROTIER_API_ENDPOINT:-https://api.zerotier.com/api/v1}
  local token=${ZEROTIER_API_TOKEN:-$(head -1 "$PWD/token")}

  if [[ -z "$token" ]]
  then
    echo "No API token set" >&2
    return 1
  fi

  local endpoint="$1"

  curl -fsSL \
    --header "Authorization: token $token" \
    "${api_host}/${endpoint}"
}

zt_network() {
  zt_api "network"
}

zt_first_network_id() {
  zt_network | jq -r '.[0].id'
}

zt_network_id() {
  local network_name="${1:-$ZEROTIER_NETWORK_NAME}"
  zt_network | jq -er --arg name "$network_name" '
    .[] | select(.config.name == $name) | .id'
}

zt_network_members() {
  local network_id="${1:-$(zt_first_network_id)}"
  zt_api "network/${network_id}/member"
}

zt_zone_file() {
  local network_id
  local suffix

  while [[ -n "$*" ]]
  do
    case "$1" in
      -n|--network|--network-id)
        network_id="$2"
        shift 2
        ;;
      -s|--suffix)
        suffix="$2"
        shift 2
        ;;
    esac
  done

  if [[ -n "$suffix" && "$suffix" != .* ]]
  then
    # prepend dot if not already present
    suffix=".$suffix"
  fi

  if [[ -z "$network_id" ]]
  then
    network_id="$(zt_first_network_id)"
  fi

  zt_network_members "$network_id" | jq -er --arg suffix "$suffix" '
    sort_by(.name) | .[] |
    select(.hidden == false) |
    .config.ipAssignments[0] + " " + .name + $suffix
  '
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  ZEROTIER_API_TOKEN="${ZEROTIER_API_TOKEN:-}"
  ZEROTIER_API_HOST="${ZEROTIER_API_HOST:-}"
  ZEROTIER_NETWORK_NAME="${ZEROTIER_NETWORK_NAME:-}"
  SUFFIX="${SUFFIX:-zt}"

  while [[ -n "$*" ]]
  do
    case "$1" in
      -a|--api|--api-endpoint)
        ZEROTIER_API_ENDPOINT="$2"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      -n|--network)
        ZEROTIER_NETWORK_NAME="$2"
        shift 2
        ;;
      -o|--output)
        OUTPUT="$2"
        shift 2
        ;;
      -s|--suffix)
        SUFFIX="$2"
        shift 2
        ;;
      -t|--token)
        ZEROTIER_API_TOKEN="$2"
        shift 2
        ;;
      *)
        echo "Unknown option: $1"
        usage >&2
        exit 2
        ;;
    esac
  done

  if [[ -n "$ZEROTIER_NETWORK_NAME" ]]
  then
    ZEROTIER_NETWORK_ID=$(zt_network_id "$ZEROTIER_NETWORK_NAME")
    if [[ -z "$ZEROTIER_NETWORK_ID" ]]
    then
      echo "Failed to find network with name '$ZEROTIER_NETWORK_NAME'" >&2
      exit 1
    fi
  fi

  if ! ZONEFILE=$(zt_zone_file --suffix "$SUFFIX" --network-id "$ZEROTIER_NETWORK_ID")
  then
    echo "Failed to generate zone file" >&2
    exit 1
  fi
  if [[ -n "$OUTPUT" && $OUTPUT != "-" ]]
  then
    echo "$ZONEFILE" > "$OUTPUT"
  else
    echo "$ZONEFILE"
  fi
fi
