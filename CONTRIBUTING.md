# Contribuyendo a AWS Security Baseline Terraform

¡Gracias por tu interés en contribuir! Este documento proporciona guías para contribuir al proyecto.

## Cómo Contribuir

### Reportar Bugs

Si encuentras un bug, por favor abre un issue con:
- Descripción clara del problema
- Pasos para reproducir
- Comportamiento esperado vs actual
- Versión de Terraform y AWS provider
- Logs relevantes (sin información sensible)

### Sugerir Mejoras

Para sugerir nuevas funcionalidades:
- Abre un issue describiendo la mejora
- Explica el caso de uso
- Considera el impacto en costos (debe mantenerse en Free Tier)

### Pull Requests

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Realiza tus cambios
4. Asegúrate de que el código pasa las validaciones:
   ```bash
   terraform fmt -check -recursive
   terraform validate
   ```
5. Commit tus cambios (`git commit -m 'feat: agregar nueva funcionalidad'`)
6. Push a la rama (`git push origin feature/nueva-funcionalidad`)
7. Abre un Pull Request

### Estándares de Código

- Usa `terraform fmt` para formatear el código
- Sigue las convenciones de nombres de Terraform
- Documenta variables y outputs
- Incluye comentarios para lógica compleja
- Mantén los módulos pequeños y enfocados

### Commits

Usa [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` para nuevas funcionalidades
- `fix:` para correcciones de bugs
- `docs:` para cambios en documentación
- `refactor:` para refactorización de código
- `test:` para agregar o modificar tests

### Testing

Antes de enviar un PR:
- Ejecuta `terraform plan` y verifica que no hay errores
- Prueba en una cuenta AWS de prueba si es posible
- Verifica que no se generan costos fuera del Free Tier

## Restricciones Importantes

- **Solo servicios Free Tier**: No agregar servicios que generen costos
- **Seguridad primero**: Cualquier cambio debe mantener o mejorar la postura de seguridad
- **Documentación**: Actualizar README.md con cualquier cambio significativo

## Preguntas

Si tienes preguntas, abre un issue con la etiqueta `question`.
