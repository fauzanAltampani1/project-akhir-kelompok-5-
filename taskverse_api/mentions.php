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

    // GET: List all mentions or by message_id
    if ($method == 'GET') {
        if (isset($_GET['message_id'])) {
            $stmt = $conn->prepare("SELECT * FROM mentions WHERE message_id = ?");
            $stmt->execute([$_GET['message_id']]);
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        } else {
            $stmt = $conn->query("SELECT * FROM mentions");
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        }
        exit;
    }

    // POST: Create new mention
    if ($method == 'POST') {
        $data = json_decode(file_get_contents('php://input'), true);
        $stmt = $conn->prepare("INSERT INTO mentions (message_id, mention_text, user_id) VALUES (?, ?, ?)");
        $stmt->execute([
            $data['message_id'],
            $data['mention_text'],
            $data['user_id'] ?? null
        ]);
        echo json_encode(['status' => 'success']);
        exit;
    }

    // PUT: Update mention (by id)
    if ($method == 'PUT') {
        parse_str(file_get_contents("php://input"), $data);
        $stmt = $conn->prepare("UPDATE mentions SET message_id=?, mention_text=?, user_id=? WHERE id=?");
        $stmt->execute([
            $data['message_id'],
            $data['mention_text'],
            $data['user_id'] ?? null,
            $data['id']
        ]);
        echo json_encode(['status' => 'success']);
        exit;
    }

    // DELETE: Delete mention (by id)
    if ($method == 'DELETE') {
        parse_str(file_get_contents("php://input"), $data);
        $stmt = $conn->prepare("DELETE FROM mentions WHERE id=?");
        $stmt->execute([$data['id']]);
        echo json_encode(['status' => 'success']);
        exit;
    }

    echo json_encode(['status' => 'error', 'message' => 'Invalid request']);
} catch (PDOException $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
?>