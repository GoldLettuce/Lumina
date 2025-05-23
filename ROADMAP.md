# ??? Roadmap Detallado Portafolio Financiero

## FASE 1: Estructura Base y Configuración

- [x] Crear estructura de carpetas (core, data, domain, ui, l10n).
- [x] Añadir archivos README.md en cada carpeta con explicación.
- [ ] Crear `.gitignore` para Flutter.
- [ ] Crear `main.dart` con pantalla de bienvenida minimalista.
- [ ] Definir paleta de colores y fuentes minimalistas (archivo de tema en `core`).
- [ ] Configurar internacionalización inicial (inglés/español, aunque sea solo en estructura).

## FASE 2: Modelo de Datos y Persistencia

- [ ] Definir entidad `Investment` en `domain/entities`.
- [ ] Crear modelo `InvestmentModel` en `data/models`.
- [ ] Implementar almacenamiento local simple (usando `shared_preferences` o `hive`).
- [ ] Definir repositorio abstracto `InvestmentRepository` en `domain/repositories`.
- [ ] Implementar repositorio concreto en `data/repositories_impl`.
- [ ] Crear caso de uso “añadir inversión” y “listar inversiones” en `domain/usecases`.

## FASE 3: UI Básica y Funcionalidad Inicial

- [ ] Pantalla de inicio (welcome/minimalista, logo y nombre).
- [ ] Pantalla principal con listado de inversiones (vacío al principio).
- [ ] Pantalla/modal para añadir inversión (tipo, símbolo, cantidad, fecha, precio de compra).
- [ ] Validación de formularios y UX amigable (campos obligatorios, errores claros).
- [ ] Gestión de estado con Provider para inversiones.

## FASE 4: Visualización y Experiencia de Usuario

- [ ] Resumen superior con total invertido, valor actual, rentabilidad general (minimalista).
- [ ] Gráfico de evolución del portafolio (usando fl_chart, solo diseño simple al principio).
- [ ] Selector de activos con buscador (modal tipo CoinGecko).
- [ ] Animaciones de transición suaves (pantallas y gráficos).

## FASE 5: Integración de Datos en Tiempo Real

- [ ] Integrar API de CoinGecko para obtener precios de criptos (usando modelo con `idCoinGecko`).
- [ ] Integrar API de acciones/ETFs si es posible (AlphaVantage, Yahoo Finance, etc.).
- [ ] Selección dinámica de símbolo según tipo de activo.
- [ ] Cálculo automático de valor actual y rentabilidad con precios reales.
- [ ] Actualización automática/periódica de datos de precios.

## FASE 6: Gestión y Edición de Operaciones

- [ ] Pantalla/modal con detalle de cada activo (listado de operaciones, compras/ventas).
- [ ] Permitir editar y eliminar operaciones.
- [ ] Confirmación antes de borrar.
- [ ] Visualización clara de todas las operaciones históricas.

## FASE 7: Robustez y Experiencia Final

- [ ] Persistencia robusta: que los datos no se pierdan nunca (pruebas con cierre/reapertura de app).
- [ ] Pruebas básicas de funcionalidades críticas.
- [ ] Mejoras visuales (tipografía, iconos minimalistas, modo oscuro opcional).
- [ ] Optimización para rendimiento y tamaño de app (revisar dependencias y assets).
- [ ] Internacionalización real (en, es) y textos bien gestionados.
- [ ] Pantalla de ajustes básicos (idioma, moneda base, etc.).
- [ ] Autenticación con Apple ID (y Google opcional).

## FASE 8: Publicación y Extras

- [ ] Pruebas en TestFlight (iOS) y dispositivos reales.
- [ ] Ajustes finales de diseño.
- [ ] Publicar en App Store y Play Store.
