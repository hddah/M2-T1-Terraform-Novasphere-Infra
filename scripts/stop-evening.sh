#!/usr/bin/env bash
# Stoppe l'instance web. Usage : ./scripts/stop-evening.sh [dev|prod]
set -euo pipefail
ENV="${1:-dev}"
cd "$(dirname "$0")/../envs/$ENV"
ID=$(terraform output -raw web_instance_id)
aws ec2 stop-instances --instance-ids "$ID" > /dev/null
echo "[$ENV] Instance $ID en cours d'arret. Detruire toute ressource facturee a l'heure (ALB, NAT, ASG)."
