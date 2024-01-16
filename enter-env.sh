#!/usr/bin/env nix-shell
#!nix-shell --arg config "{ allowUnfree = true; }" -i bash -I nixpkgs=channel:nixos-unstable-small -p bashInteractive vault awscli jq openssh

set -eu

scratch=$(mktemp -d -t tmp.XXXXXXXXXX)
function finish {
  rm -rf "$scratch"
  if [ "x${VAULT_EXIT_ACCESSOR:-}" != "x" ]; then
    echo "--> Revoking my token ..." >&2
    vault token revoke -self || true
  fi
}
trap finish EXIT

echo "--> Assuming role: nix-community-aarch64-builder-deployers" >&2
vault_creds=$(vault token create \
	-display-name=nix-community-aarch64-builder \
	-format=json \
	-role nix-community-aarch64-builder-deployers)

VAULT_EXIT_ACCESSOR=$(jq -r .auth.accessor <<<"$vault_creds")
expiration_ts=$(($(date '+%s') + "$(jq -r .auth.lease_duration<<<"$vault_creds")"))
export VAULT_TOKEN=$(jq -r .auth.client_token <<<"$vault_creds")

echo "--> Setting variables: PACKET_AUTH_TOKEN" >&2
export PACKET_AUTH_TOKEN=$(vault kv get -field api_key_token packet/creds/nixos-foundation)

echo "--> Signing SSH key deploy.key.pub -> deploy.key-cert.pub" >&2
if [ ! -f deploy.key ]; then
  ssh-keygen -t rsa -f deploy.key -N ""
fi

echo "--> Setting variables: SSH_IDENTITY_FILE, SSH_USER, NIX_SSHOPTS" >&2
vault write -field=signed_key \
  ssh-keys/sign/netboot public_key=@./deploy.key.pub > deploy.key-cert.pub
export SSH_IDENTITY_FILE=$(pwd)/deploy.key
export SSH_USER=root
export NIX_SSHOPTS="-i $SSH_IDENTITY_FILE"

if [ "x${1:-}" == "x" ]; then

cat <<BASH > "$scratch/bashrc"
vault_prompt() {
  remaining=\$(( $expiration_ts - \$(date '+%s')))
  if [ \$remaining -gt 0 ]; then
    PS1='\n\[\033[01;32m\][TTL:\${remaining}s:\w]\$\[\033[0m\] ';
  else
    remaining=expired
    PS1='\n\[\033[01;33m\][\$remaining:\w]\$\[\033[0m\] ';
  fi
}
PROMPT_COMMAND=vault_prompt
BASH

bash --init-file "$scratch/bashrc"
else
  "$@"
fi

