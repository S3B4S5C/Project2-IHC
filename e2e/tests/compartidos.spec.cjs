const { test, expect } = require('@playwright/test');
const { API, abrirPanel, marcarRealizado } = require('./ayuda.cjs');

test('invitacion aceptada, consulta, gestion, revocacion e historial con autor', async ({ browser, request }) => {
  const sufijo = Date.now().toString(36);
  const password = 'E2ePrueba123';

  async function usuario(nombre, tipo) {
    const correo = 'compartido-' + tipo + '-' + sufijo + '@example.com';
    const registro = await request.post(API + '/usuarios/registro', {
      data: { nombre, correo, password },
    });
    expect(registro.status()).toBe(201);
    const login = await request.post(API + '/usuarios/login', { data: { correo, password } });
    expect(login.status()).toBe(200);
    const token = (await login.json()).access_token;
    return { nombre, correo, password, token };
  }

  const dueno = await usuario('Dueño E2E', 'dueno');
  const responsable = await usuario('Responsable E2E', 'responsable');
  const invitada = await usuario('Invitada E2E', 'invitada');
  const fecha = new Date();
  fecha.setDate(fecha.getDate() + 5);
  const programada = [
    fecha.getFullYear(),
    String(fecha.getMonth() + 1).padStart(2, '0'),
    String(fecha.getDate()).padStart(2, '0'),
  ].join('-');

  const crear = await request.post(API + '/mascotas/crear', {
    headers: { Authorization: 'Bearer ' + dueno.token },
    data: {
      nombre: 'Luna',
      tipo: 'Perro',
      cuidado: 'Vacuna',
      fecha: programada,
      responsable_correo: responsable.correo,
      periodicidad_dias: 3,
    },
  });
  expect(crear.status()).toBe(200);
  const cuidado = await crear.json();

  const contextoResponsable = await browser.newContext();
  const paginaResponsable = await contextoResponsable.newPage();
  await abrirPanel(paginaResponsable, responsable.correo, responsable.password);
  await paginaResponsable.getByRole('button', { name: 'Cuidados compartidos e invitaciones' }).click();
  const correoInput = paginaResponsable.getByLabel('Correo de usuario registrado');
  await correoInput.click();
  await paginaResponsable.waitForTimeout(200);
  await correoInput.fill('');
  await correoInput.pressSequentially(invitada.correo, { delay: 25 });
  await expect(correoInput).toHaveValue(invitada.correo);

  const invitacionRespuesta = paginaResponsable.waitForResponse(
    (respuesta) => respuesta.url().endsWith('/compartidos/invitar') &&
      respuesta.request().method() === 'POST'
  );
  await paginaResponsable.getByRole('button', { name: 'Enviar invitación' }).click();
  const invitacionHttp = await invitacionRespuesta;
  expect(invitacionHttp.status()).toBe(201);
  const invitacion = await invitacionHttp.json();

  const contextoInvitada = await browser.newContext();
  const paginaInvitada = await contextoInvitada.newPage();
  await abrirPanel(paginaInvitada, invitada.correo, invitada.password);
  await paginaInvitada.getByRole('button', { name: 'Cuidados compartidos e invitaciones' }).click();
  await expect(paginaInvitada.getByText('Pendiente de respuesta')).toBeVisible();
  await paginaInvitada.getByRole('button', { name: 'Aceptar' }).click();
  await expect(paginaInvitada.getByText('Estado: Aceptada')).toBeVisible();

  await paginaInvitada.reload();
  await expect(paginaInvitada.getByText('Compartido: solo consulta')).toBeVisible();
  await expect(paginaInvitada.getByRole('button', { name: 'Marcar como realizado' })).toHaveCount(0);
  const denegado = await request.put(API + '/mascotas/' + cuidado.id + '/completar', {
    headers: { Authorization: 'Bearer ' + invitada.token },
  });
  expect(denegado.status()).toBe(403);

  const cambiar = await request.patch(API + '/compartidos/' + invitacion.id + '/permiso', {
    headers: { Authorization: 'Bearer ' + responsable.token },
    data: { permiso: 'gestion' },
  });
  expect(cambiar.status()).toBe(200);

  await paginaInvitada.reload();
  await expect(paginaInvitada.getByText('Compartido: gestión')).toBeVisible();
  await marcarRealizado(paginaInvitada);

  const historial = await request.get(API + '/historial/', {
    headers: { Authorization: 'Bearer ' + dueno.token },
  });
  expect(historial.status()).toBe(200);
  const eventos = (await historial.json()).filter(
    (evento) => evento.mascota_id === cuidado.id && evento.tipo === 'realizado'
  );
  expect(eventos).toHaveLength(1);
  expect(eventos[0].autor_id).toBeDefined();
  expect(eventos[0].autor_nombre).toBe('Invitada E2E');
  expect(eventos[0].fecha_hora).toBeTruthy();

  const revocacion = await request.post(API + '/compartidos/' + invitacion.id + '/revocar', {
    headers: { Authorization: 'Bearer ' + responsable.token },
  });
  expect(revocacion.status()).toBe(200);

  await paginaInvitada.reload();
  await expect(paginaInvitada.getByText('Compartido: gestión')).toHaveCount(0);
  const historialPosterior = await request.get(API + '/historial/', {
    headers: { Authorization: 'Bearer ' + dueno.token },
  });
  expect(historialPosterior.status()).toBe(200);
  expect((await historialPosterior.json()).some((evento) =>
    evento.mascota_id === cuidado.id && evento.autor_nombre === 'Invitada E2E'
  )).toBe(true);

  await contextoResponsable.close();
  await contextoInvitada.close();
});
