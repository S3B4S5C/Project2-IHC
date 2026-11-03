const { test, expect } = require('@playwright/test');
const { API, prepararCuidado, sumarDias, abrirPanel, activarAccesibilidad, marcarRealizado } = require('./ayuda.cjs');

test('al realizar un cuidado recurrente se muestra y persiste la siguiente fecha', async ({ page, request }) => {
  const { token, fecha, mascota, correo, password } = await prepararCuidado(request, 7);
  const siguiente = sumarDias(fecha, 7);

  await abrirPanel(page, correo, password);
  await expect(page.getByLabel(`Vacuna · ${fecha}`)).toBeVisible();
  await expect(page.getByLabel('Cada 7 días')).toBeVisible();

  await marcarRealizado(page);
  await expect(page.getByLabel(`Vacuna · ${siguiente}`)).toBeVisible();
  await expect(page.getByRole('button', { name: 'Marcar como realizado' })).toBeVisible();

  await page.reload();
  await activarAccesibilidad(page);
  await expect(page.getByLabel(`Vacuna · ${siguiente}`)).toBeVisible();

  const lista = await request.get(`${API}/mascotas/lista`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  expect(lista.ok()).toBeTruthy();
  const cuidado = (await lista.json()).find((item) => item.id === mascota.id);
  expect(cuidado).toMatchObject({ fecha: siguiente, estado: false, periodicidad_dias: 7 });
});
