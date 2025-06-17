<?php
/**
 * Projects API Endpoint
 *
 * Handles CRUD operations for projects and project members including:
 * - Create, read, update, delete projects
 * - Manage project members (add, remove, change roles)
 * - List projects with member information
 * 
 * @version 1.1.0
 * @author TaskVerse Team
 */

// Prevent any output before JSON response
error_reporting(E_ERROR | E_PARSE); // Only show fatal errors
ini_set('display_errors', 0); // Don't display errors in output
ob_start(); // Start output buffering

require_once __DIR__ . '/includes/config.php';
require_once __DIR__ . '/includes/utils.php';

// Clean any output that might have been generated
if (ob_get_length()) {
    ob_clean();
}

// Set response headers for JSON API
header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, X-Requested-With, Authorization');
header('Access-Control-Max-Age: 86400'); // 1 day for preflight cache
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');
header('X-XSS-Protection: 1; mode=block');
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');

// Start session for rate limiting
session_start();

// Handle preflight OPTIONS requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit(0);
}

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
    }    // Member management endpoints
    if (count($pathParts) > 1 && $pathParts[1] == 'members') {
        $projectId = filter_var($pathParts[0], FILTER_VALIDATE_INT);
        if (!$projectId) {
            return sendError('Invalid project ID format', 400);
        }

        // Check if project exists
        $checkStmt = $conn->prepare("SELECT id FROM projects WHERE id = ?");
        $checkStmt->execute([$projectId]);
        if (!$checkStmt->fetch()) {
            return sendError('Project not found', 404);
        }

        // POST: Add member
        if ($method == 'POST') {
            $rawData = file_get_contents('php://input');
            if (empty($rawData)) {
                return sendError('No data provided', 400);
            }

            $data = json_decode($rawData, true);
            if (json_last_error() !== JSON_ERROR_NONE) {
                return sendError('Invalid JSON: ' . json_last_error_msg(), 400);
            }

            if (!isset($data['user_id']) || !isset($data['role'])) {
                return sendError('Missing required fields: user_id and role', 400);
            }

            $userId = filter_var($data['user_id'], FILTER_VALIDATE_INT);
            if (!$userId) {
                return sendError('Invalid user ID format', 400);
            }

            // Validate user exists
            $userCheck = $conn->prepare("SELECT id FROM users WHERE id = ?");
            $userCheck->execute([$userId]);
            if (!$userCheck->fetch()) {
                return sendError('User not found', 404);
            }

            // Check if already a member
            $memberCheck = $conn->prepare("SELECT * FROM project_members WHERE project_id = ? AND user_id = ?");
            $memberCheck->execute([$projectId, $userId]);
            if ($memberCheck->fetch()) {
                return sendError('User is already a member of this project', 409);
            }

            $currentTime = date('Y-m-d H:i:s');
            $stmt = $conn->prepare("INSERT INTO project_members (project_id, user_id, role, joined_at) VALUES (?, ?, ?, ?)");
            $stmt->execute([
                $projectId,
                $userId,
                $data['role'],
                $data['joined_at'] ?? $currentTime
            ]);

            // Get user details to return
            $userStmt = $conn->prepare("SELECT id, name, email FROM users WHERE id = ?");
            $userStmt->execute([$userId]);
            $user = $userStmt->fetch(PDO::FETCH_ASSOC);

            sendResponse([
                'message' => 'Member added successfully',
                'member' => [
                    'user_id' => $userId,
                    'user' => $user,
                    'role' => $data['role'],
                    'joined_at' => $data['joined_at'] ?? $currentTime
                ]
            ]);
        }

        // DELETE: Remove member
        if ($method == 'DELETE') {
            $rawData = file_get_contents('php://input');
            if (empty($rawData)) {
                return sendError('No data provided', 400);
            }

            $data = json_decode($rawData, true);
            if (json_last_error() !== JSON_ERROR_NONE) {
                return sendError('Invalid JSON: ' . json_last_error_msg(), 400);
            }

            if (!isset($data['user_id'])) {
                return sendError('Missing user_id', 400);
            }

            $userId = filter_var($data['user_id'], FILTER_VALIDATE_INT);
            if (!$userId) {
                return sendError('Invalid user ID format', 400);
            }

            // Check if member exists before deleting
            $memberCheck = $conn->prepare("SELECT * FROM project_members WHERE project_id = ? AND user_id = ?");
            $memberCheck->execute([$projectId, $userId]);
            if (!$memberCheck->fetch()) {
                return sendError('User is not a member of this project', 404);
            }

            $stmt = $conn->prepare("DELETE FROM project_members WHERE project_id = ? AND user_id = ?");
            $stmt->execute([$projectId, $userId]);

            sendResponse([
                'message' => 'Member removed successfully',
                'project_id' => $projectId,
                'user_id' => $userId
            ]);
        }

        // PUT: Update member role
        if ($method == 'PUT') {
            $rawData = file_get_contents('php://input');
            if (empty($rawData)) {
                return sendError('No data provided', 400);
            }

            $data = json_decode($rawData, true);
            if (json_last_error() !== JSON_ERROR_NONE) {
                return sendError('Invalid JSON: ' . json_last_error_msg(), 400);
            }

            if (!isset($data['user_id']) || !isset($data['role'])) {
                return sendError('Missing required fields: user_id and role', 400);
            }

            $userId = filter_var($data['user_id'], FILTER_VALIDATE_INT);
            if (!$userId) {
                return sendError('Invalid user ID format', 400);
            }

            // Check if member exists before updating
            $memberCheck = $conn->prepare("SELECT * FROM project_members WHERE project_id = ? AND user_id = ?");
            $memberCheck->execute([$projectId, $userId]);
            if (!$memberCheck->fetch()) {
                return sendError('User is not a member of this project', 404);
            }

            $stmt = $conn->prepare("UPDATE project_members SET role = ? WHERE project_id = ? AND user_id = ?");
            $stmt->execute([$data['role'], $projectId, $userId]);

            sendResponse([
                'message' => 'Member role updated successfully',
                'project_id' => $projectId,
                'user_id' => $userId,
                'role' => $data['role']
            ]);
        }
    }
    // Regular project endpoints
    // GET: List all projects or by id
    if ($method == 'GET') {
        $userId = isset($_GET['user_id']) ? filter_var($_GET['user_id'], FILTER_VALIDATE_INT) : null;

        // Get single project by ID
        if (isset($_GET['id'])) {
            $projectId = filter_var($_GET['id'], FILTER_VALIDATE_INT);
            if (!$projectId) {
                return sendError('Invalid project ID format', 400);
            }

            $stmt = $conn->prepare("SELECT * FROM projects WHERE id = ?");
            $stmt->execute([$projectId]);
            $project = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($project) {
                // Get creator info
                $creatorStmt = $conn->prepare("SELECT id, name, email FROM users WHERE id = ?");
                $creatorStmt->execute([$project['creator_id']]);
                $project['creator'] = $creatorStmt->fetch(PDO::FETCH_ASSOC);

                // Get project members with user details
                $membersStmt = $conn->prepare(
                    "SELECT pm.user_id, pm.role, pm.joined_at, u.name, u.email
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
                            'email' => $m['email']
                        ],
                        'role' => $m['role'],
                        'joined_at' => $m['joined_at'],
                    ];
                }
                $project['members'] = $members;
                sendResponse($project);
            } else {
                sendResponse(null);
            }
        }

        // List projects - with personalization if user_id provided
        $query = "SELECT p.*, u.name as creator_name, u.email as creator_email
                FROM projects p
                JOIN users u ON p.creator_id = u.id";

        // Filter by user if user_id is provided (personalization)
        if ($userId) {
            $query = "SELECT p.*, u.name as creator_name, u.email as creator_email
                    FROM projects p
                    JOIN users u ON p.creator_id = u.id
                    JOIN project_members pm ON p.id = pm.project_id
                    WHERE pm.user_id = ?";
            $stmt = $conn->prepare($query);
            $stmt->execute([$userId]);
        } else {
            $stmt = $conn->prepare($query);
            $stmt->execute();
        }

        $projects = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Get members for each project
        foreach ($projects as &$project) {
            $membersStmt = $conn->prepare(
                "SELECT pm.user_id, pm.role, pm.joined_at, u.name, u.email
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
                        'email' => $m['email']
                    ],
                    'role' => $m['role'],
                    'joined_at' => $m['joined_at'],
                ];
            }
        }

        sendResponse($projects);
    }

    // POST: Create new project
    if ($method == 'POST') {
        $rawData = file_get_contents('php://input');
        if (empty($rawData)) {
            return sendError('No data provided', 400);
        }

        $data = json_decode($rawData, true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            return sendError('Invalid JSON: ' . json_last_error_msg(), 400);
        }

        // Validate input
        $rules = [
            'name' => 'required|string',
            'creator_id' => 'required|int',
            'description' => 'string',
            'status' => 'string',
            'created_at' => 'required|string',
            'updated_at' => 'required|string'
        ];

        $validation = validateInput($data, $rules);
        if (!empty($validation['errors'])) {
            return sendError('Validation failed: ' . implode(', ', $validation['errors']), 422);
        }

        $data = $validation['data'];

        // Set default values for optional fields
        $currentTime = date('Y-m-d H:i:s');
        $data['created_at'] = $data['created_at'] ?? $currentTime;
        $data['updated_at'] = $data['updated_at'] ?? $currentTime;

        try {
            $conn->beginTransaction();

            // Insert project
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
            $memberStmt = $conn->prepare("INSERT INTO project_members (project_id, user_id, role, joined_at) VALUES (?, ?, ?, ?)");
            $memberStmt->execute([
                $projectId,
                $data['creator_id'],
                'admin',
                $data['created_at']
            ]);

            // Insert other members if provided
            if (!empty($data['member_ids']) && is_array($data['member_ids'])) {
                foreach ($data['member_ids'] as $memberId) {
                    // Make sure memberId is a valid integer
                    if (!filter_var($memberId, FILTER_VALIDATE_INT)) {
                        continue;
                    }

                    $role = isset($data['member_roles'][$memberId]) ?
                        filter_var($data['member_roles'][$memberId], FILTER_SANITIZE_STRING) : 'member';

                    $memberStmt->execute([
                        $projectId,
                        $memberId,
                        $role,
                        $data['created_at']
                    ]);
                }
            }

            $conn->commit();

            // Get the created project details to return
            $projStmt = $conn->prepare("SELECT * FROM projects WHERE id = ?");
            $projStmt->execute([$projectId]);
            $project = $projStmt->fetch(PDO::FETCH_ASSOC);
            sendResponse([
                'message' => 'Project created successfully',
                'project_id' => $projectId,
                'project' => $project
            ]);

        } catch (PDOException $e) {
            $conn->rollBack();
            return sendError('Database error during project creation: ' . $e->getMessage(), 500);
        }
    }    // PUT: Update project
    if ($method == 'PUT') {
        $rawData = file_get_contents('php://input');
        if (empty($rawData)) {
            return sendError('No data provided', 400);
        }

        $data = json_decode($rawData, true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            return sendError('Invalid JSON: ' . json_last_error_msg(), 400);
        }

        if (!isset($data['id'])) {
            return sendError('Missing project ID', 400);
        }

        // Validate input
        $rules = [
            'id' => 'required|int',
            'name' => 'string',
            'description' => 'string',
            'status' => 'string',
            'updated_at' => 'string'
        ];

        $validation = validateInput($data, $rules);
        if (!empty($validation['errors'])) {
            return sendError('Validation failed: ' . implode(', ', $validation['errors']), 422);
        }

        $data = $validation['data'];
        // Set default values for optional fields
        $currentTime = date('Y-m-d H:i:s');
        $data['updated_at'] = $data['updated_at'] ?? $currentTime;

        try {
            // Check if project exists
            $checkStmt = $conn->prepare("SELECT id FROM projects WHERE id = ?");
            $checkStmt->execute([$data['id']]);
            if (!$checkStmt->fetch()) {
                return sendError('Project not found', 404);
            }

            // Update project
            $stmt = $conn->prepare(
                "UPDATE projects
                SET name = ?, description = ?, task_count = ?, thread_count = ?,
                    status = ?, updated_at = ?
                WHERE id = ?"
            );
            $stmt->execute([
                $data['name'] ?? null,
                $data['description'] ?? null,
                $data['task_count'] ?? 0,
                $data['thread_count'] ?? 0,
                $data['status'] ?? 'active',
                $data['updated_at'],
                $data['id']
            ]);

            // Get updated project details
            $projStmt = $conn->prepare("SELECT * FROM projects WHERE id = ?");
            $projStmt->execute([$data['id']]);
            $project = $projStmt->fetch(PDO::FETCH_ASSOC);

            sendResponse([
                'message' => 'Project updated successfully',
                'project' => $project
            ]);
        } catch (PDOException $e) {
            return sendError('Database error during project update: ' . $e->getMessage(), 500);
        }
    }    // DELETE: Delete project and its members
    if ($method == 'DELETE') {
        $rawData = file_get_contents('php://input');
        if (empty($rawData)) {
            return sendError('No data provided', 400);
        }

        $data = json_decode($rawData, true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            return sendError('Invalid JSON: ' . json_last_error_msg(), 400);
        }

        if (!isset($data['id'])) {
            return sendError('Missing project ID', 400);
        }

        $projectId = filter_var($data['id'], FILTER_VALIDATE_INT);
        if (!$projectId) {
            return sendError('Invalid project ID format', 400);
        }

        // Check if project exists
        $checkStmt = $conn->prepare("SELECT id FROM projects WHERE id = ?");
        $checkStmt->execute([$projectId]);
        if (!$checkStmt->fetch()) {
            return sendError('Project not found', 404);
        }

        $conn->beginTransaction();
        try {
            // Delete associated tasks if needed
            $taskStmt = $conn->prepare("DELETE FROM tasks WHERE project_id = ?");
            $taskStmt->execute([$projectId]);

            // Delete related threads if needed
            $threadStmt = $conn->prepare("DELETE FROM threads WHERE project_id = ?");
            $threadStmt->execute([$projectId]);

            // Delete project members
            $memberStmt = $conn->prepare("DELETE FROM project_members WHERE project_id = ?");
            $memberStmt->execute([$projectId]);

            // Finally delete the project itself
            $projectStmt = $conn->prepare("DELETE FROM projects WHERE id = ?");
            $projectStmt->execute([$projectId]);

            $conn->commit();
            sendResponse([
                'message' => 'Project and related data deleted successfully',
                'project_id' => $projectId
            ]);
        } catch (Exception $e) {
            $conn->rollBack();
            return sendError('Error deleting project: ' . $e->getMessage(), 500);
        }
    }    // If we get here, no endpoint matched the request
    return sendError('Invalid endpoint or HTTP method', 404);

} catch (PDOException $e) {
    // Log the error for debugging (make sure error logging is configured)
    error_log('Database error in projects.php: ' . $e->getMessage());

    // Return a safe error message to the client
    return sendError('Database operation failed. Please try again later.', 500);

} catch (Exception $e) {
    // Log the error for debugging
    error_log('Server error in projects.php: ' . $e->getMessage());

    // Return a safe error message to the client
    return sendError('An unexpected error occurred. Please try again later.', 500);
}

// Make sure nothing else is outputted after this closing tag
?>