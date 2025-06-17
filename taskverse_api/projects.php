<?php
/**
 * Projects API Endpoint
 * 
 * Handles CRUD operations for projects and project members
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
    }

    // Member management endpoints
    if (count($pathParts) > 1 && $pathParts[1] == 'members') {
        $projectId = $pathParts[0];

        // POST: Add member
        if ($method == 'POST') {
            $data = json_decode(file_get_contents('php://input'), true);
            if (!isset($data['user_id']) || !isset($data['role'])) {
                sendError('Missing required fields');
            }

            $stmt = $conn->prepare("INSERT INTO project_members (project_id, user_id, role, joined_at) VALUES (?, ?, ?, ?)");
            $stmt->execute([
                $projectId,
                $data['user_id'],
                $data['role'],
                $data['joined_at']
            ]);
            sendResponse(['message' => 'Member added successfully']);
        }

        // DELETE: Remove member
        if ($method == 'DELETE') {
            $data = json_decode(file_get_contents('php://input'), true);
            if (!isset($data['user_id'])) {
                sendError('Missing user_id');
            }

            $stmt = $conn->prepare("DELETE FROM project_members WHERE project_id = ? AND user_id = ?");
            $stmt->execute([$projectId, $data['user_id']]);
            sendResponse(['message' => 'Member removed successfully']);
        }

        // PUT: Update member role
        if ($method == 'PUT') {
            $data = json_decode(file_get_contents('php://input'), true);
            if (!isset($data['user_id']) || !isset($data['role'])) {
                sendError('Missing required fields');
            }

            $stmt = $conn->prepare("UPDATE project_members SET role = ? WHERE project_id = ? AND user_id = ?");
            $stmt->execute([$data['role'], $projectId, $data['user_id']]);
            sendResponse(['message' => 'Member role updated successfully']);
        }
    }

    // Regular project endpoints
    // GET: List all projects or by id
    if ($method == 'GET') {
        if (isset($_GET['id'])) {
            $stmt = $conn->prepare("SELECT * FROM projects WHERE id = ?");
            $stmt->execute([$_GET['id']]);
            $project = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($project) {
                // Get creator
                $creatorStmt = $conn->prepare("SELECT * FROM users WHERE id = ?");
                $creatorStmt->execute([$project['creator_id']]);
                $project['creator'] = $creatorStmt->fetch(PDO::FETCH_ASSOC);

                // Get members
                $membersStmt = $conn->prepare(
                    "SELECT pm.*, u.name, u.email, u.avatar 
                    FROM project_members pm 
                    JOIN users u ON pm.user_id = u.id 
                    WHERE pm.project_id = ?"
                );
                $membersStmt->execute([$project['id']]);
                $members = [];
                while ($m = $membersStmt->fetch(PDO::FETCH_ASSOC)) {
                    $members[] = [
                        'user_id' => $m['user_id'],
                        'user' => [
                            'id' => $m['user_id'],
                            'name' => $m['name'],
                            'email' => $m['email'],
                            'avatar' => $m['avatar'],
                        ],
                        'role' => $m['role'],
                        'joined_at' => $m['joined_at'],
                    ];
                }
                $project['members'] = $members;
                sendResponse($project);
            }
            sendResponse(null);
        }

        // List all projects
        $stmt = $conn->prepare(
            "SELECT p.*, u.name as creator_name, u.email as creator_email, u.avatar as creator_avatar 
            FROM projects p 
            JOIN users u ON p.creator_id = u.id"
        );
        $stmt->execute();
        $projects = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Get members for each project
        foreach ($projects as &$project) {
            $membersStmt = $conn->prepare(
                "SELECT pm.*, u.name, u.email, u.avatar 
                FROM project_members pm 
                JOIN users u ON pm.user_id = u.id 
                WHERE pm.project_id = ?"
            );
            $membersStmt->execute([$project['id']]);
            $project['members'] = [];
            while ($m = $membersStmt->fetch(PDO::FETCH_ASSOC)) {
                $project['members'][] = [
                    'user_id' => $m['user_id'],
                    'user' => [
                        'id' => $m['user_id'],
                        'name' => $m['name'],
                        'email' => $m['email'],
                        'avatar' => $m['avatar'],
                    ],
                    'role' => $m['role'],
                    'joined_at' => $m['joined_at'],
                ];
            }
        }
        sendResponse($projects);
    }    // POST: Create new project
    if ($method == 'POST') {
        $data = json_decode(file_get_contents('php://input'), true);

        // Validate input
        $rules = [
            'name' => 'required|string',
            'creator_id' => 'required|int',
            'description' => 'string',
            'status' => 'string'
        ];

        $validation = validateInput($data, $rules);
        if (!empty($validation['errors'])) {
            return sendError('Validation failed: ' . implode(', ', $validation['errors']));
        }

        $data = $validation['data'];

        $stmt = $conn->prepare(
            "INSERT INTO projects (name, description, creator_id, task_count, thread_count, status, created_at, updated_at) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)"
        );
        $stmt->execute([
            $data['name'],
            $data['description'] ?? null,
            $data['creator_id'],
            $data['task_count'] ?? 0,
            $data['thread_count'] ?? 0,
            $data['status'] ?? 'active',
            $data['created_at'],
            $data['updated_at']
        ]);

        $projectId = $conn->lastInsertId();

        // Insert creator as admin member
        $stmt = $conn->prepare("INSERT INTO project_members (project_id, user_id, role, joined_at) VALUES (?, ?, ?, ?)");
        $stmt->execute([
            $projectId,
            $data['creator_id'],
            'admin',
            $data['created_at']
        ]);

        // Insert other members if provided
        if (!empty($data['member_ids'])) {
            foreach ($data['member_ids'] as $memberId) {
                $role = $data['member_roles'][$memberId] ?? 'member';
                $stmt->execute([
                    $projectId,
                    $memberId,
                    $role,
                    $data['created_at']
                ]);
            }
        }

        sendResponse(['message' => 'Project created successfully', 'project_id' => $projectId]);
    }

    // PUT: Update project
    if ($method == 'PUT') {
        $data = json_decode(file_get_contents('php://input'), true);
        if (!isset($data['id'])) {
            sendError('Missing project ID');
        }

        $stmt = $conn->prepare(
            "UPDATE projects 
            SET name = ?, description = ?, task_count = ?, thread_count = ?, 
                status = ?, updated_at = ? 
            WHERE id = ?"
        );
        $stmt->execute([
            $data['name'],
            $data['description'] ?? null,
            $data['task_count'] ?? 0,
            $data['thread_count'] ?? 0,
            $data['status'] ?? 'active',
            $data['updated_at'],
            $data['id']
        ]);
        sendResponse(['message' => 'Project updated successfully']);
    }

    // DELETE: Delete project and its members
    if ($method == 'DELETE') {
        $data = json_decode(file_get_contents('php://input'), true);
        if (!isset($data['id'])) {
            sendError('Missing project ID');
        }

        $conn->beginTransaction();
        try {
            $conn->prepare("DELETE FROM project_members WHERE project_id = ?")->execute([$data['id']]);
            $conn->prepare("DELETE FROM projects WHERE id = ?")->execute([$data['id']]);
            $conn->commit();
            sendResponse(['message' => 'Project deleted successfully']);
        } catch (Exception $e) {
            $conn->rollBack();
            throw $e;
        }
    }

    return sendError('Invalid request', 404);
} catch (PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
} catch (Exception $e) {
    sendError('Server error: ' . $e->getMessage(), 500);
}
?>