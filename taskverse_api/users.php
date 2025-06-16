<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

$servername = "localhost";
$username = "root";
$password = "";
$dbname = "taskverse_db";

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $method = $_SERVER['REQUEST_METHOD'];
    if ($method == 'OPTIONS') { exit; }

    // GET: List all users or get by id
    if ($method == 'GET') {
        if (isset($_GET['id'])) {
            $stmt = $conn->prepare("SELECT id, name, email, avatar_url FROM users WHERE id = ?");
            $stmt->execute([$_GET['id']]);
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            echo json_encode($user ?: []);
        } else {
            $stmt = $conn->query("SELECT id, name, email, avatar_url FROM users");
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        }
        exit;
    }

    // POST: Create new user (password required)
    if ($method == 'POST') {
        $data = json_decode(file_get_contents('php://input'), true);
        $stmt = $conn->prepare("INSERT INTO users (id, name, email, password, avatar_url) VALUES (?, ?, ?, ?, ?)");
        $stmt->execute([
            $data['id'],
            $data['name'],
            $data['email'],
            password_hash($data['password'], PASSWORD_DEFAULT),
            $data['avatar_url'] ?? null
        ]);
        echo json_encode(['status' => 'success']);
        exit;
    }

    // PUT: Update user (except password)
    if ($method == 'PUT') {
        parse_str(file_get_contents("php://input"), $data);
        $stmt = $conn->prepare("UPDATE users SET name=?, email=?, avatar_url=? WHERE id=?");
        $stmt->execute([
            $data['name'],
            $data['email'],
            $data['avatar_url'] ?? null,
            $data['id']
        ]);
        echo json_encode(['status' => 'success']);
        exit;
    }

    // DELETE: Delete user
    if ($method == 'DELETE') {
        parse_str(file_get_contents("php://input"), $data);
        $stmt = $conn->prepare("DELETE FROM users WHERE id=?");
        $stmt->execute([$data['id']]);
        echo json_encode(['status' => 'success']);
        exit;
    }

    echo json_encode(['status' => 'error', 'message' => 'Invalid request']);
} catch (PDOException $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
?>