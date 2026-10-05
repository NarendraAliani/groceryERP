<?php

declare(strict_types=1);

namespace GroceryERP\\Controllers;

use GroceryERP\\Config\\Database;
use GroceryERP\\Core\\Controller;
use Throwable;

final class CustomerController extends Controller
{
    public function profile(): never
    {
        $this->requireStoreContext();
        $phone=$this->cleanString($_GET['phone']??'',20);
        if($phone==='') $this->json([],false,422);
        try{
            $db=Database::connection();
            $stmt=$db->prepare('SELECT customer_id,phone,name,loyalty_points,tier FROM customers WHERE phone=? LIMIT 1');
            $stmt->execute([$phone]);
            $this->json(['customer'=>$stmt->fetch() ?: null]);
        }catch(Throwable $e){$this->error($e);}
    }

    public function digitalBill(): never
    {
        [, $storeId]=$this->requireStoreContext();
        $invoiceId=(int)($_GET['invoice_id']??0);
        if($invoiceId<=0) $this->json([],false,422);
        try{
            $db=Database::connection();
            $s=$db->prepare('SELECT i.*,c.name customer_name,c.phone FROM invoices i LEFT JOIN customers c ON c.customer_id=i.customer_id WHERE i.store_id=? AND i.invoice_id=?');
            $s->execute([$storeId,$invoiceId]); $invoice=$s->fetch();
            if(!$invoice) $this->json([],false,404);
            $s=$db->prepare('SELECT ii.*,p.name,p.barcode,u.unit_code FROM invoice_items ii JOIN inventory_batches b ON b.batch_id=ii.batch_id JOIN products p ON p.product_id=b.product_id JOIN units_of_measure u ON u.uom_id=p.uom_id WHERE ii.invoice_id=? ORDER BY ii.item_id');
            $s->execute([$invoiceId]);
            $this->json(['invoice'=>$invoice,'items'=>$s->fetchAll()]);
        }catch(Throwable $e){$this->error($e);}
    }
}
