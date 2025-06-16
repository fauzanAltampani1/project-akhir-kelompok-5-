<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Koneksi ke database (ganti sesuai konfigurasi lu)
$servername = "localhost";
$username = "root"; // Default XAMPP username
$password = ""; // Default XAMPP password (kosong)
$dbname = "taskverse_db";

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Ambil data dari request
    $data = json_decode(file_get_contents('php://input'), true);
    
    $name = $data['name'] ?? '';
    $email = $data['email'] ?? '';
    $password = $data['password'] ?? '';
    
    // Validasi input
    if (empty($name) || empty($email) || empty($password)) {
        echo json_encode([
            'status' => 'error',
            'message' => 'All fields are required'
        ]);
        exit;
    }
    
    // Cek apakah email sudah ada
    $stmt = $conn->prepare("SELECT id FROM users WHERE email = ?");
    $stmt->execute([$email]);
    if ($stmt->fetch()) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Email already registered'
        ]);
        exit;
    }
    
    // Hash password
    $passwordHash = password_hash($password, PASSWORD_BCRYPT);
    
    // Generate user ID (contoh: UUID sederhana)
    $userId = uniqid('user_');
    
    // Insert user ke database
    $stmt = $conn->prepare("INSERT INTO users (id, name, email, password) VALUES (?, ?, ?, ?)");
    $stmt->execute([$userId, $name, $email, $passwordHash]);
    
    // Generate token (contoh: simple JWT-like token)
    $token = base64_encode(json_encode([
        'user_id' => $userId,
        'exp' => time() + 86400 // Token expires in 24 hours
    ]));
    
    // Response
    echo json_encode([
        'status' => 'success',
        'data' => [
            'id' => $userId,
            'name' => $name,
            'email' => $email,
            'avatar_url' => null
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