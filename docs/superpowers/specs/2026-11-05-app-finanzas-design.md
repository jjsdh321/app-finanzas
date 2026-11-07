# App de finanzas personales: especificación de diseño

- **Fecha:** 2026-11-05
- **Estado:** pendiente de revisión
- **Plataforma:** Android e iOS con un solo código (Flutter)
- **Datos:** solo locales en el dispositivo (sin cuenta ni servidor)

---

## 0. Objetivo y público

**Para quién:** personas con sueldo mínimo o ingresos ajustados, aunque sirve para cualquier usuario.

**Resultado esperado:** que el usuario sepa en menos de 1 minuto cuánto entra, cuánto sale, cuánto le sobra y cuánto debe apartar para imprevistos, caprichos y ahorro.

**Criterios de éxito**
- Registrar un gasto en menos de 10 segundos.
- El Inicio muestra datos útiles nada más terminar el onboarding.
- Las cifras de reparto siempre son alcanzables (se basan en lo que realmente sobra).
- Las sumas cuadran al céntimo.
- Funciona sin conexión, sin registro y sin anuncios.

**Fuera de alcance en v1.0:** sincronización en la nube, cuentas de usuario, importación bancaria, multiusuario (ver hoja de ruta, sección 8).

---

## 1. Arquitectura

```
UI (Flutter widgets)
   │  lee estado vía Riverpod
   ▼
domain/   funciones puras en Dart (cálculos) + modelos
   ▲
   │  datos
data/     repositorios  →  Drift (SQLite local)
```

- **`ui/`**: pantallas y widgets. Sin lógica de cálculo ni acceso directo a la base de datos.
- **`domain/`**: núcleo. Funciones puras y deterministas: beneficio, reparto, pagas extra, saldos. Sin dependencias de Flutter ni de Drift. Cubierto por tests unitarios.
- **`data/`**: repositorios (interfaces en `domain/`, implementación en `data/`) sobre Drift. Gestionan migraciones y la generación de recurrentes.
- **Estado:** Riverpod. Los providers combinan repositorios y funciones de dominio y exponen el resultado a la UI.

**Dependencias principales:** `flutter_riverpod`, `drift` + `sqlite3_flutter_libs`, `fl_chart`, `intl` (formato de moneda y fechas en español).

**Estructura de carpetas**
```
lib/
  main.dart
  app.dart                 tema, rutas, navegación inferior
  domain/
    models/                Money, Transaction, Category, RecurringItem, Pocket, Settings
    calc/                  monthly_summary.dart, allocation.dart, extra_pay.dart, pocket_balance.dart
    repositories/          interfaces abstractas
  data/
    db/                    tablas Drift, database.dart, migraciones
    repositories/          implementaciones
    recurring_generator.dart
  ui/
    home/ transactions/ stats/ settings/ add_transaction/ onboarding/
    widgets/               componentes compartidos (barra de bolsa, selector de mes…)
  providers/
test/
  domain/  data/  ui/
integration_test/
```

---

## 2. Modelo de datos

Todos los importes se guardan como **enteros en céntimos**. Las fechas, como fecha local (sin hora) en formato ISO.

| Tabla | Campos |
|---|---|
| `categories` | `id`, `name`, `icon`, `pocket` (`necesidades` / `imprevistos` / `caprichos` / `ahorro`), `archived` |
| `transactions` | `id`, `type` (`income` / `expense`), `amount_cents` (>0), `date`, `category_id`, `note` (nullable), `recurring_id` (nullable), `period` (`YYYY-MM`, nullable, solo si viene de un recurrente) |
| `recurring_items` | `id`, `type`, `amount_cents`, `day_of_month` (1–31), `category_id`, `active`, `extra_months` (lista de meses con paga extra, p. ej. `[6,12]`), `extra_amount_cents` (nullable) |
| `pockets` | `id`, `key` (`imprevistos` / `caprichos` / `ahorro`), `weight` (entero) |
| `settings` | fila única: `currency` (por defecto `EUR`), `payments_per_year` (12 o 14), `prorate_extra_pay` (bool, por defecto `true` si 14 pagas), `start_month` (`YYYY-MM`), `onboarding_done` |

**Restricciones**
- Índice único `(recurring_id, period)` en `transactions`: un recurrente genera como máximo un movimiento por mes.
- `day_of_month` mayor que los días del mes se ajusta al último día (p. ej. 31 → 30 de noviembre).

**Categorías predefinidas**
- Necesidades: Vivienda, Suministros, Comida, Transporte, Salud, Telefonía/Internet, Otros básicos.
- Imprevistos: Imprevistos (averías, multas, urgencias).
- Caprichos: Ocio, Restaurantes, Compras, Suscripciones.
- Ahorro: Ahorro (traspasos a ahorro).
- Ingresos: Nómina, Paga extra, Otros ingresos.

**Decisiones**
- Los recurrentes **generan movimientos reales** al abrir la app (para cada mes desde la última generación hasta el actual), de modo que un mes concreto se puede editar o borrar.
- Los **saldos de las bolsas no se guardan**: se calculan siempre a partir de movimientos y asignaciones, por lo que nunca se desincronizan.
- Las migraciones de Drift están versionadas; las mejoras futuras añaden tablas sin perder datos.

---

## 3. Lógica de cálculo (`domain/calc`)

Funciones puras. Entradas: listas de movimientos, categorías y ajustes. Salidas: valores inmutables.

### 3.1 Resumen mensual
```
ingresos_mes = Σ ingresos del mes
gastos_mes   = Σ gastos del mes
beneficio    = ingresos_mes − gastos_mes
```

### 3.2 Reparto del mes
```
necesidades = Σ gastos del mes en categorías con pocket = necesidades
disponible  = ingreso_base − necesidades
```
- `ingreso_base` = `ingresos_mes`, salvo con prorrateo activo (ver 3.4).
- `disponible` se reparte entre **Imprevistos, Caprichos y Ahorro** proporcionalmente a sus pesos. Por defecto 20 : 15 : 15 → **40 % / 30 % / 30 %**.
- **Redondeo:** cada asignación = `floor(disponible × peso / Σpesos)`; el resto de céntimos va a Ahorro. La suma de asignaciones es siempre exactamente `disponible`.
- Si `disponible ≤ 0`: todas las asignaciones son 0, se marca `deficit = −disponible` y la UI muestra un aviso sugiriendo recortar primero Caprichos.

**Indicador de referencia:** `ratio_necesidades = necesidades / ingreso_base`, comparado con el 50 % recomendado. Solo informativo.

### 3.3 Saldo de cada bolsa (acumulativo)
```
saldo(bolsa, hasta_mes) = Σ asignaciones(bolsa) desde start_month hasta hasta_mes
                        − Σ gastos en categorías de esa bolsa en el mismo periodo
```
- Un gasto en categoría de Caprichos resta de Caprichos; uno de Imprevistos resta de Imprevistos; uno de Ahorro (traspaso) **no** resta del saldo de Ahorro, se trata como dinero apartado.
- El saldo puede ser negativo; la UI lo muestra en rojo.

### 3.4 Pagas extra y prorrateo
- `payments_per_year = 14`: la nómina recurrente tiene `extra_months = [6, 12]` por defecto.
- Con `prorate_extra_pay = true`: `ingreso_base = ingreso_anual_previsto / 12`, donde el ingreso anual previsto sale de los recurrentes de ingreso (12 pagas + extras). Los ingresos no recurrentes del mes se suman tal cual.
- En meses sin extra se muestra: "Aparta X € de tu paga extra para este mes" (diferencia entre base prorrateada y lo cobrado). En junio y diciembre: "Guarda X € de la extra para los próximos meses".
- Con prorrateo desactivado: `ingreso_base = ingresos_mes` reales.

### 3.5 Mes sin ingresos registrados
Si el mes actual no tiene ingresos todavía, el Inicio usa los ingresos recurrentes previstos y etiqueta las cifras como **"Estimación"**.

---

## 4. Pantallas y navegación

**Navegación inferior con 4 pestañas** + botón flotante **"+"** visible en todas.

### 4.1 Inicio
- Selector de mes (‹ Noviembre 2026 ›).
- Tarjeta principal: ingresos, gastos, sobrante (beneficio).
- 3 barras de bolsa (Imprevistos, Caprichos, Ahorro): asignado este mes, gastado, saldo disponible.
- Avisos: déficit; necesidades > 50 % de ingresos; mensaje de paga extra si aplica.
- Últimos 5 movimientos con enlace a "Ver todos".

### 4.2 Movimientos
- Lista del mes agrupada por día, con total diario.
- Filtros: tipo (ingreso/gasto) y categoría.
- Deslizar para editar o borrar (con deshacer).

### 4.3 Estadísticas
- Anillo de gasto por categoría del mes.
- Barras de ingresos frente a gastos de los últimos 6 meses.
- Indicador de necesidades frente al 50 %.

### 4.4 Ajustes
- **Recurrentes:** lista, alta, edición, activar/desactivar; configuración de pagas extra.
- **Reparto:** pesos de las bolsas con vista previa en euros sobre el mes actual.
- **Categorías:** crear, editar, archivar; asignar bolsa.
- Número de pagas, prorrateo, moneda.
- Borrar todos los datos (doble confirmación).

### 4.5 Añadir / editar movimiento
Hoja inferior, un solo paso: importe grande con teclado numérico → Gasto/Ingreso → categoría (rejilla de iconos) → fecha (hoy por defecto) → nota opcional → Guardar. Recuerda la última categoría usada por tipo.

### 4.6 Onboarding (primer uso, 3 pasos)
1. Sueldo neto mensual y número de pagas (12/14).
2. Gastos fijos principales (alquiler, suministros, transporte, teléfono…) → se crean como recurrentes.
3. Confirmar el reparto sugerido (40/30/30) con vista previa en euros.

Al terminar se generan los recurrentes del mes actual y se abre el Inicio con datos.

### 4.7 Diseño visual
- Lenguaje sencillo, sin jerga financiera.
- Colores de estado: verde (disponible), ámbar (bolsa < 20 % de lo asignado en el mes), rojo (saldo ≤ 0 o déficit).
- Modo claro y oscuro (sigue al sistema). Material 3.
- Formato de moneda y fechas con `intl` en `es_ES`.

---

## 5. Manejo de errores

- **Importes:** solo positivos, máximo 2 decimales, validados en el formulario; se convierten a céntimos antes de guardar.
- **Borrar categoría con movimientos:** obligatorio reasignar los movimientos a otra categoría o archivar la categoría. Nunca se pierden movimientos.
- **Fallo de escritura en BD:** mensaje claro (SnackBar) con opción de reintentar; la app no se cierra.
- **Recurrentes duplicados:** imposibles por el índice único `(recurring_id, period)`; la generación es idempotente.
- **Pesos de bolsas:** se exige al menos un peso > 0; el porcentaje mostrado siempre suma 100 %.
- **Cambio de fecha del sistema / zona horaria:** las fechas se guardan sin hora, por lo que no cambian de mes.

---

## 6. Pruebas

| Nivel | Qué cubre |
|---|---|
| Unitarias (`test/domain`) | Reparto con redondeo exacto, déficit, pesos personalizados, prorrateo de 14 pagas, mensajes de paga extra, saldos acumulados entre meses, estimación sin ingresos |
| Repositorios (`test/data`) | CRUD contra SQLite en memoria; generación de recurrentes idempotente; ajuste de día 31; migraciones |
| Widgets (`test/ui`) | Añadir movimiento actualiza Inicio; validación del formulario; aviso de déficit |
| Integración (`integration_test`) | Onboarding → añadir gasto → ver bolsas actualizadas |

Se escriben con TDD: primero el test, luego el código.

---

## 7. Privacidad

- Todos los datos se quedan en el dispositivo. Sin analítica, sin anuncios, sin permisos de red en v1.0.
- Borrado total de datos disponible en Ajustes.

---

## 8. Hoja de ruta

| Versión | Contenido |
|---|---|
| **v1.0 (MVP)** | Todo lo descrito en las secciones 1–7 |
| v1.1 | Presupuesto por categoría con avisos al 80 % y 100 %; exportar a CSV |
| v1.2 | Objetivos de ahorro con cuota mensual sugerida; fondo de emergencia (meta 3–6 meses de gastos fijos) |
| v1.3 | Notificaciones y recordatorios de pagos; widget de pantalla de inicio |
| v2.0 | Copia de seguridad y sincronización en la nube opcional; importar extracto bancario (CSV); modo pareja/hogar; simulador "¿y si…?" |

Cada versión añade tablas (migraciones Drift) y pantallas sin modificar el núcleo de `domain/calc`.
