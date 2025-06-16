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

    // GET: List all tasks or by id/project_id
    if ($method == 'GET') {
        if (isset($_GET['id'])) {
            $stmt = $conn->prepare("SELECT * FROM project_tasks WHERE id = ?");
            $stmt->execute([$_GET['id']]);
            $task = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($task) {
                // Get assignees
                $assigneesStmt = $conn->prepare("SELECT user_id FROM project_task_assignees WHERE task_id = ?");
                $assigneesStmt->execute([$task['id']]);
                $task['assignee_ids'] = $assigneesStmt->fetchAll(PDO::FETCH_COLUMN);
                echo json_encode($task);
            } else {
                echo json_encode([]);
            }
        } else if (isset($_GET['project_id'])) {
            $stmt = $conn->prepare("SELECT * FROM project_tasks WHERE project_id = ?");
            $stmt->execute([$_GET['project_id']]);
            $tasks = [];
            while ($task = $stmt->fetch(PDO::FETCH_ASSOC)) {
                $assigneesStmt = $conn->prepare("SELECT user_id FROM project_task_assignees WHERE task_id = ?");
                $assigneesStmt->execute([$task['id']]);
                $task['assignee_ids'] = $assigneesStmt->fetchAll(PDO::FETCH_COLUMN);
                $tasks[] = $task;
            }
            echo json_encode($tasks);
        } else {
            $stmt = $conn->query("SELECT * FROM project_tasks");
            $tasks = [];
            while ($task = $stmt->fetch(PDO::FETCH_ASSOC)) {
                $assigneesStmt = $conn->prepare("SELECT user_id FROM project_task_assignees WHERE task_id = ?");
                $assigneesStmt->execute([$task['id']]);
                $task['assignee_ids'] = $assigneesStmt->fetchAll(PDO::FETCH_COLUMN);
                $tasks[] = $task;
            }
            echo json_encode($tasks);
        }
        exit;
    }

    // POST: Create new task
    if ($method == 'POST') {
        $data = json_decode(file_get_contents('php://input'), true);

        $stmt = $conn->prepare("INSERT INTO project_tasks (id, title, description, due_date, project_id, is_completed, assigner_id) VALUES (?, ?, ?, ?, ?, ?, ?)");
        $stmt->execute([
            $data['id'],
            $data['title'],
            $data['description'] ?? null,
            $data['due_date'],
            $data['project_id'],
            $data['is_completed'] ?? 0,
            $data['assigner_id']
        ]);

        // Insert assignees
        if (!empty($data['assignee_ids'])) {
            foreach ($data['assignee_ids'] as $userId) {
                $assigneeStmt = $conn->prepare("INSERT INTO project_task_assignees (task_id, user_id) VALUES (?, ?)");
                $assigneeStmt->execute([$data['id'], $userId]);
            }
        }

        echo json_encode(['status' => 'success']);
        exit;
    }

    // PUT: Update task
    if ($method == 'PUT') {
        parse_str(file_get_contents("php://input"), $data);

        $stmt = $conn->prepare("UPDATE project_tasks SET title=?, description=?, due_date=?, project_id=?, is_completed=?, assigner_id=? WHERE id=?");
        $stmt->execute([
            $data['title'],
            $data['description'] ?? null,
            $data['due_date'],
            $data['project_id'],
            $data['is_completed'] ?? 0,
            $data['assigner_id'],
            $data['id']
        ]);

        // Update assignees: remove all then add new
        $conn->prepare("DELETE FROM project_task_assignees WHERE task_id=?")->execute([$data['id']]);
        if (!empty($data['assignee_ids'])) {
            foreach ($data['assignee_ids'] as $userId) {
                $assigneeStmt = $conn->prepare("INSERT INTO project_task_assignees (task_id, user_id) VALUES (?, ?)");
                $assigneeStmt->execute([$data['id'], $userId]);
            }
        }

        echo json_encode(['status' => 'success']);
        exit;
    }

    // DELETE: Delete task and its assignees
    if ($method == 'DELETE') {
        parse_str(file_get_contents("php://input"), $data);
        $conn->prepare("DELETE FROM project_task_assignees WHERE task_id=?")->execute([$data['id']]);
        $conn->prepare("DELETE FROM project_tasks WHERE id=?")->execute([$data['id']]);
        echo json_encode(['status' => 'success']);
        exit;
    }

    echo json_encode(['status' => 'error', 'message' => 'Invalid request']);
} catch (PDOException $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
?>