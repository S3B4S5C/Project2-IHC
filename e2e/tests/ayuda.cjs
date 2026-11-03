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
  return { token, fecha, mascota };
}

async function abrirPanel(page, token) {
  await page.addInitScript((jwt) => {
    localStorage.setItem('flutter.jwt_token', JSON.stringify(jwt));
    localStorage.setItem('flutter.usuario_nombre', JSON.stringify('Prueba E2E'));
  }, token);
  await page.goto('/');
  await activarAccesibilidad(page);
  await expect(page.getByLabel('Mascota al Día - Panel')).toBeVisible();
}

async function activarAccesibilidad(page) {
  const boton = page.locator('flt-semantics-placeholder').first();
  await boton.waitFor({ state: 'attached' });
  await boton.evaluate((el) => el.click());
}

async function marcarRealizado(page) {
  await page.getByRole('button', { name: 'Marcar como realizado' }).click();
  await page.getByRole('button', { name: 'Marcar', exact: true }).click();
}

module.exports = { API, prepararCuidado, sumarDias, abrirPanel, activarAccesibilidad, marcarRealizado };
