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
- [x] Añadido campo `OperationType` al modelo de operación para distinguir compras y ventas.

## FASE 3: UI Básica y Funcionalidad Inicial

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

- [x] Integrar API de CoinGecko para obtener precios de criptos (usando modelo con `idCoinGecko`).
- [x] Selección dinámica de símbolo según tipo de activo.
- [x] Cálculo automático de valor actual y rentabilidad con precios reales.
- [x] Actualización automática/periódica de datos de precios.
- [x] Mostrar gráfico con datos históricos reales por activo (CoinGecko).
- [x] ✅ Implementado histórico del portafolio completo (valor agregado por minuto, con agrupamiento real).
  - [x] Todos los puntos del histórico se agrupan por minuto para evitar picos artificiales por timestamps diferentes.
- [x] Uso de caché local de históricos en Hive para evitar peticiones innecesarias.
- [x] ✅ Recalcular histórico si se añaden operaciones anteriores al rango guardado.
- [x] 🧠 Coordinación automática entre operaciones, histórico y gráfico tras cada cambio.
- [x] 📊 Recalculo del histórico semanal a partir del primer día con inversión real.
- [x] 🔁 Punto actual se actualiza cada 60s con los precios en vivo.
- [x] ✅ Añadir automáticamente punto actual del día con precios en vivo.
- [ ] Soporte offline: usar datos locales si no hay conexión.
- [ ] ⚠️ Soporte para filtrar el gráfico por activo individual con tap largo. 👈 PENDIENTE
- [x] 🔁 Sustituida API de CoinGecko por CryptoCompare (top 100 por market cap).
- [x] 🧭 Nuevo servicio `CryptoCompareAssetListService` para cargar los activos disponibles.
- [x] 🧩 Creado `AssetListProvider` con filtro en vivo para el selector.
- [x] 🧾 Modal de selección de activos completamente rediseñado con scroll, buscador y diseño minimalista.
- [x] ✏️ Campo de búsqueda sin bordes, sin placeholder y con icono de lupa único.
- [x] 📈 Servicio `CryptoCompareHistoryService` funcional con endpoint corregido y parámetros validados.
- [x] 💵 Servicio `CryptoComparePriceService` implementado para obtener precios en tiempo real desde CryptoCompare.
- [x] Eliminado el texto "Cargando..." en la lista de activos si no hay precio aún. 
- [x] Añadido AnimatedSwitcher para transiciones suaves al mostrar precios. 
- [x] Se reserva espacio para evitar saltos visuales entre “cargando” y “valor”. 
- [x] Estilo gráfico más fluido: se evita mostrar el gráfico si aún no hay histórico. 
- [x] Punto actual (todayPoint) solo se añade si el histórico no lo contiene ya. 
- [x] Eliminar título redundante de la AppBar para un diseño más limpio y centrado.

## FASE 5.5: Migración a CoinGecko

- [x] Sustituir todos los endpoints de CryptoCompare por CoinGecko (`/coins/markets`, `/simple/price`, `/coins/{id}/market_chart`).
- [x] Añadir campo `coingeckoId` al modelo `InvestmentModel` y regenerar adapters Hive.
- [x] Actualizar `AssetListProvider` para usar `CoinGeckoAssetsDatasource` y exponer `filteredSymbols` de `CoinGeckoAsset`.
- [x] Modificar `AssetSelectorModal` para devolver `Map<String, String>` con `id`, `symbol` y `name`.
- [x] Implementar `CoinGeckoPriceService` en lugar de `CryptoComparePriceService`.
- [x] Ajustar `PortfolioSyncService` para calcular valor actual usando `coingeckoId`.
- [x] Probar flujo completo de selección, guardado y visualización de precios con CoinGecko API.

## 🛠️ Mejoras de Rendimiento y Lógica del Gráfico (Junio 2025)

# 🔧 Optimización de Renderizado
- [x] El gráfico ya no se reconstruye cada vez que se toca o arrastra el dedo.  
  → Ahora usamos `context.read()` en lugar de `context.watch()` para evitar rebuilds innecesarios.
- [x] Eliminado el `ValueKey(spots)` en el widget del gráfico para evitar regeneración completa.
- [x] Se separó el widget `_PortfolioChart` para aislar cambios solo a `history`.

# ⚡ Precarga desde Hive (datos previos)
- [x] Si el usuario ya había abierto la app, se muestra inmediatamente el histórico almacenado en Hive.
- [x] Carga asincrónica de los precios en segundo plano sin bloquear la UI.

# 🔁 Lógica de actualización del histórico
- [x] Eliminado el cálculo repetido del histórico con cada movimiento táctil.
- [x] Añadir comprobación de si ya ha pasado una semana desde el último punto estático guardado.
  - Si no ha pasado, no se fuerza regeneración.
  - Si ha pasado, se añade nuevo punto y se recalcula el gráfico.
- [x] Optimizado `loadHistory()` para evitar reconstrucciones dobles al abrir la app.
  → Se agrupa el cambio de estado y se notifica solo una vez si hubo cambios.
- [x] Validación de duplicación del punto actual del día: evita que se agregue más de una vez si ya existe en el histórico.

# 🧠 Estrategia de reconstrucción eficiente
- [x] Implementar persistencia del último gráfico mostrado (incluye `history` y `spotPrices`).
- [x] Al abrir la app, se muestra inmediatamente el gráfico anterior.
- [x] Se actualiza en segundo plano (si hay cambios) sin interferir al usuario.

# 🧪 Pendiente de pruebas
- [ ] Verificar comportamiento en dispositivos de gama baja (memoria y fluidez).
- [ ] Validar que no se reconstruya más de una vez por segundo en casos extremos.

## FASE 6: Gestión y Edición de Operaciones

- [x] `Investment` acepta múltiples operaciones (modelo reorganizado).
- [x] Pantalla/modal con detalle de cada activo (listado de operaciones, compras/ventas).
- [x] Permitir editar y eliminar operaciones.
- [x] Confirmación antes de borrar.
- [x] Visualización clara de todas las operaciones históricas.
- [x] Acceso al historial con tap sobre activo en la lista principal. 👈 NUEVO 
- [x] Acceso al historial desde pantalla de activos ocultos (archivados). 👈 NUEVO
- [ ] Filtrar gráfico por activo con tap largo sobre activo. 👈 NUEVO
- [x] Soporte para registrar operaciones de compra y venta con distinción clara (OperationType). ✅
- [x] Modal de añadir operación con soporte de tipo (compra/venta), validaciones completas y persistencia.
- [x] Separación de activos sin cantidad (>0) en pantalla dedicada de activos archivados. 👈 NUEVO
- [x] Botón minimalista en la pantalla principal para acceder a activos ocultos. 👈 NUEVO
- [x]  Ajustes visuales en el modal de compra/venta: unificación de estilos entre botones, aplicación de colores pastel (verde y mostaza), tipografía en negro, y mejoras en la accesibilidad del teclado.
- [x] Evitar doble guardado en el modal de operación: desactiva campos y botones tras pulsar "Guardar", muestra indicador de carga y conserva estilos visuales.

## FASE 7: Pantalla de Configuración y Personalización

- [x] Crear pantalla de ajustes accesible desde la pantalla principal.
- [x] Selector de idioma (`es`, `en`).
- [x] Selector de moneda base (USD, EUR, etc.).
- [ ] Alternancia de modo oscuro/manual.
- [x] Exportación/Importación manual de datos (JSON o CSV).
- [X] Resetear todos los datos del portafolio (con confirmación).
- [ ] Información sobre la app (versión, créditos, enlace al repositorio).

## FASE 8: Robustez y Experiencia Final

- [x] Gráfico y datos cargan de inmediato desde Hive tras hot restart ✅
- [x] Persistencia robusta: que los datos no se pierdan nunca (pruebas con cierre/reapertura de app).
- [ ] Pruebas básicas de funcionalidades críticas.
- [ ] Mejoras visuales (tipografía, iconos minimalistas, modo oscuro opcional).
- [ ] Optimizaciones para rendimiento y tamaño de app (revisar dependencias y assets).
- [ ] Internacionalización real (`en`, `es`) y textos bien gestionados.
- [x] Animaciones de transición suaves (pantallas y gráficos).
- [ ] Autenticación con Apple ID (y Google opcional).
- [ ] Animaciones de transición suaves (pantallas y gráficos).
- [x] Ocultado el texto "Cargando..." en la pantalla de selección de símbolos (AssetSelectorModal) si ya hay contenido previo.
- [ ] Pruebas de resistencia en la interacción del modal (guardar varias veces, cierre brusco, datos inválidos).
- [ ] Feedback visual unificado: aplicar patrón de carga (spinner) en otros botones relevantes (como borrar, editar, sincronizar).
- [ ] Refactor de `AddInvestmentDialog` para modularizar validaciones y lógica de guardado.

## FASE 9: Publicación y Extras

- [ ] Pruebas en TestFlight (iOS) y dispositivos reales.
- [ ] Ajustes finales de diseño.
- [ ] Publicar en App Store y Play Store.
