-- ==============================================================================
-- GOMEX NUTRITION - ESQUEMA DE BASE DE DATOS SUPABASE (POSTGRESQL)
-- Proyecto: https://jdhscjhashyqmnmuksuk.supabase.co
-- Región: sa-east-1 (São Paulo)
-- Descripción: Tablas, restricciones, políticas de seguridad (RLS),
--              publicación en tiempo real y datos semilla iniciales.
-- ==============================================================================

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
    id SERIAL PRIMARY KEY,
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
DROP POLICY IF EXISTS "Public insert/update categories" ON public.categories;
DROP POLICY IF EXISTS "Public modify categories" ON public.categories;
DROP POLICY IF EXISTS "Public delete categories" ON public.categories;

DROP POLICY IF EXISTS "Public read products" ON public.products;
DROP POLICY IF EXISTS "Public insert/update products" ON public.products;
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
DROP POLICY IF EXISTS "Public manage collaborators" ON public.collaborators;
DROP POLICY IF EXISTS "Public update collaborators" ON public.collaborators;
DROP POLICY IF EXISTS "Public delete collaborators" ON public.collaborators;

DROP POLICY IF EXISTS "Public read expenses" ON public.expenses;
DROP POLICY IF EXISTS "Public insert expenses" ON public.expenses;
DROP POLICY IF EXISTS "Public delete expenses" ON public.expenses;

-- Creación de políticas de acceso granulares para cliente y operaciones del POS
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
CREATE POLICY "Public manage collaborators" ON public.collaborators FOR INSERT TO anon, authenticated WITH CHECK (username IS NOT NULL);
CREATE POLICY "Public update collaborators" ON public.collaborators FOR UPDATE TO anon, authenticated USING (id IS NOT NULL) WITH CHECK (username IS NOT NULL);
CREATE POLICY "Public delete collaborators" ON public.collaborators FOR DELETE TO anon, authenticated USING (id IS NOT NULL);

CREATE POLICY "Public read expenses" ON public.expenses FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Public insert expenses" ON public.expenses FOR INSERT TO anon, authenticated WITH CHECK (id IS NOT NULL);
CREATE POLICY "Public delete expenses" ON public.expenses FOR DELETE TO anon, authenticated USING (id IS NOT NULL);

-- ==============================================================================
-- HABILITACIÓN DE TIEMPO REAL (SUPABASE REALTIME)
-- ==============================================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
        CREATE PUBLICATION supabase_realtime;
    END IF;
END $$;

ALTER PUBLICATION supabase_realtime ADD TABLE public.categories;
ALTER PUBLICATION supabase_realtime ADD TABLE public.products;
ALTER PUBLICATION supabase_realtime ADD TABLE public.clients;
ALTER PUBLICATION supabase_realtime ADD TABLE public.sales;
ALTER PUBLICATION supabase_realtime ADD TABLE public.collaborators;
ALTER PUBLICATION supabase_realtime ADD TABLE public.offers;
ALTER PUBLICATION supabase_realtime ADD TABLE public.expenses;
ALTER PUBLICATION supabase_realtime ADD TABLE public.store_config;

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

-- 2. Productos oficiales GOMEX
INSERT INTO public.products (id, code, internal_code, name, category, cost, tax_rate, margin, price, stock, unit, flavor, portion, description, activos, image, featured, badge) VALUES
(1, '779812345601', 'GMX-CRE-01', 'GOMEX Creatina Monohidratada en Gomitas', 'Rendimiento & Fuerza', 14000, 21, 103.57, 28500, 45, 'Doypack 60 Gomitas', 'Frutos Rojos', '2 gomitas diarias (3g Creatina)', 'Creatina monohidratada en gomitas masticables. Fuerza y recuperación sin shakers ni textura arenosa.', '["Creatina Monohidratada 100% Pura", "Electrolitos"]'::jsonb, 'public/bolsaGomitas.jpg', true, 'MÁS VENDIDO ⭐'),
(2, '779812345602', 'GMX-VIT-02', 'GOMEX Multivitamínico + Inmuno Defense', 'Salud & Inmunidad', 11000, 21, 108.18, 22900, 60, 'Caja 60 Gomitas', 'Cítricos Naranja & Limón', '2 gomitas por la mañana', '12 vitaminas y minerales clave para reforzar defensas y energía diaria.', '["Vitamina C (500mg)", "Vitamina D3", "Zinc Quelado", "Complejo B"]'::jsonb, 'public/cajaGomitas.jpg', true, 'DEFENSAS 🛡️'),
(3, '779812345603', 'GMX-SLP-03', 'GOMEX Sleep & Recovery (Melatonina + Magnesio)', 'Descanso & Bienestar', 12000, 21, 107.50, 24900, 38, 'Doypack 60 Gomitas', 'Mora & Lavanda', '2 gomitas antes de dormir', 'Conciliación rápida del sueño y descanso profundo sin somnolencia diurna.', '["Melatonina Pura (3mg)", "Citrato de Magnesio", "L-Teanina"]'::jsonb, 'public/bolsaGomita.jpg', true, 'SUEÑO PROFUNDO 🌙'),
(4, '779812345604', 'GMX-TRP-04', 'GOMEX Pack Trío Rutina 360°', 'Combos & Packs', 33000, 21, 108.79, 68900, 20, 'Combo 3 Productos (180 Gomitas)', 'Surtido Frutal', 'Rutina completa día y noche', 'Creatina + Multivitamínico + Sleep con 20% de ahorro.', '["1x Creatina GOMEX", "1x Multivitamínico GOMEX", "1x Sleep GOMEX"]'::jsonb, 'public/gomitas.jpg', true, 'OFERTA PACK -20% 🔥')
ON CONFLICT (id) DO NOTHING;

-- 3. Cliente inicial por defecto
INSERT INTO public.clients (cuit, name, gym, location, province, phone, email) VALUES
('00-00000000-0', 'Consumidor Final', 'GOMEX Headquarter', 'Venta Mostrador', 'Buenos Aires', '-', '-')
ON CONFLICT (cuit) DO NOTHING;

-- 4. Colaboradores iniciales
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
