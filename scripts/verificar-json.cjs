// Verificación de respuestas REST para QA Docker. Solo módulos nativos de Node.
const assert = require('node:assert/strict');
const fs = require('node:fs');

function idValido(id) {
    assert.ok(Number.isSafeInteger(id) && id > 0, 'Identificador inválido');
    return id;
}

function idUnico(items, nombre) {
    assert.ok(Array.isArray(items), 'Se esperaba un arreglo');
    const encontrados = items.filter(item => item && item.nombre === nombre);
    assert.equal(encontrados.length, 1, 'Elemento esperado ausente o duplicado');
    return idValido(encontrados[0].id);
}

function codigoValido(codigo) {
    assert.ok(typeof codigo === 'string' && /^COT-\d{4}-\d{6,}$/.test(codigo), 'Código inválido');
    return codigo;
}

function verificar(accion, entrada, args = []) {
    switch (accion) {
        case 'catalogo':
            assert.ok(Array.isArray(entrada.equipos) && entrada.equipos.length === 3, 'Catálogo de equipos inesperado');
            assert.ok(Array.isArray(entrada.zonas) && entrada.zonas.length === 6, 'Catálogo de zonas inesperado');
            return idUnico(entrada.zonas, 'Lima Norte');
        case 'servicio':
            return idUnico(entrada, 'Diagnóstico técnico');
        case 'payload':
            assert.equal(args.length, 2);
            return JSON.stringify({
                tipoServicio: 'REPARACION', tipoCliente: 'HOGAR',
                zonaId: idValido(Number(args[0])),
                items: [{ productoId: idValido(Number(args[1])), cantidad: 1 }]
            });
        case 'codigo':
            return codigoValido(entrada.codigo);
        case 'persistencia':
            assert.equal(codigoValido(entrada.codigo), codigoValido(args[0]));
            assert.ok(Array.isArray(entrada.lineas) && entrada.lineas.length === 1, 'Detalle de cotización inesperado');
            return 'Cotización persistida correctamente.';
        default:
            throw new Error('Acción de QA desconocida');
    }
}

function autoprueba() {
    const catalogo = { equipos: [{}, {}, {}], zonas: [{ nombre: 'Lima Norte', id: 1 }, {}, {}, {}, {}, {}] };
    assert.equal(verificar('catalogo', catalogo), 1);
    assert.equal(verificar('servicio', [{ nombre: 'Diagnóstico técnico', id: 2 }]), 2);
    assert.deepEqual(JSON.parse(verificar('payload', null, ['1', '2'])), {
        tipoServicio: 'REPARACION', tipoCliente: 'HOGAR', zonaId: 1,
        items: [{ productoId: 2, cantidad: 1 }]
    });
    const codigo = 'COT-2026-000002';
    assert.equal(verificar('codigo', { codigo }), codigo);
    assert.match(verificar('persistencia', { codigo, lineas: [{}] }, [codigo]), /persistida/);
    assert.throws(() => verificar('catalogo', { equipos: [], zonas: [] }));
    assert.throws(() => verificar('servicio', []));
    assert.throws(() => verificar('servicio', [{ nombre: 'Diagnóstico técnico', id: '2' }]));
    assert.throws(() => verificar('servicio', [{ nombre: 'Diagnóstico técnico', id: 1 }, { nombre: 'Diagnóstico técnico', id: 2 }]));
    assert.throws(() => verificar('payload', null, ['0', '2']));
    assert.throws(() => verificar('codigo', { codigo: '../otro' }));
    assert.throws(() => verificar('persistencia', { codigo, lineas: [] }, [codigo]));
    assert.throws(() => verificar('persistencia', { codigo, lineas: [{}] }, ['COT-2026-000003']));
    return 'Autopruebas JSON: 13 comprobaciones aprobadas.';
}

try {
    // node -e recibe sus argumentos desde argv[1]; node archivo.cjs, desde argv[2].
    const [accion, ...args] = process.argv.slice(require.main === module ? 2 : 1);
    const resultado = accion === 'autoprueba'
        ? autoprueba()
        : verificar(accion, accion === 'payload' ? null : JSON.parse(fs.readFileSync(0, 'utf8')), args);
    console.log(resultado);
} catch (error) {
    // No imprimir cuerpos de API o datos de la cotización.
    console.error('Fallo de validación JSON (' + error.name + ').');
    process.exitCode = 1;
}
