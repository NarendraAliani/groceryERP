<?php
declare(strict_types=1);

namespace GroceryERP\Core;

use Throwable;

abstract class Controller
{
    protected function json(array $data = [], bool $success = true, int $status = 200): never
    {
        http_response_code($status);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode(['success'=>$success,'data'=>$data], JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES);
        exit;
    }

    protected function input(): array
    {
        $raw = file_get_contents('php://input') ?: '';
        if ($raw === '') return $_POST ?: [];
        $data = json_decode($raw, true);
        if (!is_array($data)) $this->json([], false, 400);
        return $data;
    }

    protected function csrfToken(): string
    {
        if (empty($_SESSION['_csrf'])) $_SESSION['_csrf'] = bin2hex(random_bytes(32));
        return $_SESSION['_csrf'];
    }

    protected function verifyCsrf(array $input): void
    {
        $token = (string)($input['_csrf'] ?? ($_SERVER['HTTP_X_CSRF_TOKEN'] ?? ''));
        if ($token === '' || !hash_equals($this->csrfToken(), $token)) $this->json([], false, 419);
    }

    protected function requireStoreContext(): array
    {
        $companyId = (int)($_SESSION['company_id'] ?? 0);
        $storeId = (int)($_SESSION['store_id'] ?? 0);
        if ($companyId <= 0 || $storeId <= 0) $this->json([], false, 401);
        return [$companyId, $storeId];
    }

    protected function cleanString(mixed $value, int $max = 255): string
    {
        return mb_substr(trim((string)$value), 0, $max);
    }

    protected function decimal(mixed $value, int $scale = 3): float
    {
        return round((float)$value, $scale);
    }

    protected function escape(mixed $value): string
    {
        return htmlspecialchars((string)$value, ENT_QUOTES|ENT_SUBSTITUTE, 'UTF-8');
    }

    protected function error(Throwable $e, string $message = 'Request failed.'): never
    {
        $file = dirname(__DIR__, 2) . '/logs/error.log';
        @file_put_contents($file, '[' . gmdate('c') . '] ' . $e->getMessage() . PHP_EOL, FILE_APPEND|LOCK_EX);
        $this->json(['message'=>$message], false, 500);
    }
}
