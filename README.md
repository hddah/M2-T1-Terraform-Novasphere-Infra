# novasphere-infra

Infrastructure de **NovaSphere** (startup SaaS fictive), gérée en Infrastructure as Code avec **Terraform**, **Ansible** et **GitHub Actions** sur **AWS**.

Projet fil rouge du module *Terraform et Automatisation du déploiement d'infrastructures dans le cloud* — Master Systèmes, Réseaux et Cloud Computing (Bac+5), ESGI Paris.

---

## État d'avancement

| Séance | Thème | Tag | Statut |
|---|---|---|---|
| Starter | EC2 Debian + Ansible, inventaire généré | — | ✅ |
| S1 | Backend S3 partagé, verrouillage natif, conventions | `v5.1.0` | ✅ |
| S2 | Module `ec2-server` (web + monitoring), publication Git | `v5.2.0` | ✅ |
| S3 | Environnements `dev` / `prod`, deux states, promotion | `v5.3.0` | ✅ |
| S4 | VPC 2 AZ, ALB, Launch Template, ASG | `v5.4.0` | ⬜ |
| S5 | Parameter Store, IAM moindre privilège, checkov | `v5.5.0` | ⬜ |
| S6 | `import`, `moved`, dérive, `removed` | `v5.6.0` | ⬜ |
| S7 | CI/CD GitHub Actions, OIDC, prod protégée | `v5.7.0` | ⬜ |
| Projet | Livraison finale (tag gelé) | — | ⬜ |

---

## Architecture actuelle

```
                    ┌────────────── AWS us-east-1 ──────────────┐
envs/dev  ──apply──►│ web (t3.micro)        monitoring           │
                    │ SG : 80 public, 22 + 9100 admin /32        │
envs/prod ──apply──►│ web (t3.small)        monitoring           │
                    └────────────────────────────────────────────┘

Module ec2-server : dépôt Git séparé, versionné par tag
  github.com/hddah/terraform-aws-ec2-server   (v1.0.0, v1.1.0)

States : s3://novasphere-tfstate-aha/
  ├── novasphere/dev/terraform.tfstate
  └── novasphere/prod/terraform.tfstate
  chiffrés, bucket versionné, verrouillage natif (use_lockfile)
```

**Choix dev/prod : répertoires plutôt que workspaces.** L'environnement ciblé est visible dans le chemin (`cd envs/prod` est un acte conscient), chaque environnement a sa propre clé de state et peut pointer sur une version différente du module.

---

## Prérequis

| Outil | Version |
|---|---|
| Terraform | ≥ 1.14 |
| AWS CLI | 2.x |
| ansible-core | 2.21 (Python ≥ 3.12) |
| Git | ≥ 2.30 |

Poste Linux, ou WSL2 Ubuntu 24.04 sous Windows (Ansible ne tourne pas nativement sous Windows).

### Accès AWS (AWS Academy Learner Lab)

1. Learner Lab → **Start Lab**, attendre le voyant vert.
2. **AWS Details** → **AWS CLI : Show** → copier le bloc dans `~/.aws/credentials`.
3. Vérifier : `aws sts get-caller-identity`

Le `aws_session_token` **change à chaque session** : à recopier à chaque Start Lab.
Régions autorisées : `us-east-1` (utilisée) et `us-west-2`.

---

## Déploiement de zéro

### 1. Cloner et générer la clé SSH

```bash
git clone https://github.com/hddah/M2-T1-Terraform-Novasphere-Infra.git novasphere-infra
cd novasphere-infra
ssh-keygen -t ed25519 -f ~/.ssh/novasphere -N ""
```

### 2. Bucket de state (déjà créé, à ne refaire que pour repartir d'un compte vierge)

```bash
aws s3api create-bucket --bucket novasphere-tfstate-aha --region us-east-1
aws s3api put-bucket-versioning --bucket novasphere-tfstate-aha \
  --versioning-configuration Status=Enabled
```

### 3. Déployer dev

```bash
cd envs/dev
cp terraform.tfvars.example terraform.tfvars   # une seule fois, puis adapter owner
terraform init
terraform plan -out=tfplan   # lire le plan en entier
terraform apply tfplan       # applique exactement le plan relu
rm tfplan
```

### 4. Déployer prod

Même procédure depuis `envs/prod` (son `terraform.tfvars.example` porte `environment = "prod"` et `instance_type = "t3.small"`).

`terraform.tfvars` n'est **jamais** commité (`.gitignore`).

### 5. Configurer et vérifier

```bash
cd ../../ansible
ansible-playbook -i inventory-dev.ini site.yml   # PLAY RECAP : failed=0, unreachable=0
ansible-playbook -i inventory-dev.ini site.yml   # 2e passage : changed=0 (idempotence)
curl http://$(cd ../envs/dev && terraform output -raw web_public_ip)
```

---

## Promotion d'un changement (dev → prod)

1. Modifier le module dans `terraform-aws-ec2-server`, publier un nouveau tag (`v1.x.0`).
2. Dans `envs/dev/main.tf`, passer `ref=v1.x.0` → `terraform init -upgrade`, `plan`, `apply`, tester.
3. Voir ce que la prod n'a pas encore :
```bash
   git diff --no-index -w envs/prod/main.tf envs/dev/main.tf
```
4. Reporter le même `ref` dans `envs/prod/main.tf` → `init -upgrade`, `plan` (lu attentivement), `apply`.

---

## Travail en équipe

- Aucun state local. Un nouveau membre fait `terraform init` puis `terraform plan` dans chaque env → plans vides.
- Verrouillage natif S3 (`use_lockfile = true`, Terraform ≥ 1.11). Le verrouillage DynamoDB, déprécié, n'est pas utilisé.
- Verrou bloqué : `terraform force-unlock <LOCK_ID>` **uniquement** après vérification avec l'équipe.
- Branches, revues et tags : voir [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Fin de journée

Instances à conserver pour le lendemain :

```bash
./scripts/stop-evening.sh dev      # le lendemain : ./scripts/start-morning.sh dev
./scripts/stop-evening.sh prod
```

Les ressources facturées à l'heure (ALB, NAT Gateway, ASG) se **détruisent** chaque soir, sans exception.

```bash
cd envs/dev  && terraform destroy
cd ../prod   && terraform destroy
```

Deux commandes, deux répertoires : un `destroy` dans `envs/dev` ne peut pas toucher la prod.

---

## Structure

```
envs/
  dev/    backend.tf, versions.tf, variables.tf, main.tf, outputs.tf, inventory.tftpl, terraform.tfvars.example
  prod/   idem, clé de state et variables propres
ansible/  site.yml, ansible.cfg, roles/web (tasks, handlers, templates, defaults)
scripts/  stop-evening.sh, start-morning.sh  (argument : dev | prod)
```

L'inventaire Ansible est généré par `terraform apply` depuis `inventory.tftpl`, un fichier par environnement (`ansible/inventory-dev.ini`, `ansible/inventory-prod.ini`) : aucune IP écrite à la main.

---

## Sécurité

Jamais versionnés (`.gitignore`) : `*.tfstate`, `terraform.tfvars`, `*.pem`, `.env`, `ansible/inventory*.ini`, `tfplan`, `.terraform/`.
Aucune clé AWS dans le dépôt : les credentials restent dans `~/.aws/credentials`.
Registre de sécurité : `SECURITE.md` (à partir de S5).
