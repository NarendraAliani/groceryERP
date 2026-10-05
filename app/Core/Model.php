<?php
declare(strict_types=1);

namespace GroceryERP\Core;

use GroceryERP\Config\Database;
use PDO;

abstract class Model
{
    protected PDO $db;

    public function __construct()
    {
        $this->db = Database::connection();
    }

    protected function procedure(string $name, array $params = []): array
    {
        $sql = 'CALL ' . $name . '(' . implode(',', array_fill(0, count($params), '?')) . ')';
        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        $rows = $stmt->fetchAll();
        while ($stmt->nextRowset()) {}
        $stmt->closeCursor();
        return $rows;
    }

    protected function query(string $sql, array $params = []): array
    {
        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll();
    }

    protected function execute(string $sql, array $params = []): int
    {
        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        return $stmt->rowCount();
    }
}
