<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Koneksi ke database (sesuaikan dengan konfigurasi lu)
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "taskverse_db";

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Ambil data dari request
    $data = json_decode(file_get_contents('php://input'), true);
    
    $email = $data['email'] ?? '';
    $password = $data['password'] ?? '';
    
    // Validasi input
    if (empty($email) || empty($password)) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Email and password are required'
        ]);
        exit;
    }
    
    // Cek user di database
    $stmt = $conn->prepare("SELECT id, name, email, password, avatar_url FROM users WHERE email = ?");
    $stmt->execute([$email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$user) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Email not found'
        ]);
        exit;
    }
    
    // Verifikasi password
    if (!password_verify($password, $user['password'])) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Invalid password'
        ]);
        exit;
    }
    
    // Generate token (sama kayak register)
    $token = base64_encode(json_encode([
        'user_id' => $user['id'],
        'exp' => time() + 86400 // Token expires in 24 hours
    ]));
    
    // Response
    echo json_encode([
        'status' => 'success',
        'data' => [
            'id' => $user['id'],
            'name' => $user['name'],
            'email' => $user['email'],
            'avatar_url' => $user['avatar_url']
        ],
        'token' => $token
    ]);
    
} catch (PDOException $e) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Database error: ' . $e->getMessage()
    ]);
}

$conn = null;
?>