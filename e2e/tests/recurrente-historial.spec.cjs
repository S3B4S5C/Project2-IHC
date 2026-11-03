const { test, expect } = require('@playwright/test');
const {
  API,
  prepararCuidado,
  sumarDias,
  abrirPanel,
  activarAccesibilidad,
  marcarRealizado,
} = require('./ayuda.cjs');

async function comprobarEvento(page, fecha) {
  const detalle = `Programado para el ${fecha}`;
  const evento = page.getByText(detalle).or(page.getByLabel(detalle));
  try {
    await expect(evento.filter({ visible: true }).first()).toBeVisible({ timeout: 10000 });
  } catch (error) {
    const etiquetas = await page.locator('flt-semantics').evaluateAll((nodos) =>
      nodos
        .map((nodo) => nodo.getAttribute('aria-label') || nodo.textContent?.trim())
        .filter(Boolean)
        .slice(0, 60),
    );
    console.log('Elementos de accesibilidad del historial:', etiquetas);
    throw error;
  }
}

test('dos realizaciones recurrentes permanecen en el historial tras recargar', async ({ page, request }) => {
  const { token, fecha, mascota, correo, password } = await prepararCuidado(request, 3);
  const segunda = sumarDias(fecha, 3);
  const tercera = sumarDias(segunda, 3);

  await abrirPanel(page, correo, password);
  await marcarRealizado(page);
  await expect(page.getByLabel(`Vacuna · ${segunda}`)).toBeVisible();
  await marcarRealizado(page);
  await expect(page.getByLabel(`Vacuna · ${tercera}`)).toBeVisible();

  const historial = await request.get(`${API}/historial/`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  expect(historial.ok()).toBeTruthy();
  const eventos = (await historial.json()).filter(
    (evento) => evento.mascota_id === mascota.id && evento.tipo === 'realizado',
  );
  expect(eventos).toHaveLength(2);
  expect(eventos.map((evento) => evento.detalle)).toEqual([
    `Programado para el ${segunda}`,
    `Programado para el ${fecha}`,
  ]);

  await page.getByRole('button', { name: 'Historial' }).click();
  await comprobarEvento(page, fecha);
  await comprobarEvento(page, segunda);

  await page.reload();
  await activarAccesibilidad(page);
  await page.getByRole('button', { name: 'Historial' }).click();
  await comprobarEvento(page, fecha);
  await comprobarEvento(page, segunda);
});
