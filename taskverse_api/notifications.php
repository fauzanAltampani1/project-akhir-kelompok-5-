<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, PUT, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

$servername = "localhost";
$username = "root";
$password = "";
$dbname = "taskverse_db";

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $method = $_SERVER['REQUEST_METHOD'];
    if ($method == 'OPTIONS') {
        exit;
    }

    // GET: Get notifications for a user
    if ($method == 'GET') {
        if (!isset($_GET['user_id'])) {
            echo json_encode(['status' => 'error', 'message' => 'User ID is required']);
            exit;
        }

        $userId = $_GET['user_id'];
        $readStatus = isset($_GET['unread_only']) ? 'AND is_read = 0' : '';

        $stmt = $conn->prepare("
            SELECT n.*, t.name as thread_name, u.name as sender_name, u.email as sender_email
            FROM notifications n
            JOIN threads t ON n.thread_id = t.id
            JOIN users u ON n.sender_id = u.id
            WHERE n.user_id = ?
            $readStatus
            ORDER BY n.created_at DESC
        ");
        $stmt->execute([$userId]);
        echo json_encode(['status' => 'success', 'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
        exit;
    }

    // PUT: Mark notification as read
    if ($method == 'PUT') {
        $data = json_decode(file_get_contents('php://input'), true);
        if (!isset($data['notification_id'])) {
            echo json_encode(['status' => 'error', 'message' => 'Notification ID is required']);
            exit;
        }

        $stmt = $conn->prepare("UPDATE notifications SET is_read = 1 WHERE id = ?");
        $stmt->execute([$data['notification_id']]);
        echo json_encode(['status' => 'success']);
        exit;
    }

    echo json_encode(['status' => 'error', 'message' => 'Invalid request']);
} catch (PDOException $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
?>