<?php
declare(strict_types=1);

namespace GroceryERP\Core;

final class Router
{
    private array $routes = [];

    public function get(string $pattern, callable $handler): void { $this->add('GET', $pattern, $handler); }
    public function post(string $pattern, callable $handler): void { $this->add('POST', $pattern, $handler); }

    private function add(string $method, string $pattern, callable $handler): void
    {
        $this->routes[] = [$method, $pattern, $handler];
    }

    public function dispatch(string $method, string $path): mixed
    {
        foreach ($this->routes as [$routeMethod, $pattern, $handler]) {
            if ($method !== $routeMethod) continue;
            if (preg_match($pattern, $path, $matches)) {
                return $handler($matches);
            }
        }
        http_response_code(404);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode(['success' => false, 'data' => ['message' => 'Route not found']]);
        return null;
    }
}
