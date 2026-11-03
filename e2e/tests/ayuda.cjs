const { expect } = require('@playwright/test');

const API = process.env.API_URL || 'http://127.0.0.1:8000/api';

function sumarDias(fecha, dias) {
  const valor = new Date(`${fecha}T12:00:00Z`);
  valor.setUTCDate(valor.getUTCDate() + dias);
  return valor.toISOString().slice(0, 10);
}

function fechaFutura() {
  const hoy = new Date();
  const fecha = new Date(hoy.getFullYear(), hoy.getMonth(), hoy.getDate() + 5);
  return `${fecha.getFullYear()}-${String(fecha.getMonth() + 1).padStart(2, '0')}-${String(fecha.getDate()).padStart(2, '0')}`;
}

async function prepararCuidado(request, periodicidadDias) {
  const correo = `e2e-${Date.now()}-${Math.random().toString(36).slice(2, 8)}@example.com`;
  const password = 'E2ePrueba123';
  const registro = await request.post(`${API}/usuarios/registro`, {
    data: { nombre: 'Prueba E2E', correo, password },
  });
  expect(registro.status()).toBe(201);

  const login = await request.post(`${API}/usuarios/login`, {
    data: { correo, password },
  });
  expect(login.ok()).toBeTruthy();
  const { access_token: token } = await login.json();

  const fecha = fechaFutura();
  const creacion = await request.post(`${API}/mascotas/crear`, {
    headers: { Authorization: `Bearer ${token}` },
    data: {
      nombre: 'Luna',
      tipo: 'Perro',
      cuidado: 'Vacuna',
      fecha,
      responsable_correo: correo,
      periodicidad_dias: periodicidadDias,
    },
  });
  expect(creacion.ok()).toBeTruthy();
  const mascota = await creacion.json();
  return { token, fecha, mascota, correo, password };
}

async function escribirCampo(page, campo, valor) {
  await campo.click();
  await expect(campo).toBeFocused();
  await page.waitForTimeout(200);
  await campo.fill('');
  await campo.pressSequentially(valor, { delay: 25 });
  await expect(campo).toHaveValue(valor);
}

async function abrirPanel(page, correo, password) {
  page.on('pageerror', (error) => console.error(`[Flutter web] ${error.message}`));
  const response = await page.goto('/');
  expect(response?.ok()).toBeTruthy();
  await activarAccesibilidad(page);

  const campoCorreo = page.getByLabel('Correo electrónico');
  const campoPassword = page.getByLabel('Contraseña');
  await expect(campoCorreo).toBeVisible({ timeout: 45000 });
  await escribirCampo(page, campoCorreo, correo);
  await escribirCampo(page, campoPassword, password);

  const loginResponse = page.waitForResponse(
    (response) => response.url().endsWith('/usuarios/login') && response.request().method() === 'POST',
    { timeout: 15000 },
  );
  await page.getByRole('button', { name: 'Ingresar' }).click();
  const respuesta = await loginResponse;
  const enviado = respuesta.request().postDataJSON();
  expect(enviado.correo, 'El correo enviado por Flutter no coincide').toBe(correo);
  expect(enviado.password === password, 'La contraseña enviada por Flutter no coincide').toBe(true);
  expect(respuesta.status(), `El login HTTP falló: ${await respuesta.text()}`).toBe(200);
  await expect(page.getByRole('button', { name: 'Historial' })).toBeVisible({ timeout: 15000 });
}

async function activarAccesibilidad(page) {
  const boton = page.locator('flt-semantics-placeholder').first();
  if (await boton.count()) await boton.evaluate((el) => el.click());
  await expect.poll(() => page.locator('flt-semantics').count(), {
    message: 'Flutter web no expuso el árbol de accesibilidad',
    timeout: 45000,
  }).toBeGreaterThan(0);
}

async function marcarRealizado(page) {
  await page.getByRole('button', { name: 'Marcar como realizado' }).click();
  await page.getByRole('button', { name: 'Marcar', exact: true }).click();
}

module.exports = { API, prepararCuidado, sumarDias, abrirPanel, activarAccesibilidad, marcarRealizado };
