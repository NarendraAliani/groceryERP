# groceryERP

Enterprise-grade, multi-tenant Grocery Retail, POS, Inventory and CRM platform built specifically for constrained shared-hosting environments.

**Repository:** https://github.com/NarendraAliani/groceryERP

## Project status

The repository currently contains the core production architecture and POS foundation.

| Area | Status |
|---|---|
| PHP 8.x MVC foundation | Implemented |
| MySQL/MariaDB schema | Implemented |
| Atomic checkout | Implemented |
| FEFO barcode lookup | Implemented |
| GST calculation | Implemented |
| Split Cash/Card/UPI | Implemented |
| UPI payment URI | Implemented |
| Customer/loyalty foundation | Implemented |
| Low-stock purchase drafts | Implemented |
| IndexedDB offline queue | Implemented |
| USB barcode scanner | Implemented |
| Camera barcode scanner | Implemented |
| GitHub Actions FTP deployment | Implemented |
| Authentication/authorization UI | Pending |
| Full procurement workflow | Pending |
| Full inventory administration UI | Pending |
| Comprehensive automated test suite | Pending |

## Goals

groceryERP is designed to scale from a single-counter neighborhood Kirana store to multi-terminal, multi-store supermarket operations.

The system is designed around real grocery-retail requirements:

- Loose-weight billing such as kg, g, L and ml.
- Packaged units such as pieces and packets.
- Barcode-first POS workflows.
- FEFO batch selection for expiry-sensitive products.
- Batch, lot, manufacturing and expiry tracking.
- Indian GST with CGST/SGST/IGST.
- Split-tender checkout.
- Dynamic UPI payment URI generation.
- Customer profiles and loyalty points.
- Low-stock procurement suggestions.
- Offline POS continuity during temporary connectivity loss.

## Technology constraints

The project deliberately avoids server-side build dependencies.

### Backend

- PHP 8.2+
- Object-oriented MVC architecture
- Native PSR-4-style custom autoloader
- PDO with MySQL
- No Composer runtime dependency
- No framework dependency

### Database

- MySQL 8.0+
- MariaDB 10.5+
- InnoDB
- ACID transactions
- Stored procedures
- Triggers
- JSON input for checkout operations

The checkout engine keeps business-critical calculations and stock mutations inside the database transaction.

### Frontend

- Semantic HTML5
- Vanilla ES6+ JavaScript
- CSS3 custom properties
- Responsive touch-oriented POS UI
- IndexedDB for offline transaction queuing
- html5-qrcode loaded through CDN

### Hosting/deployment

Target environment:

- BigRock shared Linux hosting
- Apache
- No SSH requirement
- No Node.js
- No Python
- No Redis
- No Docker
- No Composer installation on the server

Deployment is performed through GitHub Actions using FTP.

## Architecture

```text
Browser / POS Terminal
        |
        v
/public/index.php
        |
        v
     Router
        |
        +--------------------+
        |                    |
        v                    v
 Controllers             Views / JS / CSS
        |
        v
     Models
        |
        v
      PDO
        |
        v
 MySQL / MariaDB
        |
        +--> Stored Procedures
        |
        +--> Triggers
        |
        +--> InnoDB Transactions
```

Application source is intentionally outside the public web root.

## Directory structure

```text
/
├── .github/
│   └── workflows/
│       └── deploy.yml
├── .htaccess
├── README.md
├── database.sql
├── config/
│   ├── .htaccess
│   └── database.php
├── app/
│   ├── Core/
│   │   ├── Autoloader.php
│   │   ├── Router.php
│   │   ├── Controller.php
│   │   └── Model.php
│   ├── Controllers/
│   │   ├── POSController.php
│   │   ├── InventoryController.php
│   │   └── CustomerController.php
│   ├── Models/
│   │   ├── Product.php
│   │   ├── Batch.php
│   │   └── Invoice.php
│   └── Views/
│       ├── layouts/
│       │   ├── header.php
│       │   └── footer.php
│       └── pos/
│           └── index.php
├── public/
│   ├── .htaccess
│   ├── index.php
│   ├── css/
│   │   └── pos.css
│   └── js/
│       ├── scanner.js
│       ├── cart.js
│       └── offline-db.js
└── logs/
    ├── .htaccess
    └── error.log
```

## Database

The complete database deployment script is:

```text
database.sql
```

Import it through phpMyAdmin.

### Main entities

- `companies`
- `stores`
- `units_of_measure`
- `suppliers`
- `products`
- `store_product_settings`
- `inventory_batches`
- `customers`
- `invoices`
- `invoice_items`
- `invoice_payments`
- `purchase_order_drafts`
- `inventory_stock_audit`

### Stored procedures

#### `Sp_GetProductForPOS`

Performs barcode lookup for the current store and returns the first available batch using FEFO ordering:

1. Valid product only.
2. Current store only.
3. Positive stock only.
4. Unexpired batch only.
5. Earliest expiry first.
6. Stable batch ID tie-breaker.

#### `Sp_CompleteCheckoutTransaction`

The authoritative checkout transaction.

It:

1. Starts an ACID transaction.
2. Validates company/store context.
3. Validates checkout items.
4. Locks inventory batches with `FOR UPDATE`.
5. Validates available stock.
6. Calculates taxable values.
7. Calculates CGST/SGST or IGST.
8. Deducts batch stock.
9. Reconciles split payments against the calculated grand total.
10. Creates the invoice.
11. Creates invoice line items.
12. Records every payment.
13. Updates customer loyalty points.
14. Commits only when all operations succeed.

Any database exception causes a rollback.

### Triggers

#### `Trg_InventoryBatchStockAudit`

Records stock changes in `inventory_stock_audit`.

#### `Trg_CheckLowStockAlert`

When aggregate store stock falls below the configured minimum, it creates a `Draft` procurement suggestion if one does not already exist.

## POS API

### Barcode lookup

```http
GET /api/pos/lookup?barcode=8901234567890
```

### Checkout

```http
POST /api/pos/checkout
Content-Type: application/json
X-CSRF-Token: <session-token>
```

Example payload:

```json
{
  "_csrf": "session-token",
  "customer_id": 12,
  "items": [
    {
      "batch_id": 101,
      "quantity": 1.250,
      "unit_price": 120.00,
      "discount_amount": 0.00
    }
  ],
  "payments": [
    {
      "mode": "Cash",
      "amount": 150.00,
      "reference_no": ""
    }
  ]
}
```

The server/database recalculates the actual invoice totals. Client-side totals are never treated as authoritative.

### Dynamic UPI URI

```http
GET /api/pos/upi?amount=150.00
```

The endpoint uses:

- `UPI_VPA`
- `UPI_PAYEE_NAME`

and returns a UPI payment URI.

### Inventory

```http
POST /api/inventory/batch
GET  /api/inventory/low-stock
```

### CRM

```http
GET /api/customer/profile?phone=<phone>
GET /api/customer/bill?invoice_id=<invoice_id>
```

## Configuration

The application reads database configuration from environment variables:

```text
DB_HOST
DB_PORT
DB_NAME
DB_USER
DB_PASS
UPI_VPA
UPI_PAYEE_NAME
```

Do not commit real credentials.

For shared hosting, configure the variables using the hosting environment or the hosting provider's supported PHP configuration mechanism.

## GitHub Actions deployment

Workflow:

```text
.github/workflows/deploy.yml
```

Required GitHub Actions secrets:

```text
FTP_SERVER
FTP_USERNAME
FTP_PASSWORD
```

The workflow uses:

```text
SamKirkland/FTP-Deploy-Action
```

The deployment intentionally excludes:

- Git metadata
- GitHub workflow files
- `database.sql`
- Application logs

The database must therefore be imported separately through phpMyAdmin.

## Security

Current security architecture includes:

- PDO prepared statements.
- Native session handling.
- CSRF token validation for mutating POS/inventory requests.
- `htmlspecialchars()` escaping in rendered PHP values.
- Password hashing should use PHP `PASSWORD_DEFAULT` when authentication is introduced.
- Application/config/log directories blocked by Apache.
- `database.sql` blocked from HTTP access.
- Database-side stock locking.
- Database-side payment reconciliation.
- Database-side GST calculations.
- Database transaction rollback on checkout failure.

### Important deployment rule

Never expose:

```text
/app
/config
/logs
database.sql
```

as directly downloadable web resources.

## Barcode scanning

The POS supports two modes.

### USB laser scanner

Most USB scanners operate as keyboard wedges. `scanner.js` detects rapid barcode keystrokes and submits the accumulated barcode without requiring a dedicated driver.

### Mobile camera

The POS can activate the browser camera using `html5-qrcode`.

Camera scanning is intended for supported HTTPS browser environments.

## Offline behavior

The POS uses IndexedDB to queue checkout payloads when the server cannot be reached.

When connectivity returns:

1. The browser detects the online event.
2. Queued transactions are retried.
3. Successfully accepted transactions are removed from the queue.

Server-side business validation failures are **not** treated as offline failures and are not silently re-queued.

### Offline design consideration

Offline checkout is intentionally limited by the fact that authoritative stock lives in the central database. Multiple terminals can independently sell the same inventory while disconnected.

Before enabling autonomous offline selling for high-volume multi-terminal stores, the platform should add a reservation/idempotency strategy and explicit conflict handling.

## GST

The database stores:

- HSN/SAC code
- CGST rate
- SGST rate
- IGST rate

For an intra-state sale:

```text
Taxable Value
    + CGST
    + SGST
    = Grand Total
```

For an inter-state sale:

```text
Taxable Value
    + IGST
    = Grand Total
```

The checkout procedure determines the applicable tax split from store/company state context.

## Monetary and quantity precision

Currency values use two decimal places.

Inventory quantities use three decimal places.

Examples:

```text
₹125.50
1.250 kg
0.500 L
```

The database uses DECIMAL columns rather than floating-point database fields for financial values.

## Development principles

Every future feature should preserve these rules:

1. No unnecessary external backend dependencies.
2. No Node.js build requirement.
3. No Composer requirement on production hosting.
4. Database mutations must remain transactionally safe.
5. Stock cannot be trusted from browser state.
6. Financial totals must be recalculated server-side/database-side.
7. Every mutating HTTP request must be protected against CSRF.
8. User-controlled output must be escaped.
9. Store/company boundaries must be enforced.
10. README must be updated whenever architecture, deployment, database behavior, APIs, or major features change.

## Roadmap

### Phase 1 — POS foundation

- [x] Database foundation
- [x] Product/barcode lookup
- [x] FEFO selection
- [x] Cart
- [x] Decimal quantities
- [x] GST
- [x] Split payments
- [x] UPI URI
- [x] Atomic checkout
- [x] Basic offline queue

### Phase 2 — Store operations

- [ ] Authentication and RBAC
- [ ] Product management
- [ ] Batch receiving
- [ ] Stock transfers
- [ ] Stock adjustment
- [ ] Expiry/clearance dashboard
- [ ] Purchase order workflow
- [ ] Supplier management
- [ ] Store/warehouse management

### Phase 3 — CRM

- [ ] Customer registration UI
- [ ] Customer purchase history
- [ ] Loyalty configuration
- [ ] Tier rules
- [ ] Digital bill delivery
- [ ] Customer-specific promotions

### Phase 4 — Enterprise

- [ ] Multi-terminal session management
- [ ] Cashier shifts
- [ ] Cash drawer reconciliation
- [ ] Returns/refunds
- [ ] Credit sales
- [ ] Advanced reporting
- [ ] Audit/event history
- [ ] Role-based permissions
- [ ] Idempotent offline synchronization

## README maintenance policy

This README is part of the application documentation and should evolve with the codebase.

Whenever a repository change introduces or changes any of the following, update this file in the same change:

- Database tables, indexes, procedures or triggers.
- API routes or request/response contracts.
- POS behavior.
- Authentication/security rules.
- Deployment requirements.
- Environment variables.
- Directory structure.
- External CDN dependencies.
- Offline synchronization behavior.
- Major UI/workflow changes.
- Completed roadmap items.

**Rule:** code and documentation should move together.

## License

No license has been declared yet. Until a license is explicitly added to the repository, all rights are reserved by the repository owner.
