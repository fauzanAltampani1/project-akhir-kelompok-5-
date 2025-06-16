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

    // GET: List messages or get by id
    if ($method == 'GET') {
        if (isset($_GET['id'])) {
            // Get single message with sender, attachments, mentions
            $stmt = $conn->prepare("SELECT * FROM messages WHERE id = ?");
            $stmt->execute([$_GET['id']]);
            $msg = $stmt->fetch(PDO::FETCH_ASSOC);
            if ($msg) {
                // Get sender
                $senderStmt = $conn->prepare("SELECT * FROM users WHERE id = ?");
                $senderStmt->execute([$msg['sender_id']]);
                $msg['sender'] = $senderStmt->fetch(PDO::FETCH_ASSOC);

                // Get attachments
                $attStmt = $conn->prepare("SELECT * FROM message_attachments WHERE message_id = ?");
                $attStmt->execute([$msg['id']]);
                $msg['attachments'] = $attStmt->fetchAll(PDO::FETCH_ASSOC);

                // Get mentions
                $menStmt = $conn->prepare("SELECT * FROM mentions WHERE message_id = ?");
                $menStmt->execute([$msg['id']]);
                $msg['mentions'] = $menStmt->fetchAll(PDO::FETCH_ASSOC);

                echo json_encode($msg);
            } else {
                echo json_encode([]);
            }
        } else if (isset($_GET['thread_id'])) {
            // Get all messages in a thread
            $stmt = $conn->prepare("SELECT * FROM messages WHERE thread_id = ? ORDER BY created_at ASC");
            $stmt->execute([$_GET['thread_id']]);
            $messages = [];
            while ($msg = $stmt->fetch(PDO::FETCH_ASSOC)) {
                // Get sender
                $senderStmt = $conn->prepare("SELECT * FROM users WHERE id = ?");
                $senderStmt->execute([$msg['sender_id']]);
                $msg['sender'] = $senderStmt->fetch(PDO::FETCH_ASSOC);

                // Get attachments
                $attStmt = $conn->prepare("SELECT * FROM message_attachments WHERE message_id = ?");
                $attStmt->execute([$msg['id']]);
                $msg['attachments'] = $attStmt->fetchAll(PDO::FETCH_ASSOC);

                // Get mentions
                $menStmt = $conn->prepare("SELECT * FROM mentions WHERE message_id = ?");
                $menStmt->execute([$msg['id']]);
                $msg['mentions'] = $menStmt->fetchAll(PDO::FETCH_ASSOC);

                $messages[] = $msg;
            }
            echo json_encode($messages);
        } else {
            echo json_encode([]);
        }
        exit;
    }

    // POST: Create new message
    if ($method == 'POST') {
        $data = json_decode(file_get_contents('php://input'), true);

        // Insert message
        $stmt = $conn->prepare("INSERT INTO messages (id, thread_id, sender_id, content, type, created_at, updated_at, is_edited, reply_to_message_id, is_unread) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
        $stmt->execute([
            $data['id'],
            $data['thread_id'],
            $data['sender']['id'],
            $data['content'],
            $data['type'],
            $data['created_at'],
            $data['updated_at'] ?? null,
            $data['is_edited'] ?? 0,
            $data['reply_to_message_id'] ?? null,
            $data['is_unread'] ?? 1
        ]);

        // Insert attachments
        if (!empty($data['attachments'])) {
            foreach ($data['attachments'] as $att) {
                $attStmt = $conn->prepare("INSERT INTO message_attachments (id, message_id, file_name, file_size, file_type, url, thumbnail_url, mime_type) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
                $attStmt->execute([
                    $att['id'],
                    $data['id'],
                    $att['file_name'],
                    $att['file_size'],
                    $att['file_type'],
                    $att['url'],
                    $att['thumbnail_url'] ?? null,
                    $att['mime_type'] ?? null
                ]);
            }
        }

        // Insert mentions
        if (!empty($data['mentions'])) {
            foreach ($data['mentions'] as $men) {
                $menStmt = $conn->prepare("INSERT INTO mentions (message_id, mention_text, user_id) VALUES (?, ?, ?)");
                $menStmt->execute([
                    $data['id'],
                    $men['mention_text'],
                    $men['user_id'] ?? null
                ]);
            }
        }

        echo json_encode(['status' => 'success']);
        exit;
    }

    // PUT: Update message (basic fields only)
    if ($method == 'PUT') {
        parse_str(file_get_contents("php://input"), $data);
        $stmt = $conn->prepare("UPDATE messages SET content=?, type=?, updated_at=?, is_edited=?, reply_to_message_id=?, is_unread=? WHERE id=?");
        $stmt->execute([
            $data['content'],
            $data['type'],
            $data['updated_at'] ?? null,
            $data['is_edited'] ?? 0,
            $data['reply_to_message_id'] ?? null,
            $data['is_unread'] ?? 1,
            $data['id']
        ]);
        echo json_encode(['status' => 'success']);
        exit;
    }

    // DELETE: Delete message (and related attachments/mentions)
    if ($method == 'DELETE') {
        parse_str(file_get_contents("php://input"), $data);
        $msgId = $data['id'];
        $conn->prepare("DELETE FROM message_attachments WHERE message_id=?")->execute([$msgId]);
        $conn->prepare("DELETE FROM mentions WHERE message_id=?")->execute([$msgId]);
        $conn->prepare("DELETE FROM messages WHERE id=?")->execute([$msgId]);
        echo json_encode(['status' => 'success']);
        exit;
    }

    echo json_encode(['status' => 'error', 'message' => 'Invalid request']);
} catch (PDOException $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
?>