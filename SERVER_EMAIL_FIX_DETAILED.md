# Server-Side Email Service Fix

## 🔧 **Immediate Server Fix Required**

The server at `http://103.14.120.163:8081` needs to fix the email service configuration.

### **Server Code Fix (PHP/Node.js)**

```php
<?php
// forgot-password.php endpoint fix

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);
$email = $input['email'] ?? '';

if (empty($email)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Email is required']);
    exit;
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid email format']);
    exit;
}

try {
    // Generate reset token
    $resetToken = bin2hex(random_bytes(32));
    $expiryTime = time() + (60 * 60); // 1 hour expiry
    
    // Store reset token in database
    $stmt = $pdo->prepare("INSERT INTO password_resets (email, token, expires_at) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE token = ?, expires_at = ?");
    $stmt->execute([$email, $resetToken, $expiryTime, $resetToken, $expiryTime]);
    
    // Send email
    $resetLink = "http://103.14.120.163:8081/reset-password?token=" . $resetToken;
    
    $subject = "Password Reset Request - R-Gram";
    $message = "
    <html>
    <head>
        <title>Password Reset</title>
    </head>
    <body>
        <h2>Password Reset Request</h2>
        <p>You requested a password reset for your R-Gram account.</p>
        <p>Click the link below to reset your password:</p>
        <a href='$resetLink' style='background-color: #4CAF50; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;'>Reset Password</a>
        <p>This link will expire in 1 hour.</p>
        <p>If you didn't request this, please ignore this email.</p>
        <br>
        <p>Best regards,<br>R-Gram Team</p>
    </body>
    </html>
    ";
    
    $headers = [
        'MIME-Version: 1.0',
        'Content-type: text/html; charset=UTF-8',
        'From: noreply@rgram.com',
        'Reply-To: support@rgram.com',
        'X-Mailer: PHP/' . phpversion()
    ];
    
    // Use PHPMailer or similar for better email delivery
    $emailSent = mail($email, $subject, $message, implode("\r\n", $headers));
    
    if ($emailSent) {
        echo json_encode([
            'success' => true,
            'message' => 'Password reset link sent successfully to your email'
        ]);
    } else {
        // Log the error
        error_log("Failed to send password reset email to: $email");
        
        echo json_encode([
            'success' => false,
            'message' => 'Failed to send email. Please try again later.'
        ]);
    }
    
} catch (Exception $e) {
    error_log("Password reset error: " . $e->getMessage());
    
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Email service temporarily unavailable. Please try again later.'
    ]);
}
?>
```

### **Alternative: Use PHPMailer (Recommended)**

```php
<?php
require_once 'vendor/autoload.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\SMTP;
use PHPMailer\PHPMailer\Exception;

// ... (same validation code as above)

try {
    $mail = new PHPMailer(true);
    
    // SMTP Configuration
    $mail->isSMTP();
    $mail->Host = 'smtp.gmail.com'; // or your SMTP server
    $mail->SMTPAuth = true;
    $mail->Username = 'your-email@gmail.com';
    $mail->Password = 'your-app-password';
    $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
    $mail->Port = 587;
    
    // Email content
    $mail->setFrom('noreply@rgram.com', 'R-Gram');
    $mail->addAddress($email);
    $mail->isHTML(true);
    $mail->Subject = 'Password Reset Request - R-Gram';
    $mail->Body = $message; // HTML message from above
    
    $mail->send();
    
    echo json_encode([
        'success' => true,
        'message' => 'Password reset link sent successfully to your email'
    ]);
    
} catch (Exception $e) {
    error_log("Email sending failed: " . $mail->ErrorInfo);
    
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Email service temporarily unavailable. Please try again later.'
    ]);
}
?>
```

### **Database Schema**

```sql
CREATE TABLE password_resets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    token VARCHAR(255) NOT NULL,
    expires_at INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_email (email)
);
```

## 🚀 **Quick Fix Options**

### **Option 1: Use Gmail SMTP**
1. Enable 2-factor authentication on Gmail
2. Generate App Password
3. Use Gmail SMTP settings

### **Option 2: Use SendGrid**
1. Sign up for SendGrid
2. Get API key
3. Use SendGrid API

### **Option 3: Use Mailgun**
1. Sign up for Mailgun
2. Get API credentials
3. Use Mailgun API

## 📧 **Email Service Providers**

1. **Gmail SMTP** (Free)
2. **SendGrid** (Free tier: 100 emails/day)
3. **Mailgun** (Free tier: 5,000 emails/month)
4. **Amazon SES** (Pay per use)
5. **Mailchimp** (Free tier available)

## 🔧 **Server Configuration**

Make sure these are configured:
- SMTP server settings
- Email credentials
- Firewall rules (port 587/465)
- SSL/TLS certificates
- Rate limiting settings

