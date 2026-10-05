<?php
declare(strict_types=1);

namespace GroceryERP\Core;

final class Autoloader
{
    public static function register(): void
    {
        spl_autoload_register(static function (string $class): void {
            $prefixes = [
                'GroceryERP\\Core\\' => dirname(__DIR__) . '/Core/',
                'GroceryERP\\Controllers\\' => dirname(__DIR__) . '/Controllers/',
                'GroceryERP\\Models\\' => dirname(__DIR__) . '/Models/',
                'GroceryERP\\Config\\' => dirname(__DIR__, 2) . '/config/',
            ];

            foreach ($prefixes as $prefix => $base) {
                if (strncmp($class, $prefix, strlen($prefix)) !== 0) continue;
                $relative = substr($class, strlen($prefix));
                $file = $base . str_replace('\\', DIRECTORY_SEPARATOR, $relative) . '.php';
                if (is_file($file)) require_once $file;
                return;
            }
        });
    }
}
