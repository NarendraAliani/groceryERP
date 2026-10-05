-- groceryERP database deployment script
SET NAMES utf8mb4;
SET time_zone = '+00:00';
SET FOREIGN_KEY_CHECKS = 0;

CREATE DATABASE IF NOT EXISTS grocery_erp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE grocery_erp;

DROP TRIGGER IF EXISTS Trg_CheckLowStockAlert;
DROP TRIGGER IF EXISTS Trg_InventoryBatchStockAudit;
DROP PROCEDURE IF EXISTS Sp_GetProductForPOS;
DROP PROCEDURE IF EXISTS Sp_CompleteCheckoutTransaction;

CREATE TABLE IF NOT EXISTS companies (
 company_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 name VARCHAR(160) NOT NULL,
 gstin VARCHAR(15) NULL,
 state_code CHAR(2) NOT NULL,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 UNIQUE KEY uq_company_gstin (gstin)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS stores (
 store_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 company_id INT UNSIGNED NOT NULL,
 name VARCHAR(160) NOT NULL,
 address VARCHAR(500) NOT NULL,
 state_code CHAR(2) NOT NULL,
 is_active TINYINT(1) NOT NULL DEFAULT 1,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_stores_company FOREIGN KEY (company_id) REFERENCES companies(company_id),
 KEY idx_store_company (company_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS units_of_measure (
 uom_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 unit_code VARCHAR(12) NOT NULL,
 unit_name VARCHAR(50) NOT NULL,
 allows_decimal TINYINT(1) NOT NULL DEFAULT 0,
 UNIQUE KEY uq_uom_code (unit_code)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS suppliers (
 supplier_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 company_id INT UNSIGNED NOT NULL,
 name VARCHAR(180) NOT NULL,
 gstin VARCHAR(15) NULL,
 phone VARCHAR(20) NULL,
 is_active TINYINT(1) NOT NULL DEFAULT 1,
 CONSTRAINT fk_supplier_company FOREIGN KEY (company_id) REFERENCES companies(company_id),
 KEY idx_supplier_company (company_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS products (
 product_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 barcode VARCHAR(50) NOT NULL,
 hsn_code VARCHAR(20) NULL,
 name VARCHAR(220) NOT NULL,
 category VARCHAR(100) NULL,
 uom_id SMALLINT UNSIGNED NOT NULL,
 cgst_rate DECIMAL(5,2) NOT NULL DEFAULT 0.00,
 sgst_rate DECIMAL(5,2) NOT NULL DEFAULT 0.00,
 igst_rate DECIMAL(5,2) NOT NULL DEFAULT 0.00,
 is_active TINYINT(1) NOT NULL DEFAULT 1,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 CONSTRAINT fk_products_uom FOREIGN KEY (uom_id) REFERENCES units_of_measure(uom_id),
 UNIQUE KEY uq_product_barcode (barcode),
 KEY idx_product_active_barcode (barcode, is_active)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS store_product_settings (
 store_id INT UNSIGNED NOT NULL,
 product_id INT UNSIGNED NOT NULL,
 minimum_stock DECIMAL(18,3) NOT NULL DEFAULT 0.000,
 reorder_qty DECIMAL(18,3) NOT NULL DEFAULT 1.000,
 is_active TINYINT(1) NOT NULL DEFAULT 1,
 PRIMARY KEY (store_id, product_id),
 CONSTRAINT fk_sps_store FOREIGN KEY (store_id) REFERENCES stores(store_id),
 CONSTRAINT fk_sps_product FOREIGN KEY (product_id) REFERENCES products(product_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS inventory_batches (
 batch_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 store_id INT UNSIGNED NOT NULL,
 product_id INT UNSIGNED NOT NULL,
 supplier_id INT UNSIGNED NULL,
 lot_number VARCHAR(80) NULL,
 cost_price DECIMAL(14,2) NOT NULL DEFAULT 0.00,
 selling_price DECIMAL(14,2) NOT NULL DEFAULT 0.00,
 current_stock DECIMAL(18,3) NOT NULL DEFAULT 0.000,
 mfg_date DATE NULL,
 expiry_date DATE NULL,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 CONSTRAINT fk_batch_store FOREIGN KEY (store_id) REFERENCES stores(store_id),
 CONSTRAINT fk_batch_product FOREIGN KEY (product_id) REFERENCES products(product_id),
 CONSTRAINT fk_batch_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id),
 KEY idx_batch_fefo (store_id, product_id, current_stock, expiry_date, batch_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS customers (
 customer_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 phone VARCHAR(20) NOT NULL,
 name VARCHAR(160) NOT NULL,
 loyalty_points INT UNSIGNED NOT NULL DEFAULT 0,
 tier ENUM('Regular','Silver','Gold','Platinum') NOT NULL DEFAULT 'Regular',
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 UNIQUE KEY uq_customer_phone (phone)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS invoices (
 invoice_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 store_id INT UNSIGNED NOT NULL,
 customer_id BIGINT UNSIGNED NULL,
 invoice_number VARCHAR(40) NOT NULL,
 subtotal DECIMAL(14,2) NOT NULL DEFAULT 0.00,
 total_cgst DECIMAL(14,2) NOT NULL DEFAULT 0.00,
 total_sgst DECIMAL(14,2) NOT NULL DEFAULT 0.00,
 total_igst DECIMAL(14,2) NOT NULL DEFAULT 0.00,
 grand_total DECIMAL(14,2) NOT NULL DEFAULT 0.00,
 payment_status ENUM('Pending','Paid','Partially Paid','Cancelled') NOT NULL DEFAULT 'Pending',
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_invoice_store FOREIGN KEY (store_id) REFERENCES stores(store_id),
 CONSTRAINT fk_invoice_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
 UNIQUE KEY uq_invoice_store_number (store_id, invoice_number)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS invoice_items (
 item_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 invoice_id BIGINT UNSIGNED NOT NULL,
 batch_id BIGINT UNSIGNED NOT NULL,
 quantity DECIMAL(18,3) NOT NULL,
 unit_price DECIMAL(14,2) NOT NULL,
 discount_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
 cgst_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
 sgst_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
 igst_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
 row_total DECIMAL(14,2) NOT NULL,
 CONSTRAINT fk_invoice_item_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id),
 CONSTRAINT fk_invoice_item_batch FOREIGN KEY (batch_id) REFERENCES inventory_batches(batch_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS invoice_payments (
 payment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 invoice_id BIGINT UNSIGNED NOT NULL,
 mode ENUM('Cash','Card','UPI') NOT NULL,
 amount DECIMAL(14,2) NOT NULL,
 reference_no VARCHAR(120) NULL,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_payment_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS purchase_order_drafts (
 draft_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 store_id INT UNSIGNED NOT NULL,
 product_id INT UNSIGNED NOT NULL,
 suggested_qty DECIMAL(18,3) NOT NULL,
 status ENUM('Draft','Converted','Cancelled') NOT NULL DEFAULT 'Draft',
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_pod_store FOREIGN KEY (store_id) REFERENCES stores(store_id),
 CONSTRAINT fk_pod_product FOREIGN KEY (product_id) REFERENCES products(product_id),
 KEY idx_pod_status (store_id, product_id, status)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS inventory_stock_audit (
 audit_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 batch_id BIGINT UNSIGNED NOT NULL,
 store_id INT UNSIGNED NOT NULL,
 product_id INT UNSIGNED NOT NULL,
 old_stock DECIMAL(18,3) NOT NULL,
 new_stock DECIMAL(18,3) NOT NULL,
 changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 KEY idx_stock_audit_batch (batch_id, changed_at)
) ENGINE=InnoDB;

DELIMITER $$

CREATE TRIGGER Trg_InventoryBatchStockAudit
AFTER UPDATE ON inventory_batches
FOR EACH ROW
BEGIN
 IF OLD.current_stock <> NEW.current_stock THEN
  INSERT INTO inventory_stock_audit(batch_id,store_id,product_id,old_stock,new_stock)
  VALUES(NEW.batch_id,NEW.store_id,NEW.product_id,OLD.current_stock,NEW.current_stock);
 END IF;
END$$

CREATE TRIGGER Trg_CheckLowStockAlert
AFTER UPDATE ON inventory_batches
FOR EACH ROW
BEGIN
 DECLARE v_total_stock DECIMAL(18,3) DEFAULT 0.000;
 DECLARE v_minimum_stock DECIMAL(18,3) DEFAULT 0.000;
 DECLARE v_reorder_qty DECIMAL(18,3) DEFAULT 1.000;
 IF OLD.current_stock <> NEW.current_stock THEN
  SELECT COALESCE(SUM(current_stock),0.000) INTO v_total_stock
  FROM inventory_batches WHERE store_id=NEW.store_id AND product_id=NEW.product_id AND current_stock>0;
  SELECT COALESCE(minimum_stock,0.000),COALESCE(reorder_qty,1.000)
  INTO v_minimum_stock,v_reorder_qty
  FROM store_product_settings
  WHERE store_id=NEW.store_id AND product_id=NEW.product_id LIMIT 1;
  IF v_total_stock <= v_minimum_stock AND v_minimum_stock > 0 THEN
   INSERT INTO purchase_order_drafts(store_id,product_id,suggested_qty,status)
   SELECT NEW.store_id,NEW.product_id,
          GREATEST(v_reorder_qty,v_minimum_stock-v_total_stock+v_reorder_qty),'Draft'
   WHERE NOT EXISTS(
    SELECT 1 FROM purchase_order_drafts
    WHERE store_id=NEW.store_id AND product_id=NEW.product_id AND status='Draft'
   );
  END IF;
 END IF;
END$$

CREATE PROCEDURE Sp_GetProductForPOS(IN p_barcode VARCHAR(50),IN p_store_id INT)
BEGIN
 SELECT p.product_id,p.barcode,p.hsn_code,p.name,p.category,p.uom_id,
        u.unit_code,u.unit_name,u.allows_decimal,p.cgst_rate,p.sgst_rate,p.igst_rate,
        b.batch_id,b.lot_number,b.selling_price,b.current_stock,b.expiry_date
 FROM products p
 JOIN units_of_measure u ON u.uom_id=p.uom_id
 JOIN inventory_batches b ON b.product_id=p.product_id
 WHERE p.barcode=p_barcode AND p.is_active=1 AND b.store_id=p_store_id
   AND b.current_stock>0 AND (b.expiry_date IS NULL OR b.expiry_date>=CURRENT_DATE())
 ORDER BY CASE WHEN b.expiry_date IS NULL THEN 1 ELSE 0 END,b.expiry_date,b.batch_id
 LIMIT 1;
END$$

DELIMITER ;

INSERT IGNORE INTO units_of_measure(unit_code,unit_name,allows_decimal)
VALUES ('pcs','Pieces',0),('kg','Kilogram',1),('g','Gram',1),('L','Litre',1),('ml','Millilitre',1),('pkt','Packet',0);

SET FOREIGN_KEY_CHECKS=1;

DELIMITER $$

DROP PROCEDURE IF EXISTS Sp_CompleteCheckoutTransaction$$

CREATE PROCEDURE Sp_CompleteCheckoutTransaction(
 IN p_company_id INT, IN p_store_id INT, IN p_customer_id BIGINT,
 IN p_invoice_number VARCHAR(40), IN p_items JSON, IN p_payments JSON
)
SQL SECURITY INVOKER
BEGIN
 DECLARE v_done INT DEFAULT 0;
 DECLARE v_batch_id BIGINT UNSIGNED;
 DECLARE v_quantity DECIMAL(18,3);
 DECLARE v_unit_price DECIMAL(14,2);
 DECLARE v_discount DECIMAL(14,2);
 DECLARE v_product_id INT UNSIGNED;
 DECLARE v_cgst_rate DECIMAL(5,2);
 DECLARE v_sgst_rate DECIMAL(5,2);
 DECLARE v_igst_rate DECIMAL(5,2);
 DECLARE v_stock DECIMAL(18,3);
 DECLARE v_taxable DECIMAL(14,2);
 DECLARE v_cgst DECIMAL(14,2);
 DECLARE v_sgst DECIMAL(14,2);
 DECLARE v_igst DECIMAL(14,2);
 DECLARE v_subtotal DECIMAL(14,2) DEFAULT 0.00;
 DECLARE v_total_cgst DECIMAL(14,2) DEFAULT 0.00;
 DECLARE v_total_sgst DECIMAL(14,2) DEFAULT 0.00;
 DECLARE v_total_igst DECIMAL(14,2) DEFAULT 0.00;
 DECLARE v_grand_total DECIMAL(14,2) DEFAULT 0.00;
 DECLARE v_payment_total DECIMAL(14,2) DEFAULT 0.00;
 DECLARE v_invoice_id BIGINT UNSIGNED;
 DECLARE v_store_state CHAR(2);
 DECLARE v_company_state CHAR(2);
 DECLARE v_msg TEXT DEFAULT 'Checkout failed.';
 DECLARE cur CURSOR FOR SELECT batch_id,quantity,unit_price,discount_amount FROM tmp_checkout_items ORDER BY item_seq;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done=1;
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  ROLLBACK;
  DROP TEMPORARY TABLE IF EXISTS tmp_checkout_items;
  DROP TEMPORARY TABLE IF EXISTS tmp_checkout_payments;
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_msg;
 END;

 IF p_items IS NULL OR JSON_TYPE(p_items)<>'ARRAY' OR JSON_LENGTH(p_items)=0 THEN
  SET v_msg='Checkout requires at least one item.'; SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_msg;
 END IF;
 IF p_payments IS NULL OR JSON_TYPE(p_payments)<>'ARRAY' OR JSON_LENGTH(p_payments)=0 THEN
  SET v_msg='Checkout requires at least one payment.'; SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_msg;
 END IF;

 START TRANSACTION;

 SELECT s.state_code,c.state_code INTO v_store_state,v_company_state
 FROM stores s JOIN companies c ON c.company_id=s.company_id
 WHERE s.store_id=p_store_id AND s.company_id=p_company_id AND s.is_active=1
 FOR UPDATE;
 IF v_store_state IS NULL THEN
  SET v_msg='Invalid company/store context.'; SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_msg;
 END IF;

 DROP TEMPORARY TABLE IF EXISTS tmp_checkout_items;
 CREATE TEMPORARY TABLE tmp_checkout_items(
  item_seq INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  batch_id BIGINT UNSIGNED NOT NULL,
  quantity DECIMAL(18,3) NOT NULL,
  unit_price DECIMAL(14,2) NOT NULL,
  discount_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00
 ) ENGINE=InnoDB;

 INSERT INTO tmp_checkout_items(batch_id,quantity,unit_price,discount_amount)
 SELECT batch_id,quantity,unit_price,COALESCE(discount_amount,0.00)
 FROM JSON_TABLE(p_items,'$[*]' COLUMNS(
  batch_id BIGINT UNSIGNED PATH '$.batch_id',
  quantity DECIMAL(18,3) PATH '$.quantity',
  unit_price DECIMAL(14,2) PATH '$.unit_price',
  discount_amount DECIMAL(14,2) PATH '$.discount_amount' DEFAULT 0 ON EMPTY
 )) j;

 IF EXISTS(SELECT 1 FROM tmp_checkout_items WHERE quantity<=0 OR unit_price<0 OR discount_amount<0) THEN
  SET v_msg='Invalid quantity, price or discount.'; SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_msg;
 END IF;

 DROP TEMPORARY TABLE IF EXISTS tmp_checkout_payments;
 CREATE TEMPORARY TABLE tmp_checkout_payments(
  payment_seq INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  mode VARCHAR(10) NOT NULL,
  amount DECIMAL(14,2) NOT NULL,
  reference_no VARCHAR(120) NULL
 ) ENGINE=InnoDB;

 INSERT INTO tmp_checkout_payments(mode,amount,reference_no)
 SELECT mode,amount,reference_no
 FROM JSON_TABLE(p_payments,'$[*]' COLUMNS(
  mode VARCHAR(10) PATH '$.mode',
  amount DECIMAL(14,2) PATH '$.amount',
  reference_no VARCHAR(120) PATH '$.reference_no' NULL ON EMPTY
 )) j;

 IF EXISTS(SELECT 1 FROM tmp_checkout_payments WHERE mode NOT IN('Cash','Card','UPI') OR amount<=0) THEN
  SET v_msg='Invalid payment mode or amount.'; SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_msg;
 END IF;

 OPEN cur;
 item_loop: LOOP
  FETCH cur INTO v_batch_id,v_quantity,v_unit_price,v_discount;
  IF v_done=1 THEN LEAVE item_loop; END IF;

  SET v_product_id=NULL; SET v_stock=NULL;
  SELECT b.product_id,p.cgst_rate,p.sgst_rate,p.igst_rate,b.current_stock
  INTO v_product_id,v_cgst_rate,v_sgst_rate,v_igst_rate,v_stock
  FROM inventory_batches b JOIN products p ON p.product_id=b.product_id
  WHERE b.batch_id=v_batch_id AND b.store_id=p_store_id AND p.is_active=1
  FOR UPDATE;

  IF v_product_id IS NULL THEN
   SET v_msg='Batch is not valid for this store.'; SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_msg;
  END IF;
  IF v_stock<v_quantity THEN
   SET v_msg='Insufficient batch stock.'; SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_msg;
  END IF;

  SET v_taxable=ROUND(v_quantity*v_unit_price-v_discount,2);
  IF v_taxable<0 THEN
   SET v_msg='Discount exceeds line value.'; SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_msg;
  END IF;

  IF v_store_state=v_company_state THEN
   SET v_cgst=ROUND(v_taxable*v_cgst_rate/100,2);
   SET v_sgst=ROUND(v_taxable*v_sgst_rate/100,2);
   SET v_igst=0.00;
  ELSE
   SET v_cgst=0.00; SET v_sgst=0.00;
   SET v_igst=ROUND(v_taxable*v_igst_rate/100,2);
  END IF;

  SET v_subtotal=ROUND(v_subtotal+v_taxable,2);
  SET v_total_cgst=ROUND(v_total_cgst+v_cgst,2);
  SET v_total_sgst=ROUND(v_total_sgst+v_sgst,2);
  SET v_total_igst=ROUND(v_total_igst+v_igst,2);

  UPDATE inventory_batches SET current_stock=current_stock-v_quantity WHERE batch_id=v_batch_id;
 END LOOP;
 CLOSE cur;

 SET v_grand_total=ROUND(v_subtotal+v_total_cgst+v_total_sgst+v_total_igst,2);
 SELECT COALESCE(SUM(amount),0.00) INTO v_payment_total FROM tmp_checkout_payments;
 IF ABS(v_payment_total-v_grand_total)>0.009 THEN
  SET v_msg='Payment total does not equal invoice total.'; SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_msg;
 END IF;

 INSERT INTO invoices(store_id,customer_id,invoice_number,subtotal,total_cgst,total_sgst,total_igst,grand_total,payment_status)
 VALUES(p_store_id,NULLIF(p_customer_id,0),p_invoice_number,v_subtotal,v_total_cgst,v_total_sgst,v_total_igst,v_grand_total,'Paid');
 SET v_invoice_id=LAST_INSERT_ID();

 INSERT INTO invoice_items(invoice_id,batch_id,quantity,unit_price,discount_amount,cgst_amount,sgst_amount,igst_amount,row_total)
 SELECT v_invoice_id,x.batch_id,x.quantity,x.unit_price,x.discount_amount,
  ROUND(CASE WHEN v_store_state=v_company_state THEN (x.quantity*x.unit_price-x.discount_amount)*p.cgst_rate/100 ELSE 0 END,2),
  ROUND(CASE WHEN v_store_state=v_company_state THEN (x.quantity*x.unit_price-x.discount_amount)*p.sgst_rate/100 ELSE 0 END,2),
  ROUND(CASE WHEN v_store_state<>v_company_state THEN (x.quantity*x.unit_price-x.discount_amount)*p.igst_rate/100 ELSE 0 END,2),
  ROUND((x.quantity*x.unit_price-x.discount_amount)+CASE WHEN v_store_state=v_company_state
   THEN (x.quantity*x.unit_price-x.discount_amount)*(p.cgst_rate+p.sgst_rate)/100
   ELSE (x.quantity*x.unit_price-x.discount_amount)*p.igst_rate/100 END,2)
 FROM tmp_checkout_items x JOIN inventory_batches b ON b.batch_id=x.batch_id JOIN products p ON p.product_id=b.product_id;

 INSERT INTO invoice_payments(invoice_id,mode,amount,reference_no)
 SELECT v_invoice_id,mode,amount,reference_no FROM tmp_checkout_payments;

 IF p_customer_id IS NOT NULL AND p_customer_id>0 THEN
  UPDATE customers
  SET loyalty_points=loyalty_points+FLOOR(v_grand_total/100),
      tier=CASE WHEN loyalty_points+FLOOR(v_grand_total/100)>=10000 THEN 'Platinum'
                WHEN loyalty_points+FLOOR(v_grand_total/100)>=5000 THEN 'Gold'
                WHEN loyalty_points+FLOOR(v_grand_total/100)>=1000 THEN 'Silver'
                ELSE 'Regular' END
  WHERE customer_id=p_customer_id;
 END IF;

 COMMIT;
 DROP TEMPORARY TABLE IF EXISTS tmp_checkout_items;
 DROP TEMPORARY TABLE IF EXISTS tmp_checkout_payments;

 SELECT v_invoice_id AS invoice_id,p_invoice_number AS invoice_number,v_subtotal AS subtotal,
        v_total_cgst AS total_cgst,v_total_sgst AS total_sgst,v_total_igst AS total_igst,
        v_grand_total AS grand_total,'Paid' AS payment_status;
END$$

DELIMITER ;
