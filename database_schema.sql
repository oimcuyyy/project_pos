-- 1. Table Users (Pegawai & Pelanggan)
CREATE TABLE public.users (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('admin', 'cashier', 'user')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Table Products (Produk & Menu)
CREATE TABLE public.products (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    price NUMERIC NOT NULL DEFAULT 0,
    sku TEXT UNIQUE,
    image_url TEXT,
    stock INTEGER DEFAULT 0,
    is_available BOOLEAN DEFAULT TRUE,
    options JSONB DEFAULT '[]'::JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Table Transactions (Riwayat Transaksi)
CREATE TABLE public.transactions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    cashier_name TEXT NOT NULL,
    customer_name TEXT,
    payment_method TEXT NOT NULL,
    subtotal NUMERIC NOT NULL,
    tax NUMERIC NOT NULL DEFAULT 0,
    discount NUMERIC NOT NULL DEFAULT 0,
    grand_total NUMERIC NOT NULL,
    amount_paid NUMERIC NOT NULL,
    change_amount NUMERIC NOT NULL DEFAULT 0,
    items JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Table Shifts (Shift Kasir)
CREATE TABLE public.shifts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    cashier_name TEXT NOT NULL,
    starting_cash NUMERIC NOT NULL DEFAULT 0,
    cash_sales NUMERIC NOT NULL DEFAULT 0,
    non_cash_sales NUMERIC NOT NULL DEFAULT 0,
    petty_cash_out NUMERIC NOT NULL DEFAULT 0,
    expected_cash_end NUMERIC NOT NULL DEFAULT 0,
    actual_cash_end NUMERIC,
    status TEXT NOT NULL DEFAULT 'open',
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ended_at TIMESTAMP WITH TIME ZONE
);

-- 5. Table Customers (Data Pelanggan - Opsional)
CREATE TABLE public.customers (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    points INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Table Store Settings (Pengaturan Toko)
CREATE TABLE public.store_settings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    store_name TEXT NOT NULL DEFAULT 'Toko Saya',
    store_address TEXT,
    store_phone TEXT,
    tax_percentage NUMERIC DEFAULT 0,
    is_maintenance BOOLEAN DEFAULT FALSE,
    maintenance_started_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert Default Admin & Settings
INSERT INTO public.users (name, username, password, role) 
VALUES ('Super Admin', 'admin', 'admin123', 'admin');

INSERT INTO public.store_settings (store_name) 
VALUES ('Toko POS Default');
