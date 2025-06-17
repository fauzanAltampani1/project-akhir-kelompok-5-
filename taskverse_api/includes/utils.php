<?php
/**
 * Common utility functions for the TaskVerse API
 */

function validateInput($data, $rules)
{
    $errors = [];
    foreach ($rules as $field => $rule) {
        if (!isset($data[$field]) && strpos($rule, 'required') !== false) {
            $errors[] = "$field is required";
        } elseif (isset($data[$field])) {
            if (strpos($rule, 'string') !== false) {
                $data[$field] = htmlspecialchars(strip_tags($data[$field]));
            } elseif (strpos($rule, 'int') !== false) {
                $data[$field] = filter_var($data[$field], FILTER_VALIDATE_INT);
                if ($data[$field] === false) {
                    $errors[] = "$field must be an integer";
                }
            } elseif (strpos($rule, 'email') !== false) {
                if (!filter_var($data[$field], FILTER_VALIDATE_EMAIL)) {
                    $errors[] = "$field must be a valid email";
                }
            }
        }
    }
    return ['data' => $data, 'errors' => $errors];
}

function logError($message, $context = [])
{
    if (!LOG_ERRORS)
        return;

    $timestamp = date('Y-m-d H:i:s');
    $contextStr = !empty($context) ? json_encode($context) : '';
    $logMessage = "[$timestamp] $message $contextStr\n";

    error_log($logMessage, 3, ERROR_LOG_FILE);
}

function getRateLimitHeaders()
{
    $minute = date('YmdHi');
    $counter = isset($_SESSION['rate_limit'][$minute]) ? $_SESSION['rate_limit'][$minute] : 0;

    return [
        'X-RateLimit-Limit' => API_RATE_LIMIT,
        'X-RateLimit-Remaining' => max(0, API_RATE_LIMIT - $counter),
        'X-RateLimit-Reset' => strtotime('next minute')
    ];
}

function checkRateLimit()
{
    $minute = date('YmdHi');
    if (!isset($_SESSION['rate_limit'][$minute])) {
        $_SESSION['rate_limit'] = [$minute => 1];
    } else {
        $_SESSION['rate_limit'][$minute]++;
    }

    return $_SESSION['rate_limit'][$minute] <= API_RATE_LIMIT;
}

function sendResponse($data, $status = 'success')
{
    $headers = getRateLimitHeaders();
    foreach ($headers as $name => $value) {
        header("$name: $value");
    }

    $response = [
        'status' => $status,
        'data' => $data,
        'timestamp' => time(),
        'api_version' => API_VERSION
    ];

    echo json_encode($response);
    return true;
}

function sendError($message, $code = 400)
{
    http_response_code($code);
    $headers = getRateLimitHeaders();
    foreach ($headers as $name => $value) {
        header("$name: $value");
    }

    $response = [
        'status' => 'error',
        'message' => $message,
        'code' => $code,
        'timestamp' => time(),
        'api_version' => API_VERSION
    ];

    if (LOG_ERRORS) {
        logError($message, ['code' => $code, 'request_uri' => $_SERVER['REQUEST_URI']]);
    }

    echo json_encode($response);
    return false;
}

function connectDB()
{
    try {
        $dsn = "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=" . DB_CHARSET;
        $options = [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ];

        return new PDO($dsn, DB_USER, DB_PASS, $options);
    } catch (PDOException $e) {
        logError("Database connection failed: " . $e->getMessage());
        sendError("Database connection failed", 500);
        return null;
    }
}
?>