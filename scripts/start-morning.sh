#!/usr/bin/env bash
# Redemarre l'instance web et regenere l'inventaire. Usage : ./scripts/start-morning.sh [dev|prod]
set -euo pipefail
ENV="${1:-dev}"
cd "$(dirname "$0")/../envs/$ENV"
ID=$(terraform output -raw web_instance_id)
aws ec2 start-instances --instance-ids "$ID" > /dev/null
aws ec2 wait instance-running --instance-ids "$ID"
terraform apply -refresh-only -auto-approve > /dev/null
terraform apply -auto-approve -target=local_file.inventory > /dev/null
echo "[$ENV] Instance $ID demarree. Nouvelle IP : $(terraform output -raw web_public_ip)"
