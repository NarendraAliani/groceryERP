<?php

declare(strict_types=1);

namespace GroceryERP\\Controllers;

use GroceryERP\\Core\\Controller;
use GroceryERP\\Models\\Batch;
use Throwable;

final class InventoryController extends Controller
{
    public function createBatch(): never
    {
        [$companyId,$storeId] = $this->requireStoreContext();
        $input=$this->input(); $this->verifyCsrf($input);
        $productId=(int)($input['product_id']??0);
        $stock=round((float)($input['current_stock']??0),3);
        if($productId<=0 || $stock<0) $this->json([],false,422);
        try {
            (new Batch())->create($storeId,$productId,(int)($input['supplier_id']??0),$this->cleanString($input['lot_number']??'',80),round((float)($input['cost_price']??0),2),round((float)($input['selling_price']??0),2),$stock,$this->cleanString($input['mfg_date']??'',10),$this->cleanString($input['expiry_date']??'',10));
            $this->json(['message'=>'Batch created']);
        } catch(Throwable $e){$this->error($e);}
    }

    public function lowStock(): never
    {
        [, $storeId]=$this->requireStoreContext();
        try{$this->json(['items'=>(new Batch())->lowStock($storeId)]);}catch(Throwable $e){$this->error($e);}
    }
}
