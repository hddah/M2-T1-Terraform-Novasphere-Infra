# novasphere-infra

Infrastructure NovaSphere sur AWS, deployee avec Terraform, configuree avec Ansible.

## Prerequis

- Terraform >= 1.14, AWS CLI v2 (aws sts get-caller-identity repond), ansible-core 2.21 (Python 3.12+), Git
- Cle SSH : ssh-keygen -t ed25519 -f ~/.ssh/novasphere -N ""
- Bucket de state existant : novasphere-tfstate-aha (versionne, verrouillage natif)

## Structure

    envs/dev/    environnement dev  (state : novasphere/dev/terraform.tfstate)
    envs/prod/   environnement prod (state : novasphere/prod/terraform.tfstate)
    ansible/     playbook et role web
    scripts/     stop-evening.sh / start-morning.sh [dev|prod]

Module serveur : https://github.com/hddah/terraform-aws-ec2-server (version figee par ?ref=).

## Deployer un environnement

    cd envs/dev
    cp terraform.tfvars.example terraform.tfvars   # UNE SEULE FOIS, puis adapter owner
    terraform init
    terraform plan      # lire le plan en entier
    terraform apply

## Fin de seance

    terraform destroy   # dans chaque environnement deploye
