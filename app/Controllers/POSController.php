<?php

declare(strict_types=1);

namespace GroceryERP\\Controllers;

use GroceryERP\\Core\\Controller;
use GroceryERP\\Models\\Invoice;
use GroceryERP\\Models\\Product;
use Throwable;

final class POSController extends Controller
{
    public function lookupBarcode(): never
    {
        [$companyId,$storeId] = $this->requireStoreContext();
        $barcode = $this->cleanString($_GET['barcode'] ?? '', 50);
        if ($barcode === '') $this->json([], false, 422);
        try {
            $product = (new Product())->findForTerminal($barcode, $storeId);
            $this->json(['product'=>$product]);
        } catch (Throwable $e) { $this->error($e); }
    }

    public function processCheckout(): never
    {
        [$companyId,$storeId] = $this->requireStoreContext();
        $input = $this->input();
        $this->verifyCsrf($input);
        $items = is_array($input['items'] ?? null) ? $input['items'] : [];
        $payments = is_array($input['payments'] ?? null) ? $input['payments'] : [];
        if (!$items || !$payments) $this->json([], false, 422);

        foreach ($items as &$item) {
            $item = [
                'batch_id'=>(int)($item['batch_id'] ?? 0),
                'quantity'=>round((float)($item['quantity'] ?? 0),3),
                'unit_price'=>round((float)($item['unit_price'] ?? 0),2),
                'discount_amount'=>round((float)($item['discount_amount'] ?? 0),2),
            ];
        }
        unset($item);
        foreach ($payments as &$payment) {
            $payment = [
                'mode'=>$this->cleanString($payment['mode'] ?? '',10),
                'amount'=>round((float)($payment['amount'] ?? 0),2),
                'reference_no'=>$this->cleanString($payment['reference_no'] ?? '',120),
            ];
        }
        unset($payment);

        $invoiceNumber = $this->cleanString($input['invoice_number'] ?? ('POS-' . gmdate('YmdHis') . '-' . random_int(100,999)),40);
        $customerId = (int)($input['customer_id'] ?? 0);
        try {
            $result = (new Invoice())->complete($companyId,$storeId,$customerId,$invoiceNumber,$items,$payments);
            $this->json($result[0] ?? []);
        } catch (Throwable $e) { $this->error($e, $e->getCode() === '45000' ? $e->getMessage() : 'Checkout could not be completed.'); }
    }

    public function generateUpiQr(): never
    {
        [$companyId,$storeId] = $this->requireStoreContext();
        $amount = round((float)($_GET['amount'] ?? 0),2);
        if ($amount <= 0) $this->json([], false, 422);
        $pa = getenv('UPI_VPA') ?: '';
        $pn = getenv('UPI_PAYEE_NAME') ?: 'Grocery ERP';
        if ($pa === '') $this->json([], false, 503);
        $txn = 'ERP' . gmdate('YmdHis') . random_int(1000,9999);
        $uri = 'upi://pay?' . http_build_query(['pa'=>$pa,'pn'=>$pn,'am'=>number_format($amount,2,'.',''),'cu'=>'INR','tr'=>$txn], '', '&', PHP_QUERY_RFC3986);
        $this->json(['uri'=>$uri,'transaction_ref'=>$txn,'amount'=>number_format($amount,2,'.','')]);
    }
}
