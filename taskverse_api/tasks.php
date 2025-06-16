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

    if ($method == 'OPTIONS') {
        exit;
    }

    // GET: List all tasks or get by id
    if ($method == 'GET') {
        if (isset($_GET['id'])) {
            $stmt = $conn->prepare("SELECT * FROM tasks WHERE id = ?");
            $stmt->execute([$_GET['id']]);
            $task = $stmt->fetch(PDO::FETCH_ASSOC);
            echo json_encode($task ?: []);
        } else {
            $stmt = $conn->query("SELECT * FROM tasks");
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        }
        exit;
    }

    // POST: Create new task
    if ($method == 'POST') {
        $data = json_decode(file_get_contents('php://input'), true);

        // Generate a unique ID if none provided
        if (empty($data['id'])) {
            $data['id'] = uniqid('task_');
        }

        $stmt = $conn->prepare("INSERT INTO tasks (id, title, description, due_date, due_time, is_completed, type, priority, streak, last_completed, project_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
        $stmt->execute([
            $data['id'],
            $data['title'],
            $data['description'] ?? null,
            $data['due_date'] ?? null,
            $data['due_time'] ?? null,
            $data['is_completed'] ?? 0,
            $data['type'],
            $data['priority'] ?? null,
            $data['streak'] ?? 0,
            $data['last_completed'] ?? null,
            $data['project_id'] ?? null
        ]);

        // Return the created task data including the generated ID
        echo json_encode([
            'success' => true,
            'data' => $data
        ]);
        exit;
    }

    // PUT: Update task
    if ($method == 'PUT') {
        $data = json_decode(file_get_contents("php://input"), true);
        $stmt = $conn->prepare("UPDATE tasks SET title=?, description=?, due_date=?, due_time=?, is_completed=?, type=?, priority=?, streak=?, last_completed=?, project_id=? WHERE id=?");
        $stmt->execute([
            $data['title'],
            $data['description'] ?? null,
            $data['due_date'] ?? null,
            $data['due_time'] ?? null,
            $data['is_completed'] ?? 0,
            $data['type'],
            $data['priority'] ?? null,
            $data['streak'] ?? 0,
            $data['last_completed'] ?? null,
            $data['project_id'] ?? null,
            $data['id']
        ]);
        echo json_encode(['success' => true]);
        exit;
    }

    // DELETE: Delete task
    if ($method == 'DELETE') {
        $data = json_decode(file_get_contents("php://input"), true);
        $stmt = $conn->prepare("DELETE FROM tasks WHERE id=?");
        $stmt->execute([$data['id']]);
        echo json_encode(['success' => true]);
        exit;
    }

    echo json_encode(['success' => false, 'message' => 'Invalid request']);
} catch (PDOException $e) {
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
?>