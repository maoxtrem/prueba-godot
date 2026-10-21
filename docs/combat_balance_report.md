# Último Refugio — Informe de integración y balance de combate

Fecha de auditoría: 2026-10-21

## Alcance y método

Se revisaron los componentes de ataque, salud, movimiento, equipamiento,
armas, durabilidad, reparación, munición, proyectiles, enemigos, oleadas,
recompensas, mejoras, tienda, guardado y DebugSettings.

Los resultados marcados como **ejecutados** proceden de las suites headless.
Los valores de DPS y costes por unidad son cálculos teóricos a partir de los
recursos `.tres`; no representan una partida observada. La precisión real de
las armas a distancia, los impactos enemigos y el comportamiento visual de la
interfaz requieren validación manual.

## Estado actual

- `AttackComponent` centraliza el cálculo de daño, alcance, cooldown y costes.
- `WeaponInstance` conserva `instance_id`, nivel y durabilidad por ejemplar.
- `WeaponStats` y `WeaponCostConfig` son recursos compartidos de solo
  configuración; las mejoras y la durabilidad no los mutan.
- `AmmoManager` usa `InventoryComponent` y revierte una compra si la
  transacción de inventario falla.
- Los proyectiles excluyen a su atacante, aplican un único impacto por objetivo
  y se destruyen al impactar o superar su alcance.
- `GameManager` bloquea ataques, oleadas y recompensas fuera de `PLAYING`.
- `SaveSerializer` guarda IDs, niveles, durabilidad, munición, mejoras,
  misiones, oleada, HP y efectos temporales; no serializa proyectiles activos.

No se encontró un defecto funcional demostrable que justificara cambiar el
balance o las mecánicas durante esta auditoría. No se modificaron combate,
economía, oleadas ni persistencia.

## Tabla comparativa

| Arma | Tipo | Daño | Alcance | Cooldown | DPS teórico | HP/ataque | Durabilidad/ataque | Munición |
|---|---|---:|---:|---:|---:|---:|---:|---|
| Ataque básico | cuerpo a cuerpo | 10 | 150 | 0.40 s | 25.00 | 3 | — | — |
| Daga vital | MELEE_SHORT | 8 | 75 | 0.25 s | 32.00 | 1 | 1 | — |
| Espada oxidada | MELEE_SHORT | 18 | 100 | 0.60 s | 30.00 | 5 | 1 | — |
| Lanza carmesí | MELEE_LONG | 25 | 180 | 0.90 s | 27.78 | 8 | 2 | — |
| Ballesta | RANGED | 25 | 400 | 1.20 s | 20.83 | 0 | — | 1 virote |
| Pistola | RANGED | 12 | 500 | 0.35 s | 34.29 | 0 | — | 1 bala |

El DPS es `daño / cooldown` y supone ataques o impactos continuos. No incluye
fallos, movimiento, cooldown global ni disponibilidad de objetivos.

Modificadores conocidos:

- Nivel individual de arma `+n`: `daño base × (1 + 0.10 × n)`.
- Mejoras de daño del personaje y efectos temporales se multiplican con el
  multiplicador de instancia, sin modificar `WeaponStats`.
- La munición comprada tiene coste indirecto de `0.5 HP/virote` y
  `0.6 HP/bala`. Ese coste no es HP descontado al disparar.

## Economía de HP

El coste de movimiento es `distancia × 0.01 × multiplicadores efectivos`.
Los desplazamientos nulos o negativos no cobran HP y permanecer quieto no
genera gasto.

Los costes directos por ataque son los de la tabla. Las compras verifican que
el jugador conserve HP positivo; la munición y las mejoras no se cobran si la
operación falla. Las recompensas y curaciones están limitadas por la vida
máxima.

No se inventaron resultados numéricos de escenarios A–F porque una simulación
completa depende de distancia recorrida, aciertos, enemigos alcanzados,
recompensas aleatorias y decisiones del jugador. Los escenarios reproducibles
existentes cubren los componentes por separado:

- Ataque básico, daga, espada, lanza y durabilidad: `weapon_stats_test`,
  `weapon_durability_test` y `weapon_config_test`.
- Ballesta, munición, fallo de disparo y estados pausados:
  `ranged_combat_test` y `ammo_test`.
- Movimiento y regeneración: `player_idle_integration_test` y
  `regeneration_test`.

## Integración verificada

Se verificó cobertura para:

- Progresión de oleadas 3, 5, 7… y punto seguro.
- Eliminaciones, recompensas, drops y regeneración enemiga.
- Ataques melee y ranged, cooldown, durabilidad y munición.
- Bloqueo durante pausa, BETWEEN_WAVES y GAME_OVER.
- Equipamiento, reemplazo, niveles individuales y reparación.
- Inventario, tienda, misiones y controles modales.
- Serialización y restauración de armas equipadas/almacenadas, IDs, niveles,
  durabilidad, munición, mejoras, pociones, efectos, misiones, oleada y HP.

## Pruebas ejecutadas

Se ejecutaron 28 suites headless, con 497 comprobaciones correctas en total.
Incluyen `ranged_combat_test`, `ammo_test`, `weapon_repair_test`,
`save_test`, `modal_controls_test`, `upgrade_shop_test`, las pruebas de
oleadas, inventario, equipo, mejoras, quests, drops, DebugSettings y la
regresión existente.

También se comprobó la carga de las escenas y `git diff --check`.

Los mensajes de Godot sobre `user://logs` y el error JSON de `save_test` son
esperados por el entorno de ejecución y por la prueba de archivo corrupto;
las suites terminaron correctamente.

## Riesgos y recomendaciones

1. Medir con jugadores reales la precisión y la tasa de acierto de ballesta y
   pistola antes de cambiar sus costes.
2. Observar el ritmo de recuperación de HP frente al gasto combinado de
   movimiento, ataques, compras y daño recibido.
3. Evaluar la durabilidad en sesiones largas, especialmente para lanza y
   espada.
4. Realizar una prueba visual de controles y proyectiles en 1152×648; las
   pruebas headless no certifican distribución ni clic físico.
5. No aplicar ajustes de balance hasta disponer de mediciones reproducibles y
   autorización explícita.

## Checklist manual pendiente

- Probar apuntado y movimiento simultáneos con ratón real.
- Confirmar impactos y fallos de proyectiles a distintas velocidades.
- Comprobar clic físico en cerrar tienda, reparar y comprar.
- Repetir los escenarios A–F con registros de HP, aciertos, recompensas,
  munición, fragmentos y durabilidad.
- Validar visualmente inventario, tienda, punto seguro y GAME_OVER en
  1152×648, 1280×720 y 1920×1080.

No se implementan las recomendaciones ni se inicia una fase posterior.
