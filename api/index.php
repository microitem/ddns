<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once 'config.php';

header('Content-Type: application/json');

// Získanie parametrov
$hostname = isset($_GET['hostname']) ? $_GET['hostname'] : '';
$ip = isset($_GET['ip']) ? $_GET['ip'] : $_SERVER['REMOTE_ADDR'];

if (empty($hostname)) {
    http_response_code(400);
    die(json_encode(['success' => false, 'message' => 'Missing hostname parameter']));
}

// Vytvorenie plného doménového mena
$fqdn = $hostname . '.' . ZONE_NAME;

// Aktualizácia DNS záznamu cez PowerDNS API
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, PDNS_API_URL . '/zones/' . ZONE_NAME);
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PATCH');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'X-API-Key: ' . PDNS_API_KEY,
    'Content-Type: application/json'
]);

$data = [
    'rrsets' => [
        [
            'name' => $fqdn,
            'type' => 'A',
            'ttl' => 60,
            'changetype' => 'REPLACE',
            'records' => [
                [
                    'content' => $ip,
                    'disabled' => false
                ]
            ]
        ]
    ]
];

curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

if ($http_code === 204) {
    echo json_encode(['success' => true, 'message' => 'DNS record updated']);
} else {
    http_response_code(500);
    echo json_encode([
        'success' => false, 
        'message' => 'Failed to update DNS record',
        'error' => $error,
        'response' => $response,
        'http_code' => $http_code
    ]);
}
