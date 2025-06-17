<?php
/**
 * Project Tasks API Endpoint
 * 
 * Handles CRUD operations for tasks within projects, including:
 * - List all tasks in a project
 * - Get single task details
 * - Create new tasks
 * - Update existing tasks
 * - Delete tasks
 * - Manage task assignments
 * 
 * @version 1.0.0
 * @author TaskVerse Team
 */

require_once __DIR__ . '/includes/config.php';
require_once __DIR__ . '/includes/utils.php';

// Set response headers
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, X-Requested-With');
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');
header('X-XSS-Protection: 1; mode=block');

session_start();

// Check rate limit
if (!checkRateLimit()) {
    return sendError('Rate limit exceeded', 429);
}

try {
    $conn = connectDB();
    if (!$conn) {
        return sendError('Database connection failed', 500);
    }

    $method = $_SERVER['REQUEST_METHOD'];
    $path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
    $pathParts = explode('/', trim($path, '/'));
    if ($method == 'OPTIONS') {
        return;
    }    // Extract project ID from URL
    $projectId = isset($pathParts[1]) ? $pathParts[1] : null;
    if (!$projectId) {
        logError('Missing project ID', ['uri' => $_SERVER['REQUEST_URI']]);
        return sendError('Project ID is required');
    }

    // Verify project exists
    $projectStmt = $conn->prepare("SELECT * FROM projects WHERE id = ?");
    $projectStmt->execute([$projectId]);
    $project = $projectStmt->fetch(PDO::FETCH_ASSOC);
    if (!$project) {
        return sendError('Project not found', 404);
    }

    // GET: List all tasks for a project or get a specific task
    if ($method == 'GET') {
        $taskId = isset($pathParts[3]) ? $pathParts[3] : null;

        if ($taskId) {
            // Get single task
            $stmt = $conn->prepare(
                "SELECT pt.*, 
                GROUP_CONCAT(DISTINCT ptm.user_id) as assignee_ids,
                GROUP_CONCAT(DISTINCT CONCAT(u.id, ':', u.name, ':', u.email, ':', COALESCE(u.avatar, ''))) as assignee_details
                FROM project_tasks pt
                LEFT JOIN project_task_members ptm ON pt.id = ptm.task_id
                LEFT JOIN users u ON ptm.user_id = u.id
                WHERE pt.id = ? AND pt.project_id = ?
                GROUP BY pt.id"
            );
            $stmt->execute([$taskId, $projectId]);
            $task = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($task) {
                // Format assignees
                $assigneeIds = $task['assignee_ids'] ? explode(',', $task['assignee_ids']) : [];
                $assigneeDetails = [];
                if ($task['assignee_details']) {
                    foreach (explode(',', $task['assignee_details']) as $detail) {
                        list($id, $name, $email, $avatar) = explode(':', $detail);
                        $assigneeDetails[] = [
                            'id' => $id,
                            'name' => $name,
                            'email' => $email,
                            'avatar' => $avatar ?: null
                        ];
                    }
                }
                unset($task['assignee_details']);
                $task['assignee_ids'] = $assigneeIds;
                $task['assignees'] = $assigneeDetails;
                sendResponse($task);
            }
            sendError('Task not found', 404);
        }

        // List all tasks for project
        $stmt = $conn->prepare(
            "SELECT pt.*, 
            GROUP_CONCAT(DISTINCT ptm.user_id) as assignee_ids,
            GROUP_CONCAT(DISTINCT CONCAT(u.id, ':', u.name, ':', u.email, ':', COALESCE(u.avatar, ''))) as assignee_details
            FROM project_tasks pt
            LEFT JOIN project_task_members ptm ON pt.id = ptm.task_id
            LEFT JOIN users u ON ptm.user_id = u.id
            WHERE pt.project_id = ?
            GROUP BY pt.id"
        );
        $stmt->execute([$projectId]);
        $tasks = [];

        while ($task = $stmt->fetch(PDO::FETCH_ASSOC)) {
            // Format assignees
            $assigneeIds = $task['assignee_ids'] ? explode(',', $task['assignee_ids']) : [];
            $assigneeDetails = [];
            if ($task['assignee_details']) {
                foreach (explode(',', $task['assignee_details']) as $detail) {
                    list($id, $name, $email, $avatar) = explode(':', $detail);
                    $assigneeDetails[] = [
                        'id' => $id,
                        'name' => $name,
                        'email' => $email,
                        'avatar' => $avatar ?: null
                    ];
                }
            }
            unset($task['assignee_details']);
            $task['assignee_ids'] = $assigneeIds;
            $task['assignees'] = $assigneeDetails;
            $tasks[] = $task;
        }
        sendResponse($tasks);
    }    // POST: Create new task
    if ($method == 'POST') {
        $data = json_decode(file_get_contents('php://input'), true);

        // Validate input
        $rules = [
            'title' => 'required|string',
            'description' => 'string',
            'due_date' => 'string',
            'is_completed' => 'boolean',
            'assignee_ids' => 'array'
        ];

        $validation = validateInput($data, $rules);
        if (!empty($validation['errors'])) {
            return sendError('Validation failed: ' . implode(', ', $validation['errors']));
        }

        $data = $validation['data'];

        // Additional validation for date format
        if (isset($data['due_date']) && !empty($data['due_date'])) {
            $date = date_parse($data['due_date']);
            if ($date['error_count'] > 0) {
                return sendError('Invalid due date format. Use YYYY-MM-DD');
            }
        }

        $conn->beginTransaction();
        try {
            // Create task
            $stmt = $conn->prepare(
                "INSERT INTO project_tasks (project_id, title, description, due_date, is_completed, created_at, updated_at) 
                VALUES (?, ?, ?, ?, ?, ?, ?)"
            );
            $stmt->execute([
                $projectId,
                $data['title'],
                $data['description'] ?? null,
                $data['due_date'] ?? null,
                $data['is_completed'] ?? false,
                date('Y-m-d H:i:s'),
                date('Y-m-d H:i:s')
            ]);

            $taskId = $conn->lastInsertId();

            // Add assignees if provided
            if (!empty($data['assignee_ids'])) {
                $assignStmt = $conn->prepare(
                    "INSERT INTO project_task_members (task_id, user_id, assigned_at) 
                    VALUES (?, ?, ?)"
                );
                foreach ($data['assignee_ids'] as $userId) {
                    $assignStmt->execute([
                        $taskId,
                        $userId,
                        date('Y-m-d H:i:s')
                    ]);
                }
            }

            // Update project task count
            $conn->prepare(
                "UPDATE projects 
                SET task_count = task_count + 1, 
                    updated_at = ? 
                WHERE id = ?"
            )->execute([date('Y-m-d H:i:s'), $projectId]);

            $conn->commit();

            // Return created task
            $stmt = $conn->prepare(
                "SELECT pt.*, 
                GROUP_CONCAT(DISTINCT ptm.user_id) as assignee_ids,
                GROUP_CONCAT(DISTINCT CONCAT(u.id, ':', u.name, ':', u.email, ':', COALESCE(u.avatar, ''))) as assignee_details
                FROM project_tasks pt
                LEFT JOIN project_task_members ptm ON pt.id = ptm.task_id
                LEFT JOIN users u ON ptm.user_id = u.id
                WHERE pt.id = ?
                GROUP BY pt.id"
            );
            $stmt->execute([$taskId]);
            $task = $stmt->fetch(PDO::FETCH_ASSOC);

            // Format assignees
            $assigneeIds = $task['assignee_ids'] ? explode(',', $task['assignee_ids']) : [];
            $assigneeDetails = [];
            if ($task['assignee_details']) {
                foreach (explode(',', $task['assignee_details']) as $detail) {
                    list($id, $name, $email, $avatar) = explode(':', $detail);
                    $assigneeDetails[] = [
                        'id' => $id,
                        'name' => $name,
                        'email' => $email,
                        'avatar' => $avatar ?: null
                    ];
                }
            }
            unset($task['assignee_details']);
            $task['assignee_ids'] = $assigneeIds;
            $task['assignees'] = $assigneeDetails;

            sendResponse($task);
        } catch (Exception $e) {
            $conn->rollBack();
            throw $e;
        }
    }

    // PUT: Update task
    if ($method == 'PUT') {
        $taskId = isset($pathParts[3]) ? $pathParts[3] : null;
        if (!$taskId) {
            sendError('Task ID is required');
        }

        $data = json_decode(file_get_contents('php://input'), true);

        // Verify task exists and belongs to project
        $stmt = $conn->prepare("SELECT * FROM project_tasks WHERE id = ? AND project_id = ?");
        $stmt->execute([$taskId, $projectId]);
        if (!$stmt->fetch()) {
            sendError('Task not found or does not belong to the project', 404);
        }

        $conn->beginTransaction();
        try {
            // Update task basic info
            $updates = [];
            $params = [];

            if (isset($data['title'])) {
                $updates[] = "title = ?";
                $params[] = $data['title'];
            }
            if (isset($data['description'])) {
                $updates[] = "description = ?";
                $params[] = $data['description'];
            }
            if (isset($data['due_date'])) {
                $updates[] = "due_date = ?";
                $params[] = $data['due_date'];
            }
            if (isset($data['is_completed'])) {
                $updates[] = "is_completed = ?";
                $params[] = $data['is_completed'];
            }

            if (!empty($updates)) {
                $updates[] = "updated_at = ?";
                $params[] = date('Y-m-d H:i:s');
                $params[] = $taskId;
                $params[] = $projectId;

                $stmt = $conn->prepare(
                    "UPDATE project_tasks 
                    SET " . implode(", ", $updates) . "
                    WHERE id = ? AND project_id = ?"
                );
                $stmt->execute($params);
            }

            // Update assignees if provided
            if (isset($data['assignee_ids'])) {
                // Remove existing assignments
                $conn->prepare(
                    "DELETE FROM project_task_members WHERE task_id = ?"
                )->execute([$taskId]);

                // Add new assignments
                if (!empty($data['assignee_ids'])) {
                    $assignStmt = $conn->prepare(
                        "INSERT INTO project_task_members (task_id, user_id, assigned_at) 
                        VALUES (?, ?, ?)"
                    );
                    foreach ($data['assignee_ids'] as $userId) {
                        $assignStmt->execute([
                            $taskId,
                            $userId,
                            date('Y-m-d H:i:s')
                        ]);
                    }
                }
            }

            $conn->commit();

            // Return updated task
            $stmt = $conn->prepare(
                "SELECT pt.*, 
                GROUP_CONCAT(DISTINCT ptm.user_id) as assignee_ids,
                GROUP_CONCAT(DISTINCT CONCAT(u.id, ':', u.name, ':', u.email, ':', COALESCE(u.avatar, ''))) as assignee_details
                FROM project_tasks pt
                LEFT JOIN project_task_members ptm ON pt.id = ptm.task_id
                LEFT JOIN users u ON ptm.user_id = u.id
                WHERE pt.id = ?
                GROUP BY pt.id"
            );
            $stmt->execute([$taskId]);
            $task = $stmt->fetch(PDO::FETCH_ASSOC);

            // Format assignees
            $assigneeIds = $task['assignee_ids'] ? explode(',', $task['assignee_ids']) : [];
            $assigneeDetails = [];
            if ($task['assignee_details']) {
                foreach (explode(',', $task['assignee_details']) as $detail) {
                    list($id, $name, $email, $avatar) = explode(':', $detail);
                    $assigneeDetails[] = [
                        'id' => $id,
                        'name' => $name,
                        'email' => $email,
                        'avatar' => $avatar ?: null
                    ];
                }
            }
            unset($task['assignee_details']);
            $task['assignee_ids'] = $assigneeIds;
            $task['assignees'] = $assigneeDetails;

            sendResponse($task);
        } catch (Exception $e) {
            $conn->rollBack();
            throw $e;
        }
    }

    // DELETE: Delete task
    if ($method == 'DELETE') {
        $taskId = isset($pathParts[3]) ? $pathParts[3] : null;
        if (!$taskId) {
            sendError('Task ID is required');
        }

        // Verify task exists and belongs to project
        $stmt = $conn->prepare("SELECT * FROM project_tasks WHERE id = ? AND project_id = ?");
        $stmt->execute([$taskId, $projectId]);
        if (!$stmt->fetch()) {
            sendError('Task not found or does not belong to the project', 404);
        }

        $conn->beginTransaction();
        try {
            // Remove task members
            $conn->prepare(
                "DELETE FROM project_task_members WHERE task_id = ?"
            )->execute([$taskId]);

            // Delete task
            $conn->prepare(
                "DELETE FROM project_tasks WHERE id = ? AND project_id = ?"
            )->execute([$taskId, $projectId]);

            // Update project task count
            $conn->prepare(
                "UPDATE projects 
                SET task_count = GREATEST(task_count - 1, 0),
                    updated_at = ? 
                WHERE id = ?"
            )->execute([date('Y-m-d H:i:s'), $projectId]);

            $conn->commit();
            sendResponse(['message' => 'Task deleted successfully']);
        } catch (Exception $e) {
            $conn->rollBack();
            throw $e;
        }
    }

    sendError('Invalid request method', 405);
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
} catch (Exception $e) {
    sendError('Server error: ' . $e->getMessage(), 500);
}
?>