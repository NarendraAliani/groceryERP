<?php

declare(strict_types=1);

namespace GroceryERP\\Models;

use GroceryERP\\Core\\Model;

final class Product extends Model
{
    public function findForTerminal(string $barcode, int $storeId): ?array
    {
        $rows = $this->procedure('Sp_GetProductForPOS', [$barcode, $storeId]);
        return $rows[0] ?? null;
    }
}
