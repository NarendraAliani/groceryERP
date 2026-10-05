<?php

declare(strict_types=1);

namespace GroceryERP\\Models;

use GroceryERP\\Core\\Model;

final class Invoice extends Model
{
    public function complete(int $companyId, int $storeId, int $customerId, string $invoiceNumber, array $items, array $payments): array
    {
        return $this->procedure('Sp_CompleteCheckoutTransaction', [$companyId,$storeId,$customerId,$invoiceNumber,json_encode($items, JSON_THROW_ON_ERROR),json_encode($payments, JSON_THROW_ON_ERROR)]);
    }

    public function find(int $storeId, int $invoiceId): ?array
    {
        $rows = $this->query('SELECT i.*,c.name customer_name,c.phone FROM invoices i LEFT JOIN customers c ON c.customer_id=i.customer_id WHERE i.store_id=? AND i.invoice_id=?', [$storeId,$invoiceId]);
        return $rows[0] ?? null;
    }
}
