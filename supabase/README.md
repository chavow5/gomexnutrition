# Configuración de Base de Datos Supabase ⚡

Este directorio contiene los scripts SQL necesarios para inicializar y migrar la base de datos PostgreSQL de **GOMEX Nutrition** en tu proyecto de Supabase.

---

## 📌 Datos del Proyecto

- **Project URL:** `https://vdghijvwhrbiorytnpof.supabase.co`
- **Project ID / Reference:** `vdghijvwhrbiorytnpof`
- **Dashboard URL:** [https://supabase.com/dashboard/project/vdghijvwhrbiorytnpof](https://supabase.com/dashboard/project/vdghijvwhrbiorytnpof)
- **SQL Editor:** [https://supabase.com/dashboard/project/vdghijvwhrbiorytnpof/sql/new](https://supabase.com/dashboard/project/vdghijvwhrbiorytnpof/sql/new)

---

## 🔒 Arquitectura de Seguridad y Contraseñas (pgcrypto / bcrypt)

Para garantizar la máxima seguridad en los accesos de administradores y vendedores del sistema POS:

1. **Hasheo Criptográfico:** Se utiliza la extensión PostgreSQL `pgcrypto` con el algoritmo `Blowfish (bcrypt)` (`$2a$10$...`) y salting dinámico por usuario.
2. **Trigger Automático:** La tabla `collaborators` posee el trigger `trg_hash_collaborator_password` que detecta e intercepta cualquier clave en texto plano antes de persistirla, transformándola en hash bcrypt unidireccional.
3. **RPC `login_collaborator(p_username, p_password)`:** La validación se ejecuta enteramente en el motor PostgreSQL. Si las credenciales coinciden, retorna el perfil y permisos del usuario sin exponer jamás el hash ni la contraseña al cliente web.
4. **RPC `admin_upsert_collaborator(...)`:** Permite crear y actualizar usuarios del staff de forma segura. Al editar, si el campo de contraseña se deja vacío, la clave existente se preserva automáticamente sin necesidad de reingresarla.
5. **Protección en el Cliente:** El frontend nunca consulta ni almacena en memoria la columna `password`.

---

## 🚀 Pasos para inicializar la Base de Datos

### 1. Ejecutar el Script SQL en Supabase
1. Ingresá a tu proyecto en el panel de Supabase: [SQL Editor](https://supabase.com/dashboard/project/vdghijvwhrbiorytnpof/sql/new).
2. Abrí el archivo [`supabase/schema.sql`](./schema.sql) de este repositorio.
3. Copiá todo su contenido y pegalo en el editor SQL de Supabase.
4. Hacé clic en **"Run"** (o presiona `Ctrl + Enter`).
5. Verificá que aparezca el mensaje `"Success. No rows returned"` o que las tablas y funciones RPC se hayan creado correctamente en el **Table Editor** y **Database Functions**.

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
   https://vdghijvwhrbiorytnpof.supabase.co
   ```
4. Pegá tu **Anon Public Key** en el campo correspondiente.
5. Hacé clic en **"Probar y Guardar Conexión"**.
6. ¡Listo! El indicador cambiará a **🟢 Online** y todos los productos, ventas, clientes y configuraciones se sincronizarán en tiempo real.

---

## 📊 Tablas y Funciones RPC

| Objeto | Tipo | Descripción | Tiempo Real / Seguridad |
|---|---|---|:---:|
| `products` | Tabla | Catálogo de productos, stock, precios, imágenes y activos | ✅ Activo |
| `categories` | Tabla | Categorías nutricionales del e-commerce | ✅ Activo |
| `clients` | Tabla | Padrón de clientes y datos fiscales (CUIT) | ✅ Activo |
| `sales` | Tabla | Historial de transacciones y tickets POS | ✅ Activo |
| `collaborators` | Tabla | Usuarios del sistema y control de roles | 🔒 Hasheado con bcrypt |
| `offers` | Tabla | Descuentos y promociones destacadas | ✅ Activo |
| `expenses` | Tabla | Registro de gastos y movimientos de caja | ✅ Activo |
| `store_config` | Tabla | Datos comerciales de la tienda y cuentas bancarias | ✅ Activo |
| `login_collaborator` | RPC Function | Autenticación criptográfica segura | 🔒 Server-Side Only |
| `admin_upsert_collaborator` | RPC Function | Creación/edición segura de colaboradores | 🔒 Server-Side Only |

