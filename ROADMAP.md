# Roadmap Detallado Portafolio Financiero

## FASE 1: Estructura Base y Configuraci�n

- [x] Crear estructura de carpetas (core, data, domain, ui, l10n).
- [x] A�adir archivos README.md en cada carpeta con explicaci�n.
- [x] Crear `.gitignore` para Flutter.
- [x] Crear `main.dart` con pantalla de bienvenida minimalista.
- [x] Definir paleta de colores y fuentes minimalistas (archivo de tema en `core`).
- [x] Configurar internacionalizaci�n inicial (ingl�s/espa�ol, aunque sea solo en estructura).

## FASE 2: Modelo de Datos y Persistencia

- [x] Definir entidad `Investment` en `domain/entities`.
- [x] Crear modelo `InvestmentModel` en `data/models`.
- [x] Implementar almacenamiento local simple (usando `shared_preferences` o `hive`).
- [x] Definir repositorio abstracto `InvestmentRepository` en `domain/repositories`.
- [x] Implementar repositorio concreto en `data/repositories_impl.
- [x] Crear caso de uso �a�adir inversi�n� y �listar inversiones� en `domain/usecases`.

## FASE 3: UI B�sica y Funcionalidad Inicial

- ~~[ ] Pantalla de inicio (welcome/minimalista, logo y nombre).~~ DESESTIMADO
- [x] Pantalla principal con listado de inversiones (vac�o al principio).
- [x] Pantalla/modal para a�adir inversi�n (tipo, s�mbolo, cantidad, fecha, precio de compra).
- [x] Validaci�n de formularios y UX amigable (campos obligatorios, errores claros).
- [x] Gesti�n de estado con Provider para inversiones.

## FASE 4: Visualizaci�n y Experiencia de Usuario

- [ ] Resumen superior con total invertido, valor actual, rentabilidad general (minimalista).
- [ ] Gr�fico de evoluci�n del portafolio (usando fl_chart, solo dise�o simple al principio).
- [ ] Selector de activos con buscador (modal tipo CoinGecko).
- [ ] Animaciones de transici�n suaves (pantallas y gr�ficos).

## FASE 5: Integraci�n de Datos en Tiempo Real

- [ ] Integrar API de CoinGecko para obtener precios de criptos (usando modelo con `idCoinGecko`).
- [ ] Integrar API de acciones/ETFs si es posible (AlphaVantage, Yahoo Finance, etc.).
- [ ] Selecci�n din�mica de s�mbolo seg�n tipo de activo.
- [ ] C�lculo autom�tico de valor actual y rentabilidad con precios reales.
- [ ] Actualizaci�n autom�tica/peri�dica de datos de precios.

## FASE 6: Gesti�n y Edici�n de Operaciones

- [ ] Pantalla/modal con detalle de cada activo (listado de operaciones, compras/ventas).
- [ ] Permitir editar y eliminar operaciones.
- [ ] Confirmaci�n antes de borrar.
- [ ] Visualizaci�n clara de todas las operaciones hist�ricas.

## FASE 7: Robustez y Experiencia Final

- [ ] Persistencia robusta: que los datos no se pierdan nunca (pruebas con cierre/reapertura de app).
- [ ] Pruebas b�sicas de funcionalidades cr�ticas.
- [ ] Mejoras visuales (tipograf�a, iconos minimalistas, modo oscuro opcional).
- [ ] Optimizaci�n para rendimiento y tama�o de app (revisar dependencias y assets).
- [ ] Internacionalizaci�n real (en, es) y textos bien gestionados.
- [ ] Pantalla de ajustes b�sicos (idioma, moneda base, etc.).
- [ ] Autenticaci�n con Apple ID (y Google opcional).

## FASE 8: Publicaci�n y Extras

- [ ] Pruebas en TestFlight (iOS) y dispositivos reales.
- [ ] Ajustes finales de dise�o.
- [ ] Publicar en App Store y Play Store.
