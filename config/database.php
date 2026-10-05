<?php
declare(strict_types=1);

namespace GroceryERP\Config;

use PDO;
use PDOException;
use RuntimeException;

final class Database
{
    private static ?PDO $instance = null;
    private function __construct() {}

    public static function connection(): PDO
    {
        if (self::$instance instanceof PDO) return self::$instance;

        $host = getenv('DB_HOST') ?: '127.0.0.1';
        $port = getenv('DB_PORT') ?: '3306';
        $name = getenv('DB_NAME') ?: 'grocery_erp';
        $user = getenv('DB_USER') ?: '';
        $pass = getenv('DB_PASS') ?: '';
        $dsn = "mysql:host={$host};port={$port};dbname={$name};charset=utf8mb4";

        try {
            self::$instance = new PDO($dsn, $user, $pass, [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
                PDO::ATTR_STRINGIFY_FETCHES => false,
            ]);
            self::$instance->exec("SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci");
            return self::$instance;
        } catch (PDOException $e) {
            $file = dirname(__DIR__) . '/logs/error.log';
            @mkdir(dirname($file), 0750, true);
            @file_put_contents($file, '[' . gmdate('c') . '] DB failure: ' . $e->getMessage() . PHP_EOL, FILE_APPEND | LOCK_EX);
            throw new RuntimeException('Database service is temporarily unavailable.', 0, $e);
        }
    }
}
