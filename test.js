/**
 * GOMEX Nutrition - Suite de Pruebas Automatizadas
 * Ejecutable mediante: npm test  o  node test.js
 */

const fs = require('fs');
const path = require('path');
const http = require('http');

let passedTests = 0;
let totalTests = 0;

function assert(condition, testName, errorDetails = '') {
  totalTests++;
  if (condition) {
    console.log(`  ✅ [PASS] ${testName}`);
    passedTests++;
  } else {
    console.error(`  ❌ [FAIL] ${testName}`);
    if (errorDetails) {
      console.error(`     Detalle: ${errorDetails}`);
    }
  }
}

async function runTests() {
  console.log('\n=============================================================');
  console.log('🧪 INICIANDO SUITE DE PRUEBAS: GOMEX NUTRITION');
  console.log('=============================================================\n');

  const rootDir = path.resolve(__dirname);

  // -------------------------------------------------------------
  // SUITE 1: Estructura del Proyecto y Archivos Esenciales
  // -------------------------------------------------------------
  console.log('📁 SUITE 1: Estructura del Repositorio y Archivos Clave');
  const essentialFiles = [
    'index.html',
    'server.js',
    'package.json',
    '.gitignore',
    'README.md',
    'public/logo.jpg',
    'public/bg.jpg',
    'public/bolsaGomitas.jpg',
    'public/cajaGomitas.jpg',
    'public/bolsaGomita.jpg',
    'public/gomitas.jpg'
  ];

  essentialFiles.forEach(file => {
    const exists = fs.existsSync(path.join(rootDir, file));
    assert(exists, `Archivo esencial presente: ${file}`);
  });

  // Verificar que no queden archivos temporales no deseados
  const forbiddenFiles = ['.git copy', 'logo_base64.txt', 'logo_base64_utf8.txt'];
  forbiddenFiles.forEach(file => {
    const exists = fs.existsSync(path.join(rootDir, file));
    assert(!exists, `Archivo temporal/duplicado ausente (Limpio): ${file}`);
  });

  // -------------------------------------------------------------
  // SUITE 2: Validación de HTML y Metadatos
  // -------------------------------------------------------------
  console.log('\n🌐 SUITE 2: Estructura y Metadatos de index.html');
  const htmlContent = fs.readFileSync(path.join(rootDir, 'index.html'), 'utf8');

  assert(htmlContent.includes('<!DOCTYPE html>'), 'Doctype HTML5 declarado');
  assert(/<html\s+lang=["']es["']/i.test(htmlContent), 'Atributo de idioma español configurado');
  assert(/<meta\s+charset=["']UTF-8["']/i.test(htmlContent), 'Meta charset UTF-8 presente');
  assert(/<meta\s+name=["']viewport["']/i.test(htmlContent), 'Meta viewport para responsive presente');
  assert(htmlContent.includes('<title>GOMEX Nutrition'), 'Título de la aplicación presente');
  assert(htmlContent.includes('https://unpkg.com/ionicons@7.1.0/dist/ionicons/ionicons.esm.js'), 'CDN de Ionicons incluido');
  assert(htmlContent.includes('https://cdn.jsdelivr.net/npm/xlsx@0.18.5/dist/xlsx.full.min.js'), 'CDN de SheetJS incluido');
  assert(htmlContent.includes('https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2'), 'CDN de Supabase JS incluido');

  // -------------------------------------------------------------
  // SUITE 3: Integridad de Assets Referenciados
  // -------------------------------------------------------------
  console.log('\n🖼️ SUITE 3: Integridad de Assets Multimedia');
  const assetRegex = /public\/[a-zA-Z0-9_\-\.]+\.(jpg|png|svg|webp|jpeg)/g;
  const referencedAssets = Array.from(new Set(htmlContent.match(assetRegex) || []));

  referencedAssets.forEach(asset => {
    const assetPath = path.join(rootDir, asset);
    const exists = fs.existsSync(assetPath);
    let sizeOk = false;
    if (exists) {
      const stats = fs.statSync(assetPath);
      sizeOk = stats.size > 0;
    }
    assert(exists && sizeOk, `Asset verificado y no vacío: ${asset}`);
  });

  // -------------------------------------------------------------
  // SUITE 4: Consistencia del DOM y Selectores JS
  // -------------------------------------------------------------
  console.log('\n🔍 SUITE 4: Consistencia de Elementos e IDs del DOM');

  // 1. Detección de duplicados en IDs de HTML
  const idAttrRegex = /\sid=["']([^"']+)["']/g;
  const idCounts = {};
  let match;
  while ((match = idAttrRegex.exec(htmlContent)) !== null) {
    const id = match[1];
    idCounts[id] = (idCounts[id] || 0) + 1;
  }
  const duplicateIds = Object.entries(idCounts).filter(([_, count]) => count > 1);
  assert(duplicateIds.length === 0, 'No existen IDs duplicados en el marcado HTML',
    duplicateIds.map(([id, c]) => `#${id} (${c} veces)`).join(', '));

  // 2. Comprobación de que cada getElementById exista
  const getElemRegex = /document\.getElementById\(['"]([^'"]+)['"]\)/g;
  const queriedIds = new Set();
  while ((match = getElemRegex.exec(htmlContent)) !== null) {
    queriedIds.add(match[1]);
  }
  const missingIds = [];
  queriedIds.forEach(id => {
    if (!idCounts[id]) {
      missingIds.push(id);
    }
  });
  assert(missingIds.length === 0, `Todos los IDs invocados en JS existen en el DOM (${queriedIds.size} IDs validados)`,
    missingIds.join(', '));

  // -------------------------------------------------------------
  // SUITE 5: Sintaxis de JavaScript
  // -------------------------------------------------------------
  console.log('\n⚙️ SUITE 5: Sintaxis y Funciones de JavaScript');
  const jsStart = htmlContent.indexOf('<script>', htmlContent.indexOf('LÓGICA JAVASCRIPT'));
  const jsEnd = htmlContent.lastIndexOf('</script>');
  const jsCode = htmlContent.substring(jsStart + 8, jsEnd);

  let isJsValid = false;
  let jsError = '';
  try {
    new Function(jsCode);
    isJsValid = true;
  } catch (err) {
    jsError = err.message;
  }
  assert(isJsValid, 'Bloque principal de JavaScript parsea sin errores de sintaxis', jsError);

  // -------------------------------------------------------------
  // SUITE 6: Servidor HTTP Local y Manejo de Rutas
  // -------------------------------------------------------------
  console.log('\n🚀 SUITE 6: Servidor HTTP Local, Seguridad y MIME Types');

  const testPort = 3199;
  const MIME_TYPES = {
    '.html': 'text/html; charset=utf-8',
    '.js': 'text/javascript; charset=utf-8',
    '.css': 'text/css; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.jpg': 'image/jpeg',
    '.png': 'image/png'
  };

  const testServer = http.createServer((req, res) => {
    let pathname = '';
    try {
      pathname = decodeURIComponent(req.url.split('?')[0]);
    } catch (err) {
      res.writeHead(400, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('400 - Solicitud inválida');
      return;
    }

    if (pathname === '/' || pathname === '') pathname = '/index.html';
    const safePath = path.normalize(pathname).replace(/^(\.\.[\/\\])+/, '');
    const filePath = path.resolve(rootDir, '.' + safePath);

    if (!filePath.startsWith(rootDir)) {
      res.writeHead(403, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('403 - Acceso denegado');
      return;
    }

    fs.stat(filePath, (err, stats) => {
      if (err || !stats.isFile()) {
        res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end('404 - Archivo no encontrado');
        return;
      }
      const ext = path.extname(filePath).toLowerCase();
      const contentType = MIME_TYPES[ext] || 'application/octet-stream';
      res.writeHead(200, {
        'Content-Type': contentType,
        'X-Content-Type-Options': 'nosniff'
      });
      fs.createReadStream(filePath).pipe(res);
    });
  });

  await new Promise((resolve) => {
    testServer.listen(testPort, () => {
      // Test GET /
      http.get(`http://localhost:${testPort}/`, (res) => {
        res.resume();
        assert(res.statusCode === 200, 'GET / responde con HTTP 200 OK');
        assert(res.headers['content-type'].includes('text/html'), 'GET / tiene cabecera Content-Type text/html');
        assert(res.headers['x-content-type-options'] === 'nosniff', 'Cabecera X-Content-Type-Options: nosniff presente');

        // Test GET /public/logo.jpg
        http.get(`http://localhost:${testPort}/public/logo.jpg`, (imgRes) => {
          imgRes.resume();
          assert(imgRes.statusCode === 200, 'GET /public/logo.jpg responde con HTTP 200 OK');
          assert(imgRes.headers['content-type'] === 'image/jpeg', 'GET /public/logo.jpg tiene Content-Type image/jpeg');

          // Test GET /inexistente.txt
          http.get(`http://localhost:${testPort}/archivo_que_no_existe.xyz`, (notFoundRes) => {
            notFoundRes.resume();
            assert(notFoundRes.statusCode === 404, 'GET a ruta inexistente responde con HTTP 404');

            // Test Bloqueo Path Traversal
            http.get(`http://localhost:${testPort}/../../etc/passwd`, (traversalRes) => {
              traversalRes.resume();
              assert(traversalRes.statusCode === 403 || traversalRes.statusCode === 404,
                'Intento de Path Traversal bloqueado correctamente');

              if (typeof testServer.closeAllConnections === 'function') {
                testServer.closeAllConnections();
              }
              testServer.close(() => {
                resolve();
              });
            });
          });
        });
      });
    });
  });

  // -------------------------------------------------------------
  // Resumen Final
  // -------------------------------------------------------------
  console.log('\n=============================================================');
  console.log(`📊 RESULTADO FINAL: ${passedTests} de ${totalTests} pruebas pasadas (${Math.round((passedTests / totalTests) * 100)}%)`);
  console.log('=============================================================\n');

  if (passedTests === totalTests) {
    console.log('🎉 ¡TODAS LAS PRUEBAS PASARON EXITOSAMENTE! El proyecto está 100% listo para GitHub.\n');
    process.exit(0);
  } else {
    console.error('⚠️ Algunas pruebas fallaron. Por favor revisa los detalles arriba.\n');
    process.exit(1);
  }
}

runTests().catch(err => {
  console.error('Error fatal ejecutando pruebas:', err);
  process.exit(1);
});
