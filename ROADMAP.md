# ✅ Roadmap Detallado – Portafolio Financiero (Actualizado)

## FASE 1: Estructura Base y Configuración

- [x] Crear estructura de carpetas (`core`, `data`, `domain`, `ui`, `l10n`).
- [x] Añadir archivos `README.md` en cada carpeta con explicación.
- [x] Crear `.gitignore` para Flutter.
- [x] Crear `main.dart` con pantalla de bienvenida minimalista.
- [x] Definir paleta de colores y fuentes minimalistas (archivo de tema en `core`).
- [x] Configurar internacionalización inicial (inglés/español, aunque sea solo en estructura).

## FASE 2: Modelo de Datos y Persistencia

- [x] Definir entidad `Investment` en `domain/entities`.
- [x] Crear modelo `InvestmentModel` en `data/models`.
- [x] Implementar almacenamiento local simple (usando `shared_preferences` o `hive`).
- [x] Definir repositorio abstracto `InvestmentRepository` en `domain/repositories`.
- [x] Implementar repositorio concreto en `data/repositories_impl`.
- [x] Crear caso de uso “añadir inversión” y “listar inversiones” en `domain/usecases`.

## FASE 3: UI Básica y Funcionalidad Inicial

- ~~[ ] Pantalla de inicio (welcome/minimalista, logo y nombre).~~ DESESTIMADO
- [x] Pantalla principal con listado de inversiones (vacío al principio).
- [x] Pantalla/modal para añadir inversión (tipo, símbolo, cantidad, fecha, precio de compra).
- [x] Validación de formularios y UX amigable (campos obligatorios, errores claros).
- [x] Gestión de estado con Provider para inversiones.

## FASE 4: Visualización y Experiencia de Usuario

- [x] Resumen superior con total invertido, valor actual, rentabilidad general (minimalista).
- [x] Gráfico de evolución del portafolio (usando `fl_chart`, solo diseño simple al principio).
- [x] Selector de activos con buscador (modal tipo CoinGecko).
- [x] Selector de temporalidad en el gráfico (1D, 1W, 1M, 1Y, ALL).

## FASE 5: Integración de Datos en Tiempo Real

## FASE 5: Integración de Datos en Tiempo Real

- [x] Integrar API de CoinGecko para obtener precios de criptos (usando modelo con `idCoinGecko`).
- [ ] Integrar API de acciones/ETFs si es posible (AlphaVantage, Yahoo Finance, etc.).
- [x] Selección dinámica de símbolo según tipo de activo.
- [x] Cálculo automático de valor actual y rentabilidad con precios reales.
- [x] Actualización automática/periódica de datos de precios.
- [x] Mostrar gráfico con datos históricos reales por activo (CoinGecko).
- [x] ✅ Implementado histórico del portafolio completo (valor agregado por minuto, con agrupamiento real).
  - [x] Todos los puntos del histórico se agrupan por minuto para evitar picos artificiales por timestamps diferentes.
- [x] Uso de caché local de históricos en Hive para evitar peticiones innecesarias.
- [ ] Recalcular histórico si se añaden operaciones anteriores al rango guardado.
- [ ] Soporte offline: usar datos locales si no hay conexión.
- [ ] ⚠️ Soporte para filtrar el gráfico por activo individual con tap largo. 👈 PENDIENTE
- [x] 🔁 Sustituida API de CoinGecko por CryptoCompare (top 100 por market cap).
- [x] 🧭 Nuevo servicio `CryptoCompareAssetListService` para cargar los activos disponibles.
- [x] 🧩 Creado `AssetListProvider` con filtro en vivo para el selector.
- [x] 🧾 Modal de selección de activos completamente rediseñado con scroll, buscador y diseño minimalista.
- [x] ✏️ Campo de búsqueda sin bordes, sin placeholder y con icono de lupa único.

## FASE 6: Gestión y Edición de Operaciones

- [x] `Investment` acepta múltiples operaciones (modelo reorganizado).
- [ ] Pantalla/modal con detalle de cada activo (listado de operaciones, compras/ventas).
- [ ] Permitir editar y eliminar operaciones.
- [ ] Confirmación antes de borrar.
- [ ] Visualización clara de todas las operaciones históricas.
- [ ] Acceso al historial con tap sobre activo en la lista principal. 👈 NUEVO
- [ ] Filtrar gráfico por activo con tap largo sobre activo. 👈 NUEVO

## FASE 7: Robustez y Experiencia Final

- [x] Gráfico y datos cargan de inmediato desde Hive tras hot restart ✅
- [ ] Persistencia robusta: que los datos no se pierdan nunca (pruebas con cierre/reapertura de app).
- [ ] Pruebas básicas de funcionalidades críticas.
- [ ] Mejoras visuales (tipografía, iconos minimalistas, modo oscuro opcional).
- [ ] Optimizaciones para rendimiento y tamaño de app (revisar dependencias y assets).
- [ ] Internacionalización real (`en`, `es`) y textos bien gestionados.
- [ ] Pantalla de ajustes básicos (idioma, moneda base, etc.).
- [ ] Autenticación con Apple ID (y Google opcional).
- [ ] Animaciones de transición suaves (pantallas y gráficos).

## FASE 8: Publicación y Extras

- [ ] Pruebas en TestFlight (iOS) y dispositivos reales.
- [ ] Ajustes finales de diseño.
- [ ] Publicar en App Store y Play Store.
