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

    // GET: List members by thread_id or single member
    if ($method == 'GET') {
        if (isset($_GET['thread_id'])) {
            $stmt = $conn->prepare("SELECT tm.*, u.name, u.email, u.avatar_url FROM thread_members tm JOIN users u ON tm.user_id = u.id WHERE tm.thread_id = ?");
            $stmt->execute([$_GET['thread_id']]);
            $members = [];
            while ($m = $stmt->fetch(PDO::FETCH_ASSOC)) {
                $members[] = [
                    'user' => [
                        'id' => $m['user_id'],
                        'name' => $m['name'],
                        'email' => $m['email'],
                        'avatar_url' => $m['avatar_url'],
                    ],
                    'role' => $m['role'],
                    'status' => $m['status'],
                    'custom_role' => $m['custom_role'],
                    'last_active' => $m['last_active'],
                    'role_color' => $m['role_color'],
                ];
            }
            echo json_encode($members);
        } else {
            echo json_encode([]);
        }
        exit;
    }

    // POST: Add new thread member
    if ($method == 'POST') {
        $data = json_decode(file_get_contents('php://input'), true);
        $stmt = $conn->prepare("INSERT INTO thread_members (thread_id, user_id, role, custom_role, status, last_active, role_color) VALUES (?, ?, ?, ?, ?, ?, ?)");
        $stmt->execute([
            $data['thread_id'],
            $data['user_id'],
            $data['role'] ?? 'member',
            $data['custom_role'] ?? null,
            $data['status'] ?? 'offline',
            $data['last_active'],
            $data['role_color'] ?? null
        ]);
        echo json_encode(['status' => 'success']);
        exit;
    }

    // PUT: Update thread member
    if ($method == 'PUT') {
        parse_str(file_get_contents("php://input"), $data);
        $stmt = $conn->prepare("UPDATE thread_members SET role=?, custom_role=?, status=?, last_active=?, role_color=? WHERE thread_id=? AND user_id=?");
        $stmt->execute([
            $data['role'] ?? 'member',
            $data['custom_role'] ?? null,
            $data['status'] ?? 'offline',
            $data['last_active'],
            $data['role_color'] ?? null,
            $data['thread_id'],
            $data['user_id']
        ]);
        echo json_encode(['status' => 'success']);
        exit;
    }

    // DELETE: Remove thread member
    if ($method == 'DELETE') {
        parse_str(file_get_contents("php://input"), $data);
        $stmt = $conn->prepare("DELETE FROM thread_members WHERE thread_id=? AND user_id=?");
        $stmt->execute([$data['thread_id'], $data['user_id']]);
        echo json_encode(['status' => 'success']);
        exit;
    }

    echo json_encode(['status' => 'error', 'message' => 'Invalid request']);
} catch (PDOException $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
?>