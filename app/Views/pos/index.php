<?php
declare(strict_types=1);
if (empty($_SESSION['_csrf'])) $_SESSION['_csrf'] = bin2hex(random_bytes(32));
$title='groceryERP POS';
require dirname(__DIR__).'/layouts/header.php';
?>
<main class="pos-grid">
<section class="terminal-card">
<header class="terminal-header"><div><span class="eyebrow">GROCERY ERP</span><h1>Fast Billing</h1></div><div id="connectionBadge" class="status-pill online">Online</div></header>
<div class="scan-row">
<label class="sr-only" for="barcodeInput">Barcode</label>
<input id="barcodeInput" autocomplete="off" inputmode="numeric" placeholder="Scan barcode or type…" autofocus>
<button id="cameraToggle" type="button">Camera</button>
</div>
<div id="scannerStatus" class="scanner-status">Ready for scanner input</div>
<div id="reader" class="camera-panel" hidden></div>
<div class="weight-row"><label for="quantityInput">Quantity</label><input id="quantityInput" type="number" min="0.001" step="0.001" value="1.000"><span id="uomLabel">pcs</span><button id="addLoose" type="button">Add</button></div>
<div class="cart-wrap"><table id="cartTable"><thead><tr><th>Item</th><th>Qty</th><th>Rate</th><th>GST</th><th>Total</th><th></th></tr></thead><tbody></tbody></table></div>
</section>
<aside class="checkout-card">
<div class="customer-box"><label>Customer phone</label><input id="customerPhone" inputmode="tel" maxlength="20" placeholder="Optional"><div id="customerInfo"></div></div>
<div class="summary"><div><span>Subtotal</span><strong id="subtotal">₹0.00</strong></div><div><span>CGST</span><strong id="cgst">₹0.00</strong></div><div><span>SGST</span><strong id="sgst">₹0.00</strong></div><div><span>IGST</span><strong id="igst">₹0.00</strong></div><div class="grand"><span>Total</span><strong id="grandTotal">₹0.00</strong></div></div>
<button id="checkoutButton" class="primary" type="button">Checkout</button>
<div id="paymentPanel" class="payment-panel" hidden>
<h2>Split payment</h2>
<label>Cash <input data-payment="Cash" type="number" min="0" step="0.01" value="0.00"></label>
<label>Card <input data-payment="Card" type="number" min="0" step="0.01" value="0.00"></label>
<label>UPI <input data-payment="UPI" type="number" min="0" step="0.01" value="0.00"></label>
<button id="confirmPayment" class="primary" type="button">Confirm payment</button>
</div>
<div id="receipt" class="receipt" hidden></div>
</aside>
</main>
<?php require dirname(__DIR__).'/layouts/footer.php'; ?>
