# AWS Account Security Setup

Configuración automatizada de seguridad para cuentas AWS nuevas utilizando Terraform e Infrastructure as Code, con **$0 de costo** usando exclusivamente servicios del Free Tier.

## Objetivos del Proyecto

Este proyecto tiene como objetivos principales:

1. **Seguridad desde el inicio**: Implementar controles de seguridad fundamentales en cuentas AWS nuevas sin incurrir en costos
2. **Gobierno de accesos centralizado**: Utilizar IAM Identity Center (SSO) para gestión moderna de identidades y accesos
3. **Auditoría completa**: Registrar todas las actividades de la API con CloudTrail para compliance y troubleshooting
4. **Control de costos proactivo**: Monitorear gastos y uso de Free Tier con alertas tempranas
5. **Infraestructura reproducible**: Gestionar toda la configuración con Terraform para versionado y automatización
6. **Preparación para crecimiento**: Diseñar la arquitectura para escalar sin costos adicionales cuando se agreguen usuarios

## Descripción

Este proyecto implementa una configuración de seguridad completa para cuentas AWS que incluye:

- **IAM Identity Center (SSO)**: Gestión centralizada de acceso con 3 Permission Sets (Admin, Developer, ReadOnly)
- **CloudTrail**: Auditoría de todas las llamadas a la API (primer trail gratis)
- **AWS Budgets**: Alertas de costos a $1 y $5 USD, monitoreo de Free Tier
- **SNS Topics**: Notificaciones de seguridad y presupuesto
- **Políticas de Seguridad**: S3 block public access, password policy, IMDSv2 enforcement

## Prerequisitos

1. **Cuenta AWS**: Una cuenta AWS nueva o existente
2. **Terraform**: Versión >= 1.6.0
3. **AWS CLI**: Configurado con credenciales de administrador
4. **IAM Identity Center**: Debe estar habilitado manualmente en la cuenta AWS (no se puede habilitar via Terraform)
5. **Bootstrap**: El módulo bootstrap debe ejecutarse primero para crear el backend S3 y DynamoDB

## Estructura del Proyecto

```
.
├── main.tf                      # Orquestación de módulos
├── variables.tf                 # Variables de entrada
├── outputs.tf                   # Valores de salida
├── providers.tf                 # Configuración del provider AWS
├── backend.tf                   # Backend remoto S3 + DynamoDB
├── terraform.tfvars.example     # Ejemplo de variables
├── README.md                    # Esta documentación
├── bootstrap/                   # Módulo de bootstrap (ejecutar primero)
└── modules/                     # Módulos individuales
    ├── sns-notifications/
    ├── account-security/
    ├── cloudtrail/
    ├── budgets/
    └── iam-identity-center/
```

## Orden de Ejecución

## Instrucciones de Bootstrap (Primera Vez)

El proceso de bootstrap es necesario **solo la primera vez** para crear la infraestructura que almacenará el estado de Terraform (S3 bucket y DynamoDB table).

### ¿Por qué Bootstrap?

Terraform necesita almacenar su estado (qué recursos ha creado) en un lugar seguro y compartido. El módulo bootstrap crea:
- **S3 Bucket**: Para almacenar el archivo de estado de Terraform
- **DynamoDB Table**: Para bloquear el estado y prevenir modificaciones concurrentes

### Paso a Paso del Bootstrap

#### 1. Obtener tu AWS Account ID

```bash
# Opción 1: Usando AWS CLI
aws sts get-caller-identity --query Account --output text

# Opción 2: En la consola de AWS
# Ve a la esquina superior derecha, tu Account ID aparece en el menú
```

Anota este número de 12 dígitos, lo necesitarás en varios pasos.

#### 2. Configurar Variables del Bootstrap

```bash
# Navegar al directorio bootstrap
cd bootstrap

# Copiar el archivo de ejemplo
cp terraform.tfvars.example terraform.tfvars

# Editar con tu editor favorito
nano terraform.tfvars
# o
vim terraform.tfvars
```

Contenido de `terraform.tfvars`:
```hcl
account_id  = "123456789012"  # Reemplazar con tu Account ID
aws_region  = "us-east-1"     # O tu región preferida
environment = "production"
```

#### 3. Inicializar Terraform (Backend Local)

```bash
# Inicializar Terraform (descarga providers)
terraform init

# Verificar que todo está correcto
terraform validate
```

Deberías ver: `Success! The configuration is valid.`

#### 4. Revisar el Plan de Ejecución

```bash
# Ver qué recursos se crearán
terraform plan
```

Deberías ver que se crearán:
- 1 S3 bucket (para Terraform state)
- 1 S3 bucket versioning configuration
- 1 S3 bucket encryption configuration
- 1 S3 bucket public access block
- 1 DynamoDB table (para state locking)

**Total: 5 recursos**

#### 5. Aplicar la Configuración

```bash
# Crear los recursos
terraform apply

# Terraform preguntará: "Do you want to perform these actions?"
# Escribe: yes
```

Espera 30-60 segundos mientras se crean los recursos.

#### 6. Anotar los Outputs

Después del apply exitoso, verás outputs como:

```
Outputs:

dynamodb_table_name = "terraform-state-lock"
state_bucket_arn = "arn:aws:s3:::123456789012-terraform-state-us-east-1"
state_bucket_name = "123456789012-terraform-state-us-east-1"
```

**IMPORTANTE**: Anota el `state_bucket_name`, lo necesitarás en el siguiente paso.

#### 7. Verificar en AWS Console (Opcional)

Puedes verificar que los recursos se crearon:

```bash
# Verificar S3 bucket
aws s3 ls | grep terraform-state

# Verificar DynamoDB table
aws dynamodb list-tables | grep terraform-state-lock
```

#### 8. Volver al Directorio Raíz

```bash
cd ..
```

¡Bootstrap completado! Ahora puedes continuar con la configuración del backend remoto.

## Instrucciones de Deployment

Una vez completado el bootstrap, sigue estos pasos para desplegar la infraestructura de seguridad completa.

### Paso 1: Configurar Backend Remoto

Edita el archivo `backend.tf` en el directorio raíz con el nombre del bucket creado en el bootstrap:

```bash
# Editar backend.tf
nano backend.tf
```

Actualiza la línea del bucket con tu Account ID:

```hcl
terraform {
  backend "s3" {
    bucket         = "123456789012-terraform-state-us-east-1"  # ⬅️ Reemplazar con tu Account ID
    key            = "aws-account-security/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

### Paso 2: Configurar Variables

```bash
# Copiar el archivo de ejemplo
cp terraform.tfvars.example terraform.tfvars

# Editar con tus valores reales
nano terraform.tfvars
```

Ejemplo de `terraform.tfvars`:

```hcl
# AWS Configuration
account_id = "123456789012"  # Tu AWS Account ID
aws_region = "us-east-1"     # Tu región preferida

# Project Configuration
project_name = "aws-security-setup"
environment  = "production"

# Email Notifications
budget_alert_emails   = ["admin@example.com", "finance@example.com"]
security_alert_emails = ["security@example.com", "admin@example.com"]

# CloudTrail Configuration
cloudtrail_log_retention_days = 90  # 30-365 días

# IAM Identity Center
enable_mfa_enforcement = true  # Siempre recomendado

# Tags (opcional, personalizar según tu organización)
tags = {
  ManagedBy   = "Terraform"
  Project     = "AWS-Security-Setup"
  Environment = "Production"
  Owner       = "admin@example.com"
  CostCenter  = "Infrastructure"
}
```

**Variables Requeridas**:
- ✅ `account_id`: Tu AWS Account ID (12 dígitos)
- ✅ `budget_alert_emails`: Al menos un email válido
- ✅ `security_alert_emails`: Al menos un email válido

### Paso 3: Habilitar IAM Identity Center

**CRÍTICO**: IAM Identity Center debe habilitarse manualmente antes de ejecutar Terraform.

#### Habilitar via AWS Console:

1. Inicia sesión en AWS Console con credenciales de administrador
2. Navega a **IAM Identity Center** (busca "IAM Identity Center" o "SSO")
3. Si ves un botón "Enable", haz clic en él
4. Selecciona la región donde quieres habilitar Identity Center (recomendado: us-east-1)
5. Espera 1-2 minutos mientras se habilita
6. Verás la página principal de IAM Identity Center

#### Habilitar via AWS CLI:

```bash
# Verificar si ya está habilitado
aws sso-admin list-instances

# Si no está habilitado, debes hacerlo desde la consola
# (No hay comando CLI para habilitar IAM Identity Center)
```

#### Verificar que está Habilitado:

```bash
# Este comando debe devolver un Instance ARN
aws sso-admin list-instances --query 'Instances[0].InstanceArn' --output text
```

Si ves un ARN como `arn:aws:sso:::instance/ssoins-xxxxxxxxx`, está habilitado correctamente.

### Paso 4: Inicializar Terraform con Backend Remoto

```bash
# Inicializar Terraform (conectará con el backend S3)
terraform init

# Deberías ver: "Successfully configured the backend "s3"!"
```

Si ves un error, verifica:
- El nombre del bucket en `backend.tf` es correcto
- Tienes permisos para acceder al bucket S3
- La tabla DynamoDB existe

### Paso 5: Validar la Configuración

```bash
# Validar sintaxis
terraform validate

# Formatear código (opcional pero recomendado)
terraform fmt -recursive
```

### Paso 6: Revisar el Plan de Ejecución

```bash
# Generar y revisar el plan
terraform plan -out=tfplan

# Revisar detalladamente qué se creará
terraform show tfplan
```

Deberías ver que se crearán aproximadamente **20-25 recursos**:
- 2 SNS topics + subscriptions
- 1 CloudTrail trail + S3 bucket
- 2 AWS Budgets
- 3 IAM Identity Center Permission Sets
- Políticas de seguridad a nivel de cuenta
- Configuraciones de S3, lifecycle policies, etc.

**IMPORTANTE**: Revisa cuidadosamente que:
- No se están destruyendo recursos existentes
- Los emails son correctos
- El Account ID es correcto

### Paso 7: Aplicar la Configuración

```bash
# Aplicar el plan guardado
terraform apply tfplan

# O aplicar directamente (te pedirá confirmación)
terraform apply
```

El proceso tomará **2-5 minutos**. Verás el progreso en tiempo real.

### Paso 8: Verificar Outputs

Después del apply exitoso, verás outputs importantes:

```bash
# Ver todos los outputs
terraform output

# Ver un output específico
terraform output cloudtrail_arn
terraform output security_alerts_topic_arn
```

Guarda estos outputs para referencia futura.

### Paso 9: Confirmar Subscripciones SNS

**CRÍTICO**: Las notificaciones no funcionarán hasta que confirmes las subscripciones.

1. Revisa tu bandeja de entrada (y carpeta de spam)
2. Busca emails de "AWS Notifications" con asunto "AWS Notification - Subscription Confirmation"
3. Recibirás **2 emails** (uno para security alerts, otro para budget alerts)
4. Haz clic en "Confirm subscription" en cada email
5. Verás una página de confirmación en tu navegador

Verificar confirmación:

```bash
# Listar subscripciones de security alerts
aws sns list-subscriptions-by-topic \
  --topic-arn $(terraform output -raw security_alerts_topic_arn)

# Busca "SubscriptionArn" que NO sea "PendingConfirmation"
```

### Paso 10: Verificación Post-Deployment

Ejecuta estas verificaciones para asegurar que todo funciona:

```bash
# 1. Verificar CloudTrail está logging
aws cloudtrail get-trail-status --name account-audit-trail

# Deberías ver: "IsLogging": true

# 2. Verificar budgets
aws budgets describe-budgets --account-id $(terraform output -raw account_id)

# Deberías ver 2 budgets

# 3. Verificar S3 public access block
aws s3control get-public-access-block --account-id $(terraform output -raw account_id)

# Todas las opciones deben ser "true"

# 4. Verificar IAM password policy
aws iam get-account-password-policy

# Debe requerir 14+ caracteres

# 5. Listar Permission Sets
aws sso-admin list-permission-sets \
  --instance-arn $(aws sso-admin list-instances --query 'Instances[0].InstanceArn' --output text)

# Deberías ver 3 Permission Sets
```

### Paso 11: Crear Primer Usuario en IAM Identity Center

Ahora puedes crear tu primer usuario administrativo:

1. Ve a AWS Console → IAM Identity Center
2. Click en "Users" → "Add user"
3. Completa la información del usuario
4. Ve a "AWS accounts" → Selecciona tu cuenta
5. Click "Assign users or groups"
6. Selecciona tu usuario y asigna "AdminPermissionSet"
7. El usuario recibirá un email de invitación

### Troubleshooting del Deployment

**Error: "IAM Identity Center not enabled"**
```bash
# Solución: Habilita IAM Identity Center manualmente (ver Paso 3)
```

**Error: "Error acquiring the state lock"**
```bash
# Solución: Otro proceso está usando el state, espera o:
terraform force-unlock <lock-id>
```

**Error: "InvalidBucketName"**
```bash
# Solución: Verifica que el Account ID en terraform.tfvars es correcto
```

**Error: "Access Denied"**
```bash
# Solución: Verifica que tienes permisos de administrador
aws sts get-caller-identity
```

### Comandos Útiles Post-Deployment

```bash
# Ver estado actual
terraform show

# Ver outputs
terraform output

# Refrescar state (si hubo cambios manuales)
terraform refresh

# Ver recursos gestionados
terraform state list

# Ver detalles de un recurso específico
terraform state show aws_cloudtrail.main
```

¡Deployment completado! Tu cuenta AWS ahora tiene configuración de seguridad robusta con $0 de costo.

## Variables de Entrada

| Variable | Tipo | Descripción | Default | Requerido |
|----------|------|-------------|---------|-----------|
| `aws_region` | string | Región AWS | `us-east-1` | No |
| `account_id` | string | AWS Account ID (12 dígitos) | - | **Sí** |
| `project_name` | string | Nombre del proyecto | `aws-security-setup` | No |
| `environment` | string | Ambiente (production/staging/development) | `production` | No |
| `budget_alert_emails` | list(string) | Emails para alertas de presupuesto | - | **Sí** |
| `security_alert_emails` | list(string) | Emails para alertas de seguridad | - | **Sí** |
| `cloudtrail_log_retention_days` | number | Días de retención de logs (30-365) | `90` | No |
| `enable_mfa_enforcement` | bool | Forzar MFA en Identity Center | `true` | No |
| `tags` | map(string) | Tags comunes para todos los recursos | Ver ejemplo | No |

## Outputs

Después del deployment, Terraform mostrará:

- ARNs de CloudTrail y bucket S3 de logs
- ARNs de SNS topics (security y budget alerts)
- ARNs de Permission Sets de IAM Identity Center
- Nombres de budgets configurados
- Configuración de políticas de seguridad

## Módulos Incluidos

### 1. SNS Notifications
Crea topics SNS para alertas de seguridad y presupuesto con subscripciones por email.

### 2. Account Security
Configura políticas de seguridad a nivel de cuenta:
- S3 block public access (todas las opciones)
- IAM password policy (14+ caracteres, complejidad)
- EC2 IMDSv2 enforcement

### 3. CloudTrail
Configura auditoría de API calls:
- Trail multi-región
- Log file validation
- Retención de 90 días
- Bucket S3 encriptado y versionado

### 4. AWS Budgets
Monitoreo de costos:
- Budget de $0 con alertas a $1 y $5 USD
- Monitoreo de Free Tier (S3, DynamoDB)
- Alertas al 80% de uso de Free Tier

### 5. IAM Identity Center
Gestión centralizada de acceso:
- Admin Permission Set (AdministratorAccess)
- Developer Permission Set (PowerUserAccess con restricciones)
- ReadOnly Permission Set (ReadOnlyAccess)

## Límites de Free Tier

Este proyecto está diseñado para **$0 de costo** utilizando solo servicios dentro del Free Tier de AWS:

| Servicio | Límite Free Tier | Uso Estimado | Estado |
|----------|------------------|--------------|--------|
| CloudTrail | 1 trail gratis (management events) | 1 trail | ✅ Gratis |
| S3 | 5GB almacenamiento estándar | ~1-2GB logs/mes | ✅ Gratis |
| DynamoDB | 25GB almacenamiento, 25 WCU/RCU | <1MB, <1 WCU/RCU | ✅ Gratis |
| SNS | 1000 notificaciones email/mes | ~70 emails/mes | ✅ Gratis |
| AWS Budgets | 2 budgets gratis | 2 budgets | ✅ Gratis |
| IAM Identity Center | Ilimitado | N/A | ✅ Gratis |

**Alertas configuradas**:
- Alerta forecasted a $5 USD
- Alerta actual a $1 USD
- Alerta actual a $5 USD

### Servicios Excluidos por Costos

Los siguientes servicios NO están incluidos en este proyecto porque tienen costos después del período de prueba:

| Servicio | Razón de Exclusión | Consideración Futura |
|----------|-------------------|---------------------|
| AWS Config | No incluido en Free Tier permanente | Evaluar después de 30 días de prueba |
| Amazon GuardDuty | Costo después de 30 días de prueba | Considerar para cuentas de producción |
| AWS Security Hub | Costo después de 30 días de prueba | Considerar para compliance avanzado |
| AWS Organizations | No necesario para cuenta única | Útil para multi-cuenta en el futuro |
| Múltiples CloudTrail trails | Solo el primero es gratis | Suficiente con un trail multi-región |

**Nota**: Estos servicios pueden agregarse en el futuro si el presupuesto lo permite o durante períodos de prueba gratuita.

## Mantenimiento

### Actualizar Configuración

```bash
# Modificar archivos .tf según necesites
terraform plan
terraform apply
```

### Ver Estado Actual

```bash
terraform show
terraform output
```

### Destruir Infraestructura

```bash
# CUIDADO: Esto eliminará todos los recursos
terraform destroy
```

**Nota**: El bucket S3 de Terraform state (creado por bootstrap) debe eliminarse manualmente si ya no se necesita.

## Troubleshooting

### Error: IAM Identity Center not enabled
**Solución**: Habilita IAM Identity Center manualmente en la consola de AWS.

### Error: State lock timeout
**Solución**: Otro proceso está usando el state. Espera o usa `terraform force-unlock <lock-id>`.

### No recibo emails de SNS
**Solución**: 
1. Verifica spam
2. Confirma las subscripciones haciendo clic en el link del email
3. Verifica que los emails en `terraform.tfvars` sean correctos

### CloudTrail no está logging
**Solución**: Verifica que el bucket policy permite a CloudTrail escribir. Terraform lo configura automáticamente.

## Seguridad

- **No commitear** `terraform.tfvars` (contiene información sensible)
- **No commitear** `.terraform/` (archivos locales)
- **Sí commitear** `.terraform.lock.hcl` (lock de versiones de providers)
- **Rotar credenciales** regularmente
- **Usar MFA** siempre que sea posible
- **Revisar CloudTrail logs** periódicamente

## Agregar Nuevos Usuarios a IAM Identity Center

Una vez desplegada la infraestructura, puedes agregar usuarios adicionales a IAM Identity Center:

### Proceso para Agregar Usuarios

1. **Acceder a IAM Identity Center**:
   ```bash
   # Abrir la consola de AWS
   aws sso-admin list-instances
   ```
   O navega a: AWS Console → IAM Identity Center

2. **Crear Usuario**:
   - En IAM Identity Center, ve a "Users"
   - Haz clic en "Add user"
   - Completa la información:
     - Username (ej: `juan.perez`)
     - Email address (recibirá invitación)
     - First name y Last name
     - Display name (opcional)
   - Haz clic en "Next"

3. **Agregar a Grupos (Opcional)**:
   - Puedes crear grupos para gestionar permisos más fácilmente
   - Ejemplo: `Admins`, `Developers`, `ReadOnly`

4. **Asignar Permission Set**:
   - Ve a "AWS accounts" en IAM Identity Center
   - Selecciona tu cuenta AWS
   - Haz clic en "Assign users or groups"
   - Selecciona el usuario recién creado
   - Asigna uno de los Permission Sets:
     - **AdminPermissionSet**: Acceso administrativo completo (4h session)
     - **DeveloperPermissionSet**: Acceso de desarrollo con restricciones IAM (8h session)
     - **ReadOnlyPermissionSet**: Solo lectura (12h session)
   - Haz clic en "Submit"

5. **Usuario Recibe Invitación**:
   - El usuario recibirá un email con instrucciones
   - Debe configurar su password
   - Debe configurar MFA (obligatorio)

6. **Acceso del Usuario**:
   - URL de acceso: `https://<your-subdomain>.awsapps.com/start`
   - Login con username y password
   - Configurar MFA en primer login
   - Acceder a la cuenta AWS con el Permission Set asignado

### Mejores Prácticas para Usuarios

- **Siempre usar MFA**: Configurado automáticamente como obligatorio
- **Usar SSO**: Nunca crear IAM users con access keys
- **Principio de menor privilegio**: Asignar el Permission Set mínimo necesario
- **Revisar accesos regularmente**: Remover usuarios que ya no necesitan acceso
- **Rotar credenciales**: IAM Identity Center maneja esto automáticamente

### Gestión de Grupos (Recomendado)

Para facilitar la gestión de múltiples usuarios:

```bash
# Crear grupos en IAM Identity Center
1. Ve a "Groups" en IAM Identity Center
2. Crea grupos: "Admins", "Developers", "Auditors"
3. Asigna Permission Sets a grupos en lugar de usuarios individuales
4. Agrega usuarios a grupos según su rol
```

Esto simplifica la gestión cuando tienes muchos usuarios con roles similares.

## Runbook de Tareas Administrativas

### Tarea 1: Revisar Logs de CloudTrail

**Frecuencia**: Semanal o después de eventos sospechosos

```bash
# Listar objetos recientes en el bucket de CloudTrail
aws s3 ls s3://<account-id>-cloudtrail-logs-us-east-1/AWSLogs/<account-id>/CloudTrail/us-east-1/ --recursive | tail -20

# Descargar un log específico
aws s3 cp s3://<account-id>-cloudtrail-logs-us-east-1/AWSLogs/<account-id>/CloudTrail/us-east-1/2024/01/15/<log-file>.json.gz .

# Descomprimir y revisar
gunzip <log-file>.json.gz
cat <log-file>.json | jq '.Records[] | select(.userIdentity.type == "Root")'
```

**Qué buscar**:
- Uso de cuenta root (debe ser mínimo o cero)
- Cambios en IAM policies o roles
- Creación/eliminación de recursos
- Accesos desde IPs desconocidas

### Tarea 2: Monitorear Costos y Free Tier

**Frecuencia**: Diaria durante el primer mes, luego semanal

```bash
# Ver costos actuales del mes
aws ce get-cost-and-usage \
  --time-period Start=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE

# Ver uso de Free Tier
aws freetier get-free-tier-usage --filter '{"Dimensions":{"Key":"SERVICE","Values":["Amazon Simple Storage Service","Amazon DynamoDB"]}}'
```

**Acciones**:
- Si los costos superan $1 USD, investigar inmediatamente
- Si el uso de Free Tier supera 80%, revisar qué está consumiendo recursos
- Verificar que las alertas de budget están funcionando

### Tarea 3: Actualizar Terraform

**Frecuencia**: Mensual o cuando hay cambios necesarios

```bash
# 1. Actualizar código en Git
git pull origin main

# 2. Revisar cambios propuestos
terraform plan -out=tfplan

# 3. Revisar el plan cuidadosamente
terraform show tfplan

# 4. Aplicar cambios si todo se ve bien
terraform apply tfplan

# 5. Verificar outputs
terraform output
```

**Checklist**:
- [ ] Backup del state file antes de cambios grandes
- [ ] Revisar plan completo antes de apply
- [ ] Verificar que no hay destrucción de recursos críticos
- [ ] Confirmar que los cambios no generan costos

### Tarea 4: Rotar Credenciales de Terraform

**Frecuencia**: Cada 90 días

```bash
# 1. Crear nuevas credenciales en IAM Identity Center
# (Usar Admin Permission Set)

# 2. Configurar nuevas credenciales
aws configure sso

# 3. Probar acceso
aws sts get-caller-identity

# 4. Actualizar credenciales en CI/CD si aplica

# 5. Revocar credenciales antiguas después de verificar
```

### Tarea 5: Backup del Terraform State

**Frecuencia**: Antes de cambios importantes

```bash
# Descargar versión actual del state
aws s3 cp s3://<account-id>-terraform-state-us-east-1/aws-account-security/terraform.tfstate ./backup/terraform.tfstate.$(date +%Y%m%d)

# Listar versiones anteriores (S3 versioning habilitado)
aws s3api list-object-versions \
  --bucket <account-id>-terraform-state-us-east-1 \
  --prefix aws-account-security/terraform.tfstate

# Restaurar versión anterior si es necesario
aws s3api get-object \
  --bucket <account-id>-terraform-state-us-east-1 \
  --key aws-account-security/terraform.tfstate \
  --version-id <version-id> \
  terraform.tfstate.restored
```

### Tarea 6: Auditar Permission Sets y Usuarios

**Frecuencia**: Mensual

```bash
# Listar usuarios en IAM Identity Center
aws identitystore list-users --identity-store-id <identity-store-id>

# Listar Permission Sets
aws sso-admin list-permission-sets --instance-arn <instance-arn>

# Listar asignaciones de Permission Sets
aws sso-admin list-account-assignments \
  --instance-arn <instance-arn> \
  --account-id <account-id> \
  --permission-set-arn <permission-set-arn>
```

**Acciones**:
- Remover usuarios que ya no necesitan acceso
- Verificar que los Permission Sets asignados son apropiados
- Confirmar que MFA está habilitado para todos los usuarios

### Tarea 7: Verificar Configuración de Seguridad

**Frecuencia**: Trimestral

```bash
# Verificar S3 public access block
aws s3control get-public-access-block --account-id <account-id>

# Verificar IAM password policy
aws iam get-account-password-policy

# Verificar CloudTrail status
aws cloudtrail get-trail-status --name account-audit-trail

# Verificar budgets
aws budgets describe-budgets --account-id <account-id>
```

**Checklist**:
- [ ] S3 public access block está habilitado (4 configuraciones)
- [ ] IAM password policy requiere 14+ caracteres
- [ ] CloudTrail está logging activamente
- [ ] Budgets están configurados correctamente
- [ ] SNS subscriptions están confirmadas

### Tarea 8: Responder a Alertas de Seguridad

**Frecuencia**: Inmediata cuando se recibe alerta

**Alerta: Uso de Root Account**
```bash
# 1. Verificar en CloudTrail quién y cuándo
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=Username,AttributeValue=root \
  --max-results 10

# 2. Verificar que fue autorizado
# 3. Si no fue autorizado, cambiar password de root inmediatamente
# 4. Revisar todos los cambios realizados
# 5. Documentar el incidente
```

**Alerta: Nuevo IAM User/Role Creado**
```bash
# 1. Identificar quién creó el recurso
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=CreateUser \
  --max-results 5

# 2. Verificar que fue autorizado
# 3. Si no fue autorizado, eliminar el recurso
aws iam delete-user --user-name <username>

# 4. Revisar permisos del usuario que creó el recurso
```

**Alerta: Costo Excedido**
```bash
# 1. Identificar qué servicio está generando costos
aws ce get-cost-and-usage \
  --time-period Start=$(date -d "7 days ago" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity DAILY \
  --metrics "UnblendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE

# 2. Identificar recursos específicos
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Project,Values=aws-security-setup

# 3. Eliminar recursos no autorizados
# 4. Ajustar configuración para prevenir recurrencia
```

### Tarea 9: Actualizar Documentación

**Frecuencia**: Después de cada cambio significativo

```bash
# 1. Actualizar README.md con cambios
# 2. Actualizar runbook si hay nuevos procedimientos
# 3. Documentar lecciones aprendidas
# 4. Actualizar diagramas de arquitectura si aplica
# 5. Commit y push a Git

git add README.md
git commit -m "docs: actualizar documentación después de [cambio]"
git push origin main
```

### Tarea 10: Disaster Recovery Test

**Frecuencia**: Semestral

```bash
# 1. Backup completo del state
aws s3 sync s3://<account-id>-terraform-state-us-east-1 ./disaster-recovery-backup/

# 2. Documentar configuración actual
terraform output > disaster-recovery-backup/outputs.txt
terraform show > disaster-recovery-backup/current-state.txt

# 3. Simular pérdida de state (en ambiente de prueba)
# 4. Practicar restauración desde backup
# 5. Documentar tiempo de recuperación y lecciones aprendidas
```

## Próximos Pasos

Después del deployment:

1. ✅ Confirmar subscripciones SNS
2. ✅ Habilitar MFA en root account (manual)
3. ✅ Crear usuarios en IAM Identity Center
4. ✅ Asignar Permission Sets a usuarios
5. ✅ Probar login con SSO
6. ✅ Verificar que CloudTrail está logging
7. ✅ Revisar costos en AWS Cost Explorer

## Recursos Adicionales

- [AWS Free Tier](https://aws.amazon.com/free/)
- [IAM Identity Center Documentation](https://docs.aws.amazon.com/singlesignon/)
- [CloudTrail Best Practices](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/best-practices-security.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## Licencia

Este proyecto es de código abierto y está disponible bajo la licencia MIT.

## Soporte

Para preguntas o problemas, por favor abre un issue en el repositorio.
