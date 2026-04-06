-- Agregar campo umbral_alerta a la tabla productos
ALTER TABLE productos ADD COLUMN IF NOT EXISTS umbral_alerta INTEGER DEFAULT 5;

-- Comentario para documentar el campo
COMMENT ON COLUMN productos.umbral_alerta IS 'Umbral mínimo de stock para mostrar alerta. Si cantidad <= umbral_alerta, se muestra alerta de stock bajo.';
