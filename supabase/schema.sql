-- ==============================================================================
-- GOMEX NUTRITION - ESQUEMA DE BASE DE DATOS SUPABASE (POSTGRESQL)
-- Proyecto: https://jdhscjhashyqmnmuksuk.supabase.co
-- Región: sa-east-1 (São Paulo)
-- Descripción: Tablas, restricciones, políticas de seguridad (RLS),
--              autenticación segura con pgcrypto / bcrypt, publicación
--              en tiempo real y datos semilla iniciales.
-- ==============================================================================

-- 0. EXTENSIONES REQUERIDAS
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. TABLA: categories (Categorías de productos)
CREATE TABLE IF NOT EXISTS public.categories (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 2. TABLA: products (Catálogo e inventario de productos)
CREATE TABLE IF NOT EXISTS public.products (
    id BIGINT PRIMARY KEY,
    code TEXT,
    internal_code TEXT,
    name TEXT NOT NULL,
    category TEXT,
    cost NUMERIC DEFAULT 0,
    tax_rate NUMERIC DEFAULT 21,
    margin NUMERIC DEFAULT 0,
    price NUMERIC NOT NULL DEFAULT 0,
    stock INTEGER DEFAULT 0,
    unit TEXT,
    flavor TEXT,
    portion TEXT,
    description TEXT,
    activos JSONB DEFAULT '[]'::jsonb,
    image TEXT,
    featured BOOLEAN DEFAULT false,
    badge TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 3. TABLA: clients (Padrón de clientes)
CREATE TABLE IF NOT EXISTS public.clients (
    id SERIAL PRIMARY KEY,
    cuit TEXT UNIQUE,
    name TEXT NOT NULL,
    gym TEXT,
    location TEXT,
    province TEXT,
    phone TEXT,
    email TEXT,
    address TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 4. TABLA: sales (Historial de ventas y tickets)
CREATE TABLE IF NOT EXISTS public.sales (
    id TEXT PRIMARY KEY,
    ticket_no TEXT,
    date TEXT,
    seller TEXT,
    seller_name TEXT,
    client TEXT,
    payment_method TEXT,
    lines JSONB DEFAULT '[]'::jsonb,
    items JSONB DEFAULT '[]'::jsonb,
    total NUMERIC DEFAULT 0,
    subtotal NUMERIC DEFAULT 0,
    tax NUMERIC DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 5. TABLA: collaborators (Colaboradores y usuarios del sistema POS)
CREATE TABLE IF NOT EXISTS public.collaborators (
    id BIGINT PRIMARY KEY,
    name TEXT NOT NULL,
    username TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    role TEXT DEFAULT 'Vendedor',
    permissions JSONB DEFAULT '{"pos": true, "notas": true, "stock": true, "config": true, "ventas": true, "catalogo": true, "clientes": true, "presupuesto": true, "colaboradores": true, "importaciones": true}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 6. TABLA: offers (Ofertas y promociones especiales)
CREATE TABLE IF NOT EXISTS public.offers (
    id SERIAL PRIMARY KEY,
    product_id BIGINT UNIQUE,
    offer_price NUMERIC,
    discount NUMERIC,
    badge TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 7. TABLA: expenses (Gastos y egresos de caja)
CREATE TABLE IF NOT EXISTS public.expenses (
    id BIGINT PRIMARY KEY,
    date TEXT,
    category TEXT,
    concept TEXT,
    entity TEXT,
    voucher TEXT,
    method TEXT,
    amount NUMERIC DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 8. TABLA: store_config (Configuración institucional y de cuentas bancarias)
CREATE TABLE IF NOT EXISTS public.store_config (
    id TEXT PRIMARY KEY DEFAULT 'main',
    data JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- ==============================================================================
-- SEGURIDAD CRIPTOGRÁFICA Y TRIGGERS DE HASHEO AUTOMÁTICO (BCRYPT)
-- ==============================================================================

-- Función trigger para asegurar que las contraseñas siempre se almacenen con hash bcrypt
CREATE OR REPLACE FUNCTION public.hash_collaborator_password_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND (NEW.password IS NULL OR length(trim(NEW.password)) = 0) THEN
        NEW.password := OLD.password;
    ELSIF NEW.password IS NOT NULL AND NEW.password NOT LIKE '$2%' THEN
        NEW.password := extensions.crypt(NEW.password, extensions.gen_salt('bf', 10));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

DROP TRIGGER IF EXISTS trg_hash_collaborator_password ON public.collaborators;
CREATE TRIGGER trg_hash_collaborator_password
BEFORE INSERT OR UPDATE ON public.collaborators
FOR EACH ROW
EXECUTE FUNCTION public.hash_collaborator_password_trigger();

-- ==============================================================================
-- FUNCIONES RPC DE SERVIDOR PARA AUTENTICACIÓN Y GESTIÓN SEGURA
-- ==============================================================================

-- 1. Inicio de Sesión Seguro (no expone contraseñas ni hashes al cliente)
CREATE OR REPLACE FUNCTION public.login_collaborator(
    p_username TEXT,
    p_password TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_colab RECORD;
BEGIN
    SELECT * INTO v_colab
    FROM public.collaborators
    WHERE LOWER(username) = LOWER(TRIM(p_username))
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Usuario o contraseña incorrectos'
        );
    END IF;

    IF v_colab.password = extensions.crypt(p_password, v_colab.password) THEN
        RETURN jsonb_build_object(
            'success', true,
            'user', jsonb_build_object(
                'id', v_colab.id,
                'name', v_colab.name,
                'username', v_colab.username,
                'role', v_colab.role,
                'permissions', v_colab.permissions
            )
        );
    ELSE
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Usuario o contraseña incorrectos'
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

-- 2. Creación / Actualización Segura de Colaboradores
CREATE OR REPLACE FUNCTION public.admin_upsert_collaborator(
    p_id BIGINT,
    p_name TEXT,
    p_username TEXT,
    p_password TEXT,
    p_role TEXT,
    p_permissions JSONB
)
RETURNS JSONB AS $$
DECLARE
    v_existing RECORD;
    v_result RECORD;
    v_final_id BIGINT;
BEGIN
    IF p_id IS NOT NULL AND p_id > 0 THEN
        SELECT * INTO v_existing FROM public.collaborators WHERE id = p_id;
    END IF;

    IF v_existing.id IS NOT NULL THEN
        -- Actualización
        UPDATE public.collaborators
        SET
            name = COALESCE(NULLIF(TRIM(p_name), ''), name),
            username = COALESCE(NULLIF(TRIM(p_username), ''), username),
            password = CASE
                WHEN p_password IS NOT NULL AND length(trim(p_password)) > 0
                THEN extensions.crypt(p_password, extensions.gen_salt('bf', 10))
                ELSE password
            END,
            role = COALESCE(p_role, role),
            permissions = COALESCE(p_permissions, permissions)
        WHERE id = p_id
        RETURNING id, name, username, role, permissions, created_at INTO v_result;
    ELSE
        -- Inserción
        IF p_password IS NULL OR length(trim(p_password)) = 0 THEN
            RETURN jsonb_build_object(
                'success', false,
                'message', 'La contraseña es obligatoria para nuevos colaboradores.'
            );
        END IF;

        v_final_id := COALESCE(p_id, (EXTRACT(EPOCH FROM now()) * 1000)::BIGINT);

        INSERT INTO public.collaborators (id, name, username, password, role, permissions)
        VALUES (
            v_final_id,
            TRIM(p_name),
            TRIM(p_username),
            extensions.crypt(p_password, extensions.gen_salt('bf', 10)),
            COALESCE(p_role, 'Vendedor'),
            COALESCE(p_permissions, '{"pos": true, "notas": true, "stock": true, "config": false, "ventas": true, "catalogo": true, "clientes": true, "presupuesto": true, "colaboradores": false, "importaciones": false}'::jsonb)
        )
        RETURNING id, name, username, role, permissions, created_at INTO v_result;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'collaborator', jsonb_build_object(
            'id', v_result.id,
            'name', v_result.name,
            'username', v_result.username,
            'role', v_result.role,
            'permissions', v_result.permissions,
            'created_at', v_result.created_at
        )
    );
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', false,
        'message', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

-- Permisos de ejecución de RPCs
GRANT ALL ON SCHEMA public TO anon, authenticated, postgres, service_role;
GRANT EXECUTE ON FUNCTION public.login_collaborator(TEXT, TEXT) TO anon, authenticated, postgres, service_role;
GRANT EXECUTE ON FUNCTION public.admin_upsert_collaborator(BIGINT, TEXT, TEXT, TEXT, TEXT, JSONB) TO anon, authenticated, postgres, service_role;

-- ==============================================================================
-- SEGURIDAD ROW LEVEL SECURITY (RLS) Y POLÍTICAS DE ACCESO
-- ==============================================================================

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collaborators ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_config ENABLE ROW LEVEL SECURITY;

-- Limpieza de políticas previas si existieran para evitar colisiones
DROP POLICY IF EXISTS "Allow public all on categories" ON public.categories;
DROP POLICY IF EXISTS "Allow public all on products" ON public.products;
DROP POLICY IF EXISTS "Allow public all on clients" ON public.clients;
DROP POLICY IF EXISTS "Allow public all on sales" ON public.sales;
DROP POLICY IF EXISTS "Allow public all on collaborators" ON public.collaborators;
DROP POLICY IF EXISTS "Allow public all on offers" ON public.offers;
DROP POLICY IF EXISTS "Allow public all on expenses" ON public.expenses;
DROP POLICY IF EXISTS "Allow public all on store_config" ON public.store_config;

DROP POLICY IF EXISTS "Public read categories" ON public.categories;
DROP POLICY IF EXISTS "Public insert categories" ON public.categories;
DROP POLICY IF EXISTS "Public modify categories" ON public.categories;
DROP POLICY IF EXISTS "Public delete categories" ON public.categories;

DROP POLICY IF EXISTS "Public read products" ON public.products;
DROP POLICY IF EXISTS "Public insert products" ON public.products;
DROP POLICY IF EXISTS "Public update products" ON public.products;
DROP POLICY IF EXISTS "Public delete products" ON public.products;

DROP POLICY IF EXISTS "Public read offers" ON public.offers;
DROP POLICY IF EXISTS "Public insert offers" ON public.offers;
DROP POLICY IF EXISTS "Public update offers" ON public.offers;
DROP POLICY IF EXISTS "Public delete offers" ON public.offers;

DROP POLICY IF EXISTS "Public read store_config" ON public.store_config;
DROP POLICY IF EXISTS "Public update store_config" ON public.store_config;
DROP POLICY IF EXISTS "Public modify store_config" ON public.store_config;

DROP POLICY IF EXISTS "Public read clients" ON public.clients;
DROP POLICY IF EXISTS "Public insert clients" ON public.clients;
DROP POLICY IF EXISTS "Public update clients" ON public.clients;
DROP POLICY IF EXISTS "Public delete clients" ON public.clients;

DROP POLICY IF EXISTS "Public read sales" ON public.sales;
DROP POLICY IF EXISTS "Public insert sales" ON public.sales;
DROP POLICY IF EXISTS "Public delete sales" ON public.sales;

DROP POLICY IF EXISTS "Public read collaborators" ON public.collaborators;
DROP POLICY IF EXISTS "Public insert collaborators" ON public.collaborators;
DROP POLICY IF EXISTS "Public update collaborators" ON public.collaborators;
DROP POLICY IF EXISTS "Public delete collaborators" ON public.collaborators;

DROP POLICY IF EXISTS "Public read expenses" ON public.expenses;
DROP POLICY IF EXISTS "Public insert expenses" ON public.expenses;
DROP POLICY IF EXISTS "Public delete expenses" ON public.expenses;

-- Creación de políticas de acceso
-- 1. Categorías
CREATE POLICY "Public read categories" ON public.categories FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Public insert categories" ON public.categories FOR INSERT TO anon, authenticated WITH CHECK (name IS NOT NULL AND length(name) > 0);
CREATE POLICY "Public modify categories" ON public.categories FOR UPDATE TO anon, authenticated USING (id IS NOT NULL) WITH CHECK (name IS NOT NULL AND length(name) > 0);
CREATE POLICY "Public delete categories" ON public.categories FOR DELETE TO anon, authenticated USING (id IS NOT NULL);

-- 2. Productos
CREATE POLICY "Public read products" ON public.products FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Public insert products" ON public.products FOR INSERT TO anon, authenticated WITH CHECK (name IS NOT NULL AND price >= 0);
CREATE POLICY "Public update products" ON public.products FOR UPDATE TO anon, authenticated USING (id IS NOT NULL) WITH CHECK (price >= 0);
CREATE POLICY "Public delete products" ON public.products FOR DELETE TO anon, authenticated USING (id IS NOT NULL);

-- 3. Ofertas
CREATE POLICY "Public read offers" ON public.offers FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Public insert offers" ON public.offers FOR INSERT TO anon, authenticated WITH CHECK (product_id IS NOT NULL);
CREATE POLICY "Public update offers" ON public.offers FOR UPDATE TO anon, authenticated USING (product_id IS NOT NULL) WITH CHECK (product_id IS NOT NULL);
CREATE POLICY "Public delete offers" ON public.offers FOR DELETE TO anon, authenticated USING (product_id IS NOT NULL);

-- 4. Configuración de Tienda
CREATE POLICY "Public read store_config" ON public.store_config FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Public update store_config" ON public.store_config FOR INSERT TO anon, authenticated WITH CHECK (id = 'main');
CREATE POLICY "Public modify store_config" ON public.store_config FOR UPDATE TO anon, authenticated USING (id = 'main');

-- 5. Clientes
CREATE POLICY "Public read clients" ON public.clients FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Public insert clients" ON public.clients FOR INSERT TO anon, authenticated WITH CHECK (name IS NOT NULL);
CREATE POLICY "Public update clients" ON public.clients FOR UPDATE TO anon, authenticated USING (cuit IS NOT NULL) WITH CHECK (name IS NOT NULL);
CREATE POLICY "Public delete clients" ON public.clients FOR DELETE TO anon, authenticated USING (cuit IS NOT NULL);

-- 6. Ventas
CREATE POLICY "Public read sales" ON public.sales FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Public insert sales" ON public.sales FOR INSERT TO anon, authenticated WITH CHECK (id IS NOT NULL);
CREATE POLICY "Public delete sales" ON public.sales FOR DELETE TO anon, authenticated USING (id IS NOT NULL);

-- 7. Colaboradores y Gastos
CREATE POLICY "Public read collaborators" ON public.collaborators FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Public delete collaborators" ON public.collaborators FOR DELETE TO anon, authenticated USING (id IS NOT NULL);

CREATE POLICY "Public read expenses" ON public.expenses FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Public insert expenses" ON public.expenses FOR INSERT TO anon, authenticated WITH CHECK (id IS NOT NULL);
CREATE POLICY "Public delete expenses" ON public.expenses FOR DELETE TO anon, authenticated USING (id IS NOT NULL);

-- ==============================================================================
-- HABILITACIÓN DE TIEMPO REAL (SUPABASE REALTIME)
-- ==============================================================================

DO $$
DECLARE
    t text;
    tables text[] := ARRAY['categories', 'products', 'clients', 'sales', 'collaborators', 'offers', 'expenses', 'store_config'];
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
        CREATE PUBLICATION supabase_realtime;
    END IF;

    FOREACH t IN ARRAY tables LOOP
        IF NOT EXISTS (
            SELECT 1 FROM pg_publication_tables 
            WHERE pubname = 'supabase_realtime' AND tablename = t
        ) THEN
            EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', t);
        END IF;
    END LOOP;
END $$;

-- ==============================================================================
-- DATOS SEMILLA INICIALES (SEED DATA)
-- ==============================================================================

-- 1. Categorías oficiales
INSERT INTO public.categories (name) VALUES
('Rendimiento & Fuerza'),
('Salud & Inmunidad'),
('Descanso & Bienestar'),
('Combos & Packs')
ON CONFLICT (name) DO NOTHING;

-- 2. Producto oficial inicial GOMEX (1 solo producto base de contingencia)
INSERT INTO public.products (id, code, internal_code, name, category, cost, tax_rate, margin, price, stock, unit, flavor, portion, description, activos, image, featured, badge) VALUES
(1, '779812345601', 'GMX-CRE-01', 'GOMEX Creatina Monohidratada en Gomitas', 'Rendimiento & Fuerza', 14000, 21, 103.57, 45000, 45, 'Doypack 60 Gomitas', 'Frutos Rojos', '2 gomitas diarias (3g Creatina)', 'Creatina monohidratada en gomitas masticables. Fuerza y recuperación sin shakers ni textura arenosa.', '["Creatina Monohidratada 100% Pura", "Electrolitos"]'::jsonb, 'public/bolsaGomitas.jpg', true, 'MÁS VENDIDO ⭐')
ON CONFLICT (id) DO NOTHING;

-- 3. Cliente inicial por defecto
INSERT INTO public.clients (cuit, name, gym, location, province, phone, email) VALUES
('00-00000000-0', 'Consumidor Final', 'GOMEX Headquarter', 'Venta Mostrador', 'Buenos Aires', '-', '-')
ON CONFLICT (cuit) DO NOTHING;

-- 4. Colaboradores iniciales (las contraseñas '123' son convertidas automáticamente a bcrypt por el trigger)
INSERT INTO public.collaborators (id, name, username, password, role, permissions) VALUES
(1, 'David Ramírez (SuperAdmin)', 'superadmin', '123', 'Super Administrador', '{"pos": true, "notas": true, "stock": true, "config": true, "ventas": true, "catalogo": true, "clientes": true, "presupuesto": true, "colaboradores": true, "importaciones": true}'::jsonb),
(2, 'Administrador GOMEX', 'admin', '123', 'Administrador', '{"pos": true, "notas": true, "stock": true, "config": true, "ventas": true, "catalogo": true, "clientes": true, "presupuesto": true, "colaboradores": true, "importaciones": true}'::jsonb)
ON CONFLICT (id) DO NOTHING;

-- 5. Configuración inicial de Tienda y Cuentas Bancarias
INSERT INTO public.store_config (id, data) VALUES
('main', '{
  "storeConfig": {
    "tradeName": "GOMEX Nutrition",
    "businessName": "GOMEX Nutrition Argentina S.R.L.",
    "cuit": "30-71829340-9",
    "iibb": "901-283910-2",
    "address": "Av. Libertador 4500, CABA",
    "phone": "+54 9 11 1234-5678",
    "email": "contacto@gomexnutrition.com.ar",
    "taxCondition": "Responsable Inscripto",
    "ivaCondition": "Responsable Inscripto",
    "ticketMsg": "¡Gracias por elegir GOMEX Nutrition! Suplementación sin fricción.",
    "receiptFooter": "¡Gracias por elegir GOMEX Nutrition! Suplementación sin fricción.",
    "logo": "public/logo.jpg",
    "logoUrl": "public/logo.jpg"
  },
  "bankConfig": {
    "aliasMp": "gomex.nutricion.mp",
    "cvuMp": "0000003100084920194820",
    "aliasCbu": "GOMEX.NACION",
    "cbu": "0110599520000012345678",
    "bankName": "Banco de la Nación Argentina",
    "holder": "GOMEX Nutrition Argentina S.R.L.",
    "cuit": "30-71829340-9"
  }
}'::jsonb)
ON CONFLICT (id) DO NOTHING;

