# GOMEX Nutrition ⚡

Plataforma integral de **E-Commerce** y **Sistema POS (Punto de Venta) / Gestión Comercial** desarrollada para la comercialización de suplementos nutricionales y gomitas funcionales de alto rendimiento.

---

## 🌟 Características Principales

### 🛒 1. Tienda E-Commerce
- **Catálogo Interactivo**: Filtrado por categorías nutricionales (*Rendimiento & Fuerza*, *Salud & Inmunidad*, *Descanso & Bienestar*, *Combos & Packs*) y búsqueda en tiempo real.
- **Detalle de Producto**: Información técnica, tabla de activos, porciones recomendadas, beneficios y galería de imágenes.
- **Carrito de Compras**: Cálculo en tiempo real de subtotales, descuentos y costos de envío.
- **Checkout Inteligente**:
  - Pasarela para pago directo por **Mercado Pago** y **Transferencia Bancaria (CBU/CVU)** con generación de comprobante y QR.
  - Envío automático de orden de pedido detallada vía **WhatsApp**.

### 💼 2. Sistema POS (Punto de Venta) & Facturación
- **Terminal de Ventas Rápida (Punto POS)**: Facturación ágil con soporte para lector de código de barras, selección táctil de artículos y cobro express.
- **Historial de Ventas**: Registro detallado de todas las transacciones realizadas tanto en tienda física como e-commerce, con desglose de comprobantes, medio de pago y reimpresión de tickets.
- **Presupuestos Rápidos**: Generación y conversión de presupuestos a ventas en un solo clic.
- **Gestión de Clientes & CUIT**: Padrón de clientes con asignación de condición fiscal.
- **Múltiples Medios de Pago**: Efectivo, Débito, Crédito, Mercado Pago, Transferencia y Cuenta Corriente.
- **Cierre de Caja (Reporte Z)**: Apertura y cierre de turnos, arqueo de valores y registro de movimientos de caja chica.

### 📦 3. Catálogo & Fórmulas
- **Gestión de Artículos**: Alta, edición y actualización de productos, precios y propiedades nutricionales.
- **Cálculo Automático de Rentabilidad**: Desglose de Costo sin IVA, Margen de Utilidad y Precio Final.
- **Importación / Exportación Masiva**: Soporte de planillas Excel (`.xlsx`, `.xls`) y CSV mediante SheetJS.

### ☁️ 4. Sincronización en la Nube con Supabase
- **Persistencia Híbrida**: Almacenamiento local ultrarrápido (`localStorage`) con sincronización bidireccional en tiempo real a base de datos PostgreSQL en la nube (**Supabase Cloud**).
- **Control de Acceso por Roles (RBAC)**: Perfiles protegidos para Super Administrador, Administrador, Cajeros y Vendedores con permisos granulares.

---

## 🛠️ Tecnologías Utilizadas

- **Frontend**: HTML5 Semántico, CSS3 Moderno (Glassmorphism, CSS Custom Properties, Responsive Design Mobile-First), JavaScript Vanilla (ES6+).
- **Backend / Servidor**: Node.js (Servidor HTTP nativo de cero dependencias con prevención de Path Traversal y cabeceras de seguridad).
- **Base de Datos & Nube**: Supabase (PostgreSQL Cloud + WebSockets Realtime).
- **Librerías CDN**:
  - [Ionicons](https://ionic.io/ionicons) para iconografía de alta fidelidad.
  - [SheetJS (xlsx)](https://sheetjs.com/) para procesamiento de archivos Excel.
  - [Google Fonts](https://fonts.google.com/specimen/Plus+Jakarta+Sans) (Plus Jakarta Sans).

---

## 🚀 Inicio Rápido

### Requisitos Previos
- [Node.js](https://nodejs.org/) (versión 16 o superior recomendada).

### Instalación y Ejecución

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/tu-usuario/gomexnutrition.git
   cd gomexnutrition
   ```

2. **Iniciar el servidor local:**
   ```bash
   npm start
   ```
   *O alternativamente con Node directamente:*
   ```bash
   node server.js
   ```

3. **Abrir en el navegador:**
   Acceder a [http://localhost:3000](http://localhost:3000)

---

## 🧪 Pruebas Automatizadas

El proyecto cuenta con una suite integral de pruebas para asegurar la calidad del código, integridad de assets, ausencia de selectores huérfanos y respuesta del servidor HTTP:

```bash
npm test
```

---

## 📂 Estructura del Proyecto

```text
gomexnutrition/
├── public/                 # Recursos multimedia estáticos
│   ├── bg.jpg              # Fondo principal del tema visual
│   ├── logo.jpg            # Isologotipo oficial de la marca
│   ├── bolsaGomitas.jpg    # Imagen de Creatina
│   ├── cajaGomitas.jpg     # Imagen de Multivitamínico
│   ├── bolsaGomita.jpg     # Imagen de Sleep & Recovery
│   └── gomitas.jpg         # Imagen de Pack Trío
├── supabase/               # Scripts SQL y migraciones de Supabase PostgreSQL
│   ├── schema.sql          # DDL completo, tablas, RLS, Realtime y Seeds
│   └── README.md           # Guía de inicialización de Base de Datos
├── index.html              # Aplicación SPA completa (E-Commerce + POS)
├── server.js               # Servidor HTTP local con seguridad reforzada
├── test.js                 # Suite automatizada de pruebas
├── package.json            # Metadatos del proyecto y scripts
├── .gitignore              # Reglas de exclusión de Git
└── README.md               # Documentación del proyecto
```

---

## 🔒 Seguridad y Buenas Prácticas

- **Control de Acceso**: El ingreso a las funciones operativas y administrativas del POS está restringido y protegido mediante autenticación de colaboradores. Las cuentas y permisos se administran desde el panel de colaboradores de la empresa.
- **Protección de Servidor**: El servidor Node.js incluye validación y sanitización de rutas, cabeceras `X-Content-Type-Options: nosniff` y `X-Frame-Options: SAMEORIGIN`.
- **Datos Seguros**: Los parámetros de conexión y variables locales se gestionan mediante almacenamiento local y variables de entorno no versionadas.

---

## 📄 Licencia

Este proyecto está bajo la Licencia MIT.
