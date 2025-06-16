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

    // GET: List all projects or by id
    if ($method == 'GET') {
        if (isset($_GET['id'])) {
            // Get single project with members and creator
            $stmt = $conn->prepare("SELECT * FROM projects WHERE id = ?");
            $stmt->execute([$_GET['id']]);
            $project = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($project) {
                // Get creator
                $creatorStmt = $conn->prepare("SELECT * FROM users WHERE id = ?");
                $creatorStmt->execute([$project['creator_id']]);
                $project['creator'] = $creatorStmt->fetch(PDO::FETCH_ASSOC);

                // Get members
                $membersStmt = $conn->prepare("SELECT pm.*, u.name, u.email FROM project_members pm JOIN users u ON pm.user_id = u.id WHERE pm.project_id = ?");
                $membersStmt->execute([$project['id']]);
                $members = [];
                while ($m = $membersStmt->fetch(PDO::FETCH_ASSOC)) {
                    $members[] = [
                        'user_id' => $m['user_id'],
                        'user' => [
                            'id' => $m['user_id'],
                            'name' => $m['name'],
                            'email' => $m['email'],
                        ],
                        'role' => $m['role'],
                        'joined_at' => $m['joined_at'],
                    ];
                }
                $project['members'] = $members;
                echo json_encode($project);
            } else {
                echo json_encode([]);
            }
        } else {
            // List all projects
            $stmt = $conn->query("SELECT * FROM projects");
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        }
        exit;
    }

    // POST: Create new project
    if ($method == 'POST') {
        $data = json_decode(file_get_contents('php://input'), true);

        $stmt = $conn->prepare("INSERT INTO projects (id, name, description, creator_id, task_count, thread_count, status, created_at, updated_at, thread_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
        $stmt->execute([
            $data['id'],
            $data['name'],
            $data['description'] ?? null,
            $data['creator_id'],
            $data['task_count'] ?? 0,
            $data['thread_count'] ?? 0,
            $data['status'] ?? 'active',
            $data['created_at'],
            $data['updated_at'],
            $data['thread_id'] ?? null
        ]);

        // Insert members
        if (!empty($data['members'])) {
            foreach ($data['members'] as $member) {
                $memStmt = $conn->prepare("INSERT INTO project_members (project_id, user_id, role, joined_at) VALUES (?, ?, ?, ?)");
                $memStmt->execute([
                    $data['id'],
                    $member['user_id'],
                    $member['role'],
                    $member['joined_at']
                ]);
            }
        }

        echo json_encode(['status' => 'success']);
        exit;
    }

    // PUT: Update project (not members)
    if ($method == 'PUT') {
        parse_str(file_get_contents("php://input"), $data);
        $stmt = $conn->prepare("UPDATE projects SET name=?, description=?, task_count=?, thread_count=?, status=?, updated_at=?, thread_id=? WHERE id=?");
        $stmt->execute([
            $data['name'],
            $data['description'] ?? null,
            $data['task_count'] ?? 0,
            $data['thread_count'] ?? 0,
            $data['status'] ?? 'active',
            $data['updated_at'],
            $data['thread_id'] ?? null,
            $data['id']
        ]);
        echo json_encode(['status' => 'success']);
        exit;
    }

    // DELETE: Delete project and its members
    if ($method == 'DELETE') {
        parse_str(file_get_contents("php://input"), $data);
        $conn->prepare("DELETE FROM project_members WHERE project_id=?")->execute([$data['id']]);
        $conn->prepare("DELETE FROM projects WHERE id=?")->execute([$data['id']]);
        echo json_encode(['status' => 'success']);
        exit;
    }

    echo json_encode(['status' => 'error', 'message' => 'Invalid request']);
} catch (PDOException $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
?>