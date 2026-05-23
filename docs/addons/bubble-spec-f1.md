---
title: Addons F1 — Spec Bubble
dominio: addons
estado: en-construccion
actualizado: 2026-05-08
tags: [addons, bubble, fase-1]
---

# Bubble F1 — Spec mínima

## Option Sets (ya creados)
- `categoria_addon` — gestor_tareas / erp / crm / time_tracking / storage / reuniones
- `estado_implementacion_addon` — pendiente / en_implementacion / completado / cancelado

## Data Types

### `Addons_Catalogo`
| Field | Type | List |
|---|---|---|
| slug | text | no |
| nombre | text | no |
| categoria | categoria_addon | no |
| precio_eur | number | no |
| descripcion | text | no |
| campos_credenciales_json | text | no |
| plantilla_onboarding_id | text | no |
| stripe_price_id | text | no |
| activo | yes/no | no |
| orden | number | no |

### `Addons_Agencia`
| Field | Type | List |
|---|---|---|
| agencia | Agencia | no |
| addon_catalogo | Addons_Catalogo | no |
| estado | estado_implementacion_addon | no |
| precio_original_eur | number | no |
| precio_pagado_eur | number | no |
| codigo_descuento_aplicado | text | no |
| stripe_session_id | text | no |
| fecha_compra | date | no |
| fecha_completado | date | no |
| tarea_onboarding_id | text | no |
| last_test_result | text | no |
| notas | text | no |

### `Addons_Codigos_Descuento`
| Field | Type | List |
|---|---|---|
| codigo | text | no |
| descuento_porcentaje | number | no |
| categorias_aplicables | categoria_addon | **yes** |
| addon_slugs_aplicables | text | no |
| validez_fin | date | no |
| usos_max | number | no |
| usos_actuales | number | no |
| activo | yes/no | no |
| stripe_coupon_id | text | no |
| notas_internas | text | no |

## Importar CSV
1. `Addons_Catalogo` → Upload data → `bubble-import-addons-catalogo.csv` (10 cols, 34 filas).
2. Mapear `categoria` por atributo `slug`.

## DB Triggers (3)
Para cada Data Type, evento `is created or modified` → API Connector `Espejo a Supabase` con body `{tabla, bubble_id}`:
- `Addons_Catalogo` → `bub_addons_catalogo`
- `Addons_Agencia` → `bub_addons_agencia`
- `Addons_Codigos_Descuento` → `bub_addons_codigos_descuento`

## Código de prueba
Crear en `Addons_Codigos_Descuento`:
- codigo: `CodigoZenyx`
- descuento_porcentaje: `100`
- usos_max: `50`
- validez_fin: `2026-12-31`
- activo: yes

## Done
Avísame "FASE 1 lista" → arranco F2 (verificación + ALLOWED_TABLES + workflow descuentos).
