# Configuración de Base de Datos Supabase ⚡

Este directorio contiene los scripts SQL necesarios para inicializar y migrar la base de datos PostgreSQL de **GOMEX Nutrition** en tu proyecto de Supabase.

---

## 📌 Datos del Proyecto

- **Project URL:** `https://jdhscjhashyqmnmuksuk.supabase.co`
- **Project ID / Reference:** `jdhscjhashyqmnmuksuk`
- **Dashboard URL:** [https://supabase.com/dashboard/project/jdhscjhashyqmnmuksuk](https://supabase.com/dashboard/project/jdhscjhashyqmnmuksuk)
- **SQL Editor:** [https://supabase.com/dashboard/project/jdhscjhashyqmnmuksuk/sql/new](https://supabase.com/dashboard/project/jdhscjhashyqmnmuksuk/sql/new)

---

## 🚀 Pasos para inicializar la Base de Datos

### 1. Ejecutar el Script SQL en Supabase
1. Ingresá a tu proyecto en el panel de Supabase: [SQL Editor](https://supabase.com/dashboard/project/jdhscjhashyqmnmuksuk/sql/new).
2. Abrí el archivo [`supabase/schema.sql`](./schema.sql) de este repositorio.
3. Copiá todo su contenido y pegalo en el editor SQL de Supabase.
4. Hacé clic en **"Run"** (o presiona `Ctrl + Enter`).
5. Verificá que aparezca el mensaje `"Success. No rows returned"` o que las tablas se hayan creado correctamente en el **Table Editor**.

---

### 2. Obtener tu Anon Public API Key
1. En el panel de Supabase, dirigite a: **Project Settings** (icono de engranaje ⚙️) ➔ **API**.
2. Buscá la sección **Project API keys** y copiá la clave **`anon` `public`**.

---

### 3. Conectar la Aplicación Web
1. Abrí la aplicación web GOMEX Nutrition en tu navegador (`http://localhost:3000` o tu URL en producción).
2. Hacé clic en el botón con el icono de nube verde/amarillo en el encabezado superior (**Supabase Cloud**) o en **Configuración ➔ Supabase Cloud**.
3. Verificá que la URL sea:
   ```text
   https://jdhscjhashyqmnmuksuk.supabase.co
   ```
4. Pegá tu **Anon Public Key** en el campo correspondiente.
5. Hacé clic en **"Probar y Guardar Conexión"**.
6. ¡Listo! El indicador cambiará a **🟢 Online** y todos los productos, ventas, clientes y configuraciones se sincronizarán en tiempo real.

---

## 📊 Tablas Creadas por el Script

| Tabla | Descripción | Tiempo Real (Realtime) |
|---|---|:---:|
| `products` | Catálogo de productos, stock, precios, imágenes y activos | ✅ Activo |
| `categories` | Categorías nutricionales del e-commerce | ✅ Activo |
| `clients` | Padrón de clientes y datos fiscales (CUIT) | ✅ Activo |
| `sales` | Historial de transacciones y tickets POS | ✅ Activo |
| `collaborators` | Usuarios del sistema y control de roles | ✅ Activo |
| `offers` | Descuentos y promociones destacadas | ✅ Activo |
| `expenses` | Registro de gastos y movimientos de caja | ✅ Activo |
| `store_config` | Datos comerciales de la tienda y cuentas bancarias | ✅ Activo |
