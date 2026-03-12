# Requirements Document

## Introduction

Este documento define los requisitos para configurar una cuenta de AWS nueva con las mejores prácticas de seguridad, utilizando EXCLUSIVAMENTE servicios 100% gratuitos. La cuenta será utilizada para pruebas, proyectos personales de IA y desarrollo web, con presupuesto $0 y alerta a $5 USD. Se utiliza Terraform para Infrastructure as Code y se prioriza IAM Identity Center (SSO) para gobierno de accesos.

## Glossary

- **Root_Account**: La cuenta principal de AWS con acceso completo a todos los recursos
- **IAM_User**: Usuario de Identity and Access Management con permisos específicos
- **IAM_Identity_Center**: Servicio de AWS para gestión centralizada de acceso (anteriormente AWS SSO)
- **MFA_Device**: Dispositivo de autenticación multifactor (virtual o hardware)
- **Budget_Alert**: Alerta de AWS Budgets que notifica cuando se exceden umbrales de gasto
- **CloudTrail**: Servicio de AWS que registra todas las llamadas a la API (primer trail gratis)
- **IAM_Role**: Rol de IAM que puede ser asumido por usuarios o servicios
- **Terraform_State**: Archivo que mantiene el estado de la infraestructura gestionada por Terraform
- **Free_Tier**: Capa gratuita de AWS con límites específicos por servicio
- **SNS_Topic**: Tema de Simple Notification Service para envío de notificaciones
- **Permission_Set**: Conjunto de permisos en IAM Identity Center que define acceso a recursos

## Requirements

### Requirement 1: Protección de la Cuenta Root

**User Story:** Como administrador de la cuenta, quiero proteger la cuenta root con MFA y limitar su uso, para que la cuenta tenga la máxima seguridad posible.

#### Acceptance Criteria

1. THE Root_Account SHALL have MFA_Device enabled
2. WHEN Root_Account credentials are used, THE CloudTrail SHALL log the access event
3. THE Root_Account SHALL NOT be used for daily operations
4. THE IAM_User SHALL be created for administrative tasks

### Requirement 2: Gestión de Accesos con IAM Identity Center

**User Story:** Como administrador, quiero utilizar IAM Identity Center (SSO) para gestionar accesos de forma centralizada y segura, para que tenga mejor gobierno y experiencia de usuario sin costos adicionales.

#### Acceptance Criteria

1. THE IAM_Identity_Center SHALL be enabled in the AWS account
2. THE IAM_Identity_Center SHALL be configured with at least one administrative user
3. THE Permission_Set SHALL be created for administrative access
4. THE Permission_Set SHALL be created for developer access with limited permissions
5. THE Permission_Set SHALL be created for read-only access
6. WHEN a user accesses AWS, THE IAM_Identity_Center SHALL enforce MFA_Device
7. THE IAM_Identity_Center SHALL use AWS managed directory for user storage
8. WHERE programmatic access is needed, THE IAM_Role SHALL be used instead of IAM access keys

### Requirement 3: Auditoría con CloudTrail

**User Story:** Como administrador, quiero registrar todas las actividades de la API en la cuenta, para que pueda auditar accesos y cambios sin incurrir en costos.

#### Acceptance Criteria

1. THE CloudTrail SHALL be enabled with one trail for management events (free tier)
2. THE CloudTrail SHALL log all management events to S3 bucket
3. THE CloudTrail SHALL have log file validation enabled
4. THE CloudTrail SHALL be configured for all regions
5. THE S3 bucket for CloudTrail logs SHALL have versioning enabled
6. THE S3 bucket for CloudTrail logs SHALL block public access
7. WHEN Root_Account is used, THE CloudTrail SHALL log the access event

### Requirement 4: Control de Costos con Presupuesto $0

**User Story:** Como usuario con presupuesto $0 y alerta a $5 USD, quiero configurar alertas de costos y monitorear la capa gratuita, para que no tenga gastos inesperados.

#### Acceptance Criteria

1. THE Budget_Alert SHALL be created with $0 budgeted amount
2. THE Budget_Alert SHALL notify when forecasted costs exceed $5 USD
3. THE Budget_Alert SHALL notify when actual costs reach $1 USD
4. THE Budget_Alert SHALL notify when actual costs reach $5 USD
5. THE SNS_Topic SHALL be created for budget notifications
6. THE Budget_Alert SHALL monitor Free_Tier usage for key services (S3, DynamoDB, CloudTrail)
7. WHEN Free_Tier limits reach 80%, THE System SHALL send notification via SNS_Topic

### Requirement 5: Configuración de Seguridad Básica

**User Story:** Como administrador de seguridad, quiero aplicar políticas de seguridad fundamentales sin costos, para que la cuenta tenga protecciones básicas.

#### Acceptance Criteria

1. THE System SHALL block public access to S3 buckets by default at account level
2. THE S3 buckets SHALL be encrypted with AES-256 (SSE-S3) by default
3. THE System SHALL enforce encryption in transit for all services
4. WHEN an EC2 instance is launched, THE System SHALL require it to use IMDSv2
5. THE IAM_Role SHALL be created for EC2 instances instead of embedding credentials
6. THE System SHALL enforce strong password policy for IAM users (minimum 14 characters, complexity requirements)

### Requirement 6: Gestión de Infraestructura como Código

**User Story:** Como ingeniero de infraestructura, quiero gestionar toda la configuración con Terraform usando servicios gratuitos, para que la infraestructura sea reproducible y versionada sin costos.

#### Acceptance Criteria

1. THE Terraform_State SHALL be stored in S3 bucket within free tier limits
2. THE S3 bucket for Terraform_State SHALL have versioning enabled
3. THE S3 bucket for Terraform_State SHALL be encrypted with AES-256 (SSE-S3)
4. THE Terraform_State SHALL use DynamoDB table for state locking (within free tier)
5. THE DynamoDB table SHALL use on-demand billing mode to stay within free tier
6. THE System SHALL version control all Terraform configurations in Git
7. THE System SHALL tag all resources with owner, environment, and project metadata
8. WHEN Terraform applies changes, THE System SHALL require plan review before apply

### Requirement 7: Retención de Logs y Auditoría

**User Story:** Como administrador, quiero retener logs de auditoría por tiempo suficiente, para que pueda investigar incidentes sin incurrir en costos de almacenamiento.

#### Acceptance Criteria

1. THE CloudTrail logs SHALL be retained for minimum 90 days in S3
2. THE S3 bucket containing CloudTrail logs SHALL have lifecycle policy to delete logs after 90 days
3. THE S3 bucket containing CloudTrail logs SHALL stay within free tier limits (5GB)
4. THE S3 bucket containing logs SHALL have versioning enabled
5. WHEN S3 storage approaches free tier limit, THE System SHALL send notification via SNS_Topic

### Requirement 8: Notificaciones y Alertas

**User Story:** Como administrador, quiero recibir notificaciones de eventos importantes de seguridad y costos usando servicios gratuitos, para que pueda responder rápidamente a incidentes.

#### Acceptance Criteria

1. THE System SHALL create SNS_Topic for security alerts (within free tier: 1000 notifications/month)
2. THE System SHALL create SNS_Topic for budget alerts
3. THE SNS_Topic SHALL use email protocol for notifications
4. WHEN Root_Account is used, THE System SHALL send notification via SNS_Topic
5. WHEN new IAM_User or IAM_Role is created, THE System SHALL send notification via SNS_Topic
6. WHEN Budget_Alert threshold is reached, THE System SHALL send notification via SNS_Topic
7. THE System SHALL stay within SNS free tier limits (1000 email notifications per month)

### Requirement 9: Preparación para Acceso Multi-Usuario

**User Story:** Como administrador, quiero preparar la cuenta para acceso multi-usuario usando IAM Identity Center, para que pueda agregar colaboradores fácilmente en el futuro sin costos adicionales.

#### Acceptance Criteria

1. THE IAM_Identity_Center SHALL support multiple users without additional cost
2. THE Permission_Set SHALL be created for Admin level access
3. THE Permission_Set SHALL be created for Developer level access
4. THE Permission_Set SHALL be created for ReadOnly level access
5. THE System SHALL document process for adding new users to IAM_Identity_Center
6. THE System SHALL enforce MFA_Device for all users in IAM_Identity_Center
7. WHERE external collaborators need temporary access, THE IAM_Role SHALL be created with trust policy

### Requirement 10: Documentación de Mejores Prácticas

**User Story:** Como administrador, quiero documentar las configuraciones y mejores prácticas implementadas, para que pueda mantener y mejorar la seguridad de la cuenta en el futuro.

#### Acceptance Criteria

1. THE System SHALL document all IAM_Identity_Center Permission_Set configurations
2. THE System SHALL document CloudTrail configuration and log retention policies
3. THE System SHALL document Budget_Alert thresholds and notification procedures
4. THE System SHALL document Terraform_State backend configuration
5. THE System SHALL document free tier limits for all services used
6. THE System SHALL create runbook for common administrative tasks
7. THE System SHALL document services excluded due to costs (Config, GuardDuty, Security Hub) for future phases
