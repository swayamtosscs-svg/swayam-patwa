<?php
// test-email-service.php - Debug endpoint for email service
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Test basic email functionality
    $testEmail = 'test@example.com';
    $subject = 'Email Service Test';
    $message = 'This is a test email to verify the email service is working.';
    $headers = 'From: noreply@rgram.com';
    
    $result = mail($testEmail, $subject, $message, $headers);
    
    echo json_encode([
        'success' => $result,
        'message' => $result ? 'Email service is working' : 'Email service failed',
        'php_mail_function' => function_exists('mail'),
        'sendmail_path' => ini_get('sendmail_path'),
        'smtp_host' => ini_get('SMTP'),
        'smtp_port' => ini_get('smtp_port'),
        'php_version' => phpversion()
    ]);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    $email = $input['email'] ?? 'test@example.com';
    
    $subject = 'Email Service Test - ' . date('Y-m-d H:i:s');
    $message = 'This is a test email sent at ' . date('Y-m-d H:i:s') . ' to verify email service functionality.';
    $headers = [
        'MIME-Version: 1.0',
        'Content-type: text/plain; charset=UTF-8',
        'From: noreply@rgram.com',
        'X-Mailer: PHP/' . phpversion()
    ];
    
    $result = mail($email, $subject, $message, implode("\r\n", $headers));
    
    echo json_encode([
        'success' => $result,
        'message' => $result ? 'Test email sent successfully' : 'Failed to send test email',
        'email' => $email,
        'timestamp' => date('Y-m-d H:i:s')
    ]);
    exit;
}

http_response_code(405);
echo json_encode(['success' => false, 'message' => 'Method not allowed']);
?>

