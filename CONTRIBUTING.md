# Conventions d'équipe — novasphere-infra

1. Une branche par changement (`feat/...`, `fix/...`), jamais de commit direct sur `main`.
2. Toute modification passe par une pull request relue et approuvée par l'autre membre avant merge.
3. Le plan Terraform se lit intégralement avant tout `apply`.
4. Un tag Git par séance : `v5.<séance>.0`.
5. `.gitignore` non négociable, jamais modifié à la baisse : `*.tfstate`, `*.tfvars`, `*.pem`, `.env`, inventaires générés.
6. State partagé uniquement sur le backend S3 (`novasphere-tfstate-aha`), jamais de state local.
7. Verrouillage natif S3 (`use_lockfile = true`). `dynamodb_table` est déprécié par HashiCorp : on le reconnaît, on ne l'utilise pas.
8. Jamais de `terraform force-unlock` sans avoir vérifié avec l'équipe que personne n'a d'opération en cours.
9. Aucun secret en clair : ni dans le code, ni dans le state, ni dans user_data, ni dans les logs.
10. Avant de quitter : `terraform destroy` ou `./scripts/stop-evening.sh`. ALB, NAT et ASG sont détruits tous les soirs sans exception.
