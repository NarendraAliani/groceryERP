<?php

declare(strict_types=1);

namespace GroceryERP\\Models;

use GroceryERP\\Core\\Model;

final class Batch extends Model
{
    public function create(int $storeId, int $productId, ?int $supplierId, string $lot, float $cost, float $selling, float $stock, ?string $mfg, ?string $expiry): int
    {
        return $this->execute('INSERT INTO inventory_batches (store_id,product_id,supplier_id,lot_number,cost_price,selling_price,current_stock,mfg_date,expiry_date) VALUES (?,?,?,?,?,?,?,?,?)', [$storeId,$productId,$supplierId ?: null,$lot,$cost,$selling,$stock,$mfg ?: null,$expiry ?: null]);
    }

    public function lowStock(int $storeId): array
    {
        return $this->query('SELECT p.product_id,p.barcode,p.name,SUM(b.current_stock) current_stock,s.minimum_stock,s.reorder_qty FROM products p JOIN inventory_batches b ON b.product_id=p.product_id JOIN store_product_settings s ON s.product_id=p.product_id AND s.store_id=b.store_id WHERE b.store_id=? GROUP BY p.product_id,p.barcode,p.name,s.minimum_stock,s.reorder_qty HAVING current_stock <= minimum_stock ORDER BY current_stock ASC', [$storeId]);
    }
}
