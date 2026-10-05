<?php

declare(strict_types=1);

use GroceryERP\\Core\\Autoloader;
use GroceryERP\\Core\\Router;
use GroceryERP\\Controllers\\POSController;
use GroceryERP\\Controllers\\InventoryController;
use GroceryERP\\Controllers\\CustomerController;

require_once dirname(__DIR__) . '/app/Core/Autoloader.php';
Autoloader::register();
session_start();

$router = new Router();
$router->get('#^/$#', static function (): void { require dirname(__DIR__) . '/app/Views/pos/index.php'; });
$router->get('#^/api/pos/lookup$#', [new POSController(), 'lookupBarcode']);
$router->post('#^/api/pos/checkout$#', [new POSController(), 'processCheckout']);
$router->get('#^/api/pos/upi$#', [new POSController(), 'generateUpiQr']);
$router->post('#^/api/inventory/batch$#', [new InventoryController(), 'createBatch']);
$router->get('#^/api/inventory/low-stock$#', [new InventoryController(), 'lowStock']);
$router->get('#^/api/customer/profile$#', [new CustomerController(), 'profile']);
$router->get('#^/api/customer/bill$#', [new CustomerController(), 'digitalBill']);

$path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
$router->dispatch($_SERVER['REQUEST_METHOD'] ?? 'GET', $path);
