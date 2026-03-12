# Implementation Plan: AWS Account Security Setup

## Overview

Implementación modular de Terraform para configurar seguridad en una cuenta AWS nueva, usando exclusivamente servicios 100% gratuitos. Las tareas siguen el orden de dependencias: bootstrap primero, luego módulos independientes (SNS, account-security), módulos dependientes (CloudTrail, Budgets, IAM Identity Center), root module, y finalmente tests.

## Tasks

- [x] 1. Bootstrap del backend de Terraform (S3 + DynamoDB)
  - [x] 1.1 Crear directorio `bootstrap/` con `main.tf`, `variables.tf` y `outputs.tf`
    - Crear recurso `aws_s3_bucket` para Terraform state con nombre `<account-id>-terraform-state-us-east-1`
    - Crear recurso `aws_s3_bucket_versioning` habilitado
    - Crear recurso `aws_s3_bucket_server_side_encryption_configuration` con AES-256
    - Crear recurso `aws_s3_bucket_public_access_block` con las 4 configuraciones en true
    - Crear recurso `aws_dynamodb_table` para state locking con partition key `LockID` y billing mode `PAY_PER_REQUEST`
    - Configurar provider AWS con región `us-east-1`
    - Incluir tags obligatorios: `ManagedBy`, `Project`, `Environment`
    - Outputs: bucket name, bucket ARN, DynamoDB table name
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.7_

- [x] 2. Módulo SNS para notificaciones
  - [x] 2.1 Crear módulo `modules/sns-notifications/` con `main.tf`, `variables.tf`, `outputs.tf` y `topics.tf`
    - Crear recurso `aws_sns_topic` para `security-alerts` con display name
    - Crear recurso `aws_sns_topic` para `budget-alerts` con display name
    - Crear recursos `aws_sns_topic_subscription` con protocolo email para cada topic
    - Crear `aws_sns_topic_policy` para permitir publicación desde CloudTrail y Budgets
    - Variables: `security_alert_emails`, `budget_alert_emails`, `account_id`, `aws_region`, `tags`
    - Outputs: security topic ARN, budget topic ARN
    - _Requirements: 8.1, 8.2, 8.3, 8.6, 8.7, 4.5_


- [x] 3. Módulo de políticas de seguridad a nivel de cuenta
  - [x] 3.1 Crear módulo `modules/account-security/` con `main.tf`, `variables.tf`, `outputs.tf`
    - Crear recurso `aws_s3_account_public_access_block` con las 4 configuraciones en true
    - Crear recurso `aws_iam_account_password_policy` con mínimo 14 caracteres, complejidad, expiración 90 días, prevención de reutilización de 5 passwords
    - Crear archivo `ec2-imdsv2.tf` con IAM policy que requiera IMDSv2 para instancias EC2
    - Variables: `tags`
    - Outputs: password policy status, S3 public access block status
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.6_

- [x] 4. Módulo CloudTrail con S3 bucket para logs
  - [x] 4.1 Crear módulo `modules/cloudtrail/` con `main.tf`, `variables.tf`, `outputs.tf`
    - Crear archivo `s3-bucket.tf` con:
      - `aws_s3_bucket` para CloudTrail logs con nombre `<account-id>-cloudtrail-logs-us-east-1`
      - `aws_s3_bucket_versioning` habilitado
      - `aws_s3_bucket_server_side_encryption_configuration` con AES-256
      - `aws_s3_bucket_public_access_block` con las 4 configuraciones en true
      - `aws_s3_bucket_lifecycle_configuration` para eliminar logs después de 90 días
      - `aws_s3_bucket_policy` para permitir escritura de CloudTrail
    - Crear archivo `trail.tf` con:
      - `aws_cloudtrail` con nombre `account-audit-trail`, multi-region, log file validation, management events
      - `enable_logging = true`, `is_multi_region_trail = true`, `include_global_service_events = true`
    - Variables: `account_id`, `aws_region`, `log_retention_days`, `tags`
    - Outputs: trail ARN, S3 bucket name, S3 bucket ARN
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 7.1, 7.2, 7.3, 7.4_

- [x] 5. Módulo AWS Budgets con alertas
  - [x] 5.1 Crear módulo `modules/budgets/` con `main.tf`, `variables.tf`, `outputs.tf`
    - Crear archivo `cost-budget.tf` con recurso `aws_budgets_budget` tipo COST:
      - Budget amount: $0.00 USD, monthly recurring
      - Alerta forecasted a $5 USD vinculada a SNS budget topic
      - Alerta actual a $1 USD vinculada a SNS budget topic
      - Alerta actual a $5 USD vinculada a SNS budget topic
    - Crear archivo `free-tier-budget.tf` con recurso `aws_budgets_budget` tipo USAGE:
      - Monitoreo de Free Tier para S3 y DynamoDB
      - Alerta al 80% del límite de Free Tier
    - Variables: `budget_sns_topic_arn`, `tags`
    - Outputs: cost budget name, free tier budget name
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.6, 4.7_


- [x] 6. Módulo IAM Identity Center con Permission Sets
  - [x] 6.1 Crear módulo `modules/iam-identity-center/` con `main.tf`, `variables.tf`, `outputs.tf`
    - Usar data source `aws_ssoadmin_instances` para obtener la instancia de Identity Center
    - Crear archivo `permission-sets.tf` con:
      - `aws_ssoadmin_permission_set` para Admin (session 4h) con `AdministratorAccess` managed policy
      - `aws_ssoadmin_permission_set` para Developer (session 8h) con `PowerUserAccess` managed policy e inline policy que deniegue IAM, organizations, budgets, cloudtrail changes
      - `aws_ssoadmin_permission_set` para ReadOnly (session 12h) con `ReadOnlyAccess` managed policy
      - `aws_ssoadmin_managed_policy_attachment` para cada permission set
      - `aws_ssoadmin_permission_set_inline_policy` para Developer
    - Variables: `tags`
    - Outputs: permission set ARNs para Admin, Developer, ReadOnly
    - _Requirements: 2.1, 2.3, 2.4, 2.5, 2.6, 2.7, 9.1, 9.2, 9.3, 9.4_

- [x] 7. Checkpoint - Validar módulos individuales
  - Ejecutar `terraform fmt -check -recursive` en todos los módulos
  - Ejecutar `terraform validate` en cada módulo
  - Ensure all tests pass, ask the user if questions arise.

- [x] 8. Configuración del root module
  - [x] 8.1 Crear `providers.tf` con configuración del provider AWS para `us-east-1` y versión mínima de Terraform
    - _Requirements: 6.6_

  - [x] 8.2 Crear `variables.tf` con todas las variables del root module
    - Variables: `aws_region`, `account_id`, `project_name`, `environment`, `budget_alert_emails`, `security_alert_emails`, `cloudtrail_log_retention_days`, `enable_mfa_enforcement`, `tags`
    - _Requirements: 6.7_

  - [x] 8.3 Crear `main.tf` que orqueste todos los módulos en orden de dependencias
    - Invocar módulo `sns-notifications` primero (sin dependencias)
    - Invocar módulo `account-security` (sin dependencias)
    - Invocar módulo `cloudtrail` pasando outputs de SNS si aplica
    - Invocar módulo `budgets` pasando `budget_sns_topic_arn` desde SNS
    - Invocar módulo `iam-identity-center`
    - Pasar tags comunes a todos los módulos
    - _Requirements: 6.6, 6.7_

  - [x] 8.4 Crear `outputs.tf` con outputs relevantes del root module
    - CloudTrail ARN, S3 bucket names, SNS topic ARNs, Permission Set ARNs, DynamoDB table name
    - _Requirements: 6.6_

  - [x] 8.5 Crear `backend.tf` con configuración del backend S3 remoto
    - Bucket, key, region, encrypt, dynamodb_table
    - Incluir comentario sobre proceso de bootstrap y migración de state
    - _Requirements: 6.1, 6.4_

  - [x] 8.6 Crear `terraform.tfvars.example` con valores de ejemplo para todas las variables
    - _Requirements: 6.6_


- [x] 9. Checkpoint - Validar configuración completa
  - Ejecutar `terraform fmt -check -recursive` en todo el proyecto
  - Ejecutar `terraform init -backend=false` y `terraform validate` en el root module
  - Ensure all tests pass, ask the user if questions arise.

- [x] 10. Unit tests con Terratest
  - [x] 10.1 Crear estructura de tests en `tests/` con `go.mod` y configuración de Go
    - Inicializar módulo Go con dependencias de Terratest y gopter
    - Crear archivo helper `tests/helpers.go` con funciones para parsear configuración de Terraform
    - _Requirements: 6.6_

  - [ ]* 10.2 Escribir unit tests para módulo CloudTrail
    - Validar que existe exactamente un trail configurado como multi-region
    - Validar log file validation habilitado
    - Validar S3 bucket con versioning, encryption AES-256, public access block, lifecycle 90 días
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 7.1, 7.2_

  - [ ]* 10.3 Escribir unit tests para módulo Budgets
    - Validar budget $0 con alertas forecasted $5, actual $1, actual $5
    - Validar free tier monitoring budget con alerta al 80%
    - Validar vinculación con SNS topic
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.6, 4.7_

  - [ ]* 10.4 Escribir unit tests para módulo Account Security
    - Validar S3 account public access block con 4 configuraciones en true
    - Validar IAM password policy con 14+ caracteres y complejidad
    - _Requirements: 5.1, 5.6_

  - [ ]* 10.5 Escribir unit tests para módulo IAM Identity Center
    - Validar 3 permission sets: Admin con AdministratorAccess, Developer con PowerUserAccess + inline deny, ReadOnly con ReadOnlyAccess
    - Validar session durations: 4h, 8h, 12h
    - _Requirements: 2.3, 2.4, 2.5_

  - [ ]* 10.6 Escribir unit tests para módulo SNS
    - Validar existencia de topics security-alerts y budget-alerts
    - Validar subscriptions con protocolo email
    - Validar topic policies para CloudTrail y Budgets
    - _Requirements: 8.1, 8.2, 8.3_

  - [ ]* 10.7 Escribir unit tests para bootstrap (S3 + DynamoDB)
    - Validar S3 bucket con versioning, encryption, public access block
    - Validar DynamoDB table con LockID partition key y PAY_PER_REQUEST billing
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 11. Property-based tests
  - [ ]* 11.1 Escribir property test para CloudTrail Management Events Coverage
    - **Property 1: CloudTrail Management Events Coverage**
    - Verificar que CloudTrail está configurado con `enable_logging=true`, `is_multi_region_trail=true`, `include_global_service_events=true`, management events incluidos
    - **Validates: Requirements 1.2, 3.7**

  - [ ]* 11.2 Escribir property test para S3 Bucket Encryption Enforcement
    - **Property 2: S3 Bucket Encryption Enforcement**
    - Para cada `aws_s3_bucket` en la configuración, verificar que existe `aws_s3_bucket_server_side_encryption_configuration` con algoritmo AES256
    - **Validates: Requirements 5.2, 6.3**

  - [ ]* 11.3 Escribir property test para Resource Tagging Compliance
    - **Property 3: Resource Tagging Compliance**
    - Para cada recurso taggable, verificar que contiene tags `ManagedBy`, `Project`, `Environment` con valores no vacíos
    - **Validates: Requirements 6.7**

- [x] 12. Static analysis y security scanning
  - [x] 12.1 Crear configuración de tflint en `.tflint.hcl`
    - Habilitar plugin AWS
    - Configurar regla `aws_resource_missing_tags` con tags obligatorios
    - _Requirements: 6.7_

  - [x] 12.2 Crear configuración de pre-commit en `.pre-commit-config.yaml`
    - Hooks: terraform_fmt, terraform_validate, terraform_tflint, terraform_tfsec
    - _Requirements: 6.6, 6.8_

- [x] 13. Documentación
  - [x] 13.1 Crear `README.md` principal del proyecto
    - Descripción del proyecto y objetivos
    - Prerequisitos (Terraform, AWS CLI, IAM Identity Center habilitado)
    - Instrucciones de bootstrap (paso a paso)
    - Instrucciones de deployment (init, plan, apply)
    - Estructura del proyecto y descripción de módulos
    - Límites de Free Tier para servicios usados
    - Servicios excluidos por costos (Config, GuardDuty, Security Hub)
    - Proceso para agregar nuevos usuarios a IAM Identity Center
    - Runbook de tareas administrativas comunes
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7, 9.5_

- [x] 14. Final checkpoint - Validación completa
  - Ejecutar `terraform fmt -check -recursive`
  - Ejecutar `terraform validate`
  - Ejecutar tflint y tfsec
  - Ejecutar unit tests y property tests
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Las tareas marcadas con `*` son opcionales y pueden omitirse para un MVP más rápido
- Cada tarea referencia requisitos específicos para trazabilidad
- Los checkpoints aseguran validación incremental
- El bootstrap debe ejecutarse primero con backend local, luego migrar a remoto
- IAM Identity Center debe estar habilitado manualmente antes de ejecutar el módulo correspondiente
- Las subscriptions de SNS requieren confirmación manual por email después del deployment
