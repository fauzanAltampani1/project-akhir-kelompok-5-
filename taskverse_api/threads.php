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

    // GET: List threads or by id
    if ($method == 'GET') {
        if (isset($_GET['id'])) {
            // Get single thread with members
            $stmt = $conn->prepare("SELECT * FROM threads WHERE id = ?");
            $stmt->execute([$_GET['id']]);
            $thread = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($thread) {
                // Get members
                $membersStmt = $conn->prepare("SELECT tm.*, u.name, u.email, u.avatar_url FROM thread_members tm JOIN users u ON tm.user_id = u.id WHERE tm.thread_id = ?");
                $membersStmt->execute([$thread['id']]);
                $members = [];
                while ($m = $membersStmt->fetch(PDO::FETCH_ASSOC)) {
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
                $thread['members'] = $members;
                echo json_encode($thread);
            } else {
                echo json_encode([]);
            }
        } else {
            // List all threads
            $stmt = $conn->query("SELECT * FROM threads");
            $threads = [];
            while ($thread = $stmt->fetch(PDO::FETCH_ASSOC)) {
                // Optionally, you can fetch members for each thread here if needed
                $threads[] = $thread;
            }
            echo json_encode($threads);
        }
        exit;
    }

    // POST: Create new thread
    if ($method == 'POST') {
        $data = json_decode(file_get_contents('php://input'), true);

        $stmt = $conn->prepare("INSERT INTO threads (id, name, type, parent_thread_id, project_id, description, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
        $stmt->execute([
            $data['id'],
            $data['name'],
            $data['type'],
            $data['parent_thread_id'] ?? null,
            $data['project_id'] ?? null,
            $data['description'] ?? null,
            $data['created_at'],
            $data['updated_at']
        ]);

        // Insert members
        if (!empty($data['members'])) {
            foreach ($data['members'] as $member) {
                $memStmt = $conn->prepare("INSERT INTO thread_members (thread_id, user_id, role, custom_role, status, last_active, role_color) VALUES (?, ?, ?, ?, ?, ?, ?)");
                $memStmt->execute([
                    $data['id'],
                    $member['user']['id'],
                    $member['role'],
                    $member['custom_role'] ?? null,
                    $member['status'] ?? 'offline',
                    $member['last_active'],
                    $member['role_color'] ?? null
                ]);
            }
        }

        echo json_encode(['status' => 'success']);
        exit;
    }

    // PUT: Update thread (not members)
    if ($method == 'PUT') {
        parse_str(file_get_contents("php://input"), $data);
        $stmt = $conn->prepare("UPDATE threads SET name=?, type=?, parent_thread_id=?, project_id=?, description=?, updated_at=? WHERE id=?");
        $stmt->execute([
            $data['name'],
            $data['type'],
            $data['parent_thread_id'] ?? null,
            $data['project_id'] ?? null,
            $data['description'] ?? null,
            $data['updated_at'],
            $data['id']
        ]);
        echo json_encode(['status' => 'success']);
        exit;
    }

    // DELETE: Delete thread and its members
    if ($method == 'DELETE') {
        parse_str(file_get_contents("php://input"), $data);
        $conn->prepare("DELETE FROM thread_members WHERE thread_id=?")->execute([$data['id']]);
        $conn->prepare("DELETE FROM threads WHERE id=?")->execute([$data['id']]);
        echo json_encode(['status' => 'success']);
        exit;
    }

    echo json_encode(['status' => 'error', 'message' => 'Invalid request']);
} catch (PDOException $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
?>