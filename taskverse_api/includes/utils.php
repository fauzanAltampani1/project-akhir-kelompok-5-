<?php
/**
 * Common utility functions for the TaskVerse API
 */

// Prevent any output before JSON response
error_reporting(E_ERROR | E_PARSE);
ini_set('display_errors', 0);

/**
 * PHPMD suppress CyclomaticComplexity: This function is intentionally comprehensive for API validation.
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
    if (!defined('LOG_ERRORS') || !LOG_ERRORS)
        return;

    $timestamp = date('Y-m-d H:i:s');
    $contextStr = !empty($context) ? json_encode($context) : '';
    $logMessage = "[$timestamp] $message $contextStr\n";

    $logFile = defined('ERROR_LOG_FILE') ? ERROR_LOG_FILE : __DIR__ . '/../logs/api_errors.log';
    @error_log($logMessage, 3, $logFile);
}

function getRateLimitHeaders($session)
{
    $minute = date('YmdHi');
    $counter = isset($session['rate_limit'][$minute]) ? $session['rate_limit'][$minute] : 0;

    return [
        'X-RateLimit-Limit' => API_RATE_LIMIT,
        'X-RateLimit-Remaining' => max(0, API_RATE_LIMIT - $counter),
        'X-RateLimit-Reset' => strtotime('next minute')
    ];
}

/**
 * PHPMD suppress Superglobals: Session is required for rate limiting.
 */
function checkRateLimit()
{
    global $_SESSION;
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    $minute = date('YmdHi');
    if (!isset($_SESSION['rate_limit'][$minute])) {
        $_SESSION['rate_limit'] = [$minute => 1];
        return true;
    }

    $_SESSION['rate_limit'][$minute]++;
    return $_SESSION['rate_limit'][$minute] <= API_RATE_LIMIT;
}

/**
 * PHPMD suppress Superglobals: Session is required for rate limiting.
 */
function sendResponse($data, $status = 'success')
{
    // Clean any output buffer
    if (ob_get_level()) {
        ob_end_clean();
    }

    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    $headers = getRateLimitHeaders($_SESSION);
    foreach ($headers as $name => $value) {
        header("$name: $value");
    }

    $response = [
        'status' => $status,
        'data' => $data,
        'timestamp' => time(),
        'api_version' => defined('API_VERSION') ? API_VERSION : '1.0.0'
    ];

    echo json_encode($response, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    exit; // Prevent any further output
}

/**
 * PHPMD suppress Superglobals: Session is required for rate limiting and error logging.
 */
function sendError($message, $code = 400)
{
    // Clean any output buffer
    if (ob_get_level()) {
        ob_end_clean();
    }

    global $_SESSION;
    http_response_code($code);
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    $headers = getRateLimitHeaders($_SESSION);
    foreach ($headers as $name => $value) {
        header("$name: $value");
    }

    $response = [
        'status' => 'error',
        'message' => $message,
        'code' => $code,
        'timestamp' => time(),
        'api_version' => defined('API_VERSION') ? API_VERSION : '1.0.0'
    ];

    if (defined('LOG_ERRORS') && LOG_ERRORS) {
        logError($message, ['code' => $code, 'request_uri' => $_SERVER['REQUEST_URI'] ?? '']);
    }

    echo json_encode($response, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    exit; // Prevent any further output
}

function connectDB()
{
    try {
        // Ensure constants are defined
        if (!defined('DB_HOST') || !defined('DB_NAME') || !defined('DB_USER') || !defined('DB_PASS') || !defined('DB_CHARSET')) {
            throw new Exception('Database configuration constants not defined');
        }

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
    } catch (Exception $e) {
        logError("Configuration error: " . $e->getMessage());
        sendError("Server configuration error", 500);
        return null;
    }
}
?>