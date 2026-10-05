<?php declare(strict_types=1); ?>
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<meta name="csrf-token" content="<?= htmlspecialchars($_SESSION['_csrf'] ?? '', ENT_QUOTES, 'UTF-8') ?>">
<title><?= htmlspecialchars($title ?? 'groceryERP POS', ENT_QUOTES, 'UTF-8') ?></title>
<link rel="stylesheet" href="/css/pos.css">
</head>
<body>
<div class="app-shell">
