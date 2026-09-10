<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class AccountReactivatedMail extends Mailable
{
    use Queueable, SerializesModels;

    public string $userName;
    public string $appName;

    public function __construct(string $userName, string $appName = 'EasyRead')
    {
        $this->userName = $userName;
        $this->appName  = $appName;
    }

    public function build(): self
    {
        return $this
            ->subject("Account Restored: Your {$this->appName} Account is Now Active")
            ->html($this->buildHtml());
    }

    private function buildHtml(): string
    {
        $name    = e($this->userName);
        $appName = e($this->appName);
        $year    = date('Y');

        return <<<HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{$appName} Account Reactivated</title>
  <style>
    body {
      margin: 0;
      padding: 0;
      background-color: #F8F9FA;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      color: #212529;
      -webkit-font-smoothing: antialiased;
    }
    .wrapper {
      width: 100%;
      background-color: #F8F9FA;
      padding: 40px 16px;
    }
    .card {
      max-width: 480px;
      margin: 0 auto;
      background-color: #FFFFFF;
      border: 1px solid #E9ECEF;
      border-radius: 12px;
      overflow: hidden;
    }
    .header {
      padding: 32px 32px 24px;
      border-bottom: 1px solid #F1F3F5;
    }
    .brand-name {
      font-size: 20px;
      font-weight: 700;
      color: #16241D;
      letter-spacing: -0.5px;
      text-decoration: none;
      display: inline-block;
    }
    .body {
      padding: 32px 32px 28px;
    }
    .greeting {
      font-size: 16px;
      font-weight: 600;
      color: #212529;
      margin: 0 0 14px;
    }
    .paragraph {
      font-size: 14px;
      line-height: 1.6;
      color: #495057;
      margin: 0 0 20px;
    }
    .success-box {
      background-color: #F0FDF4;
      border: 1px solid #86EFAC;
      border-radius: 8px;
      padding: 16px;
      margin: 0 0 24px;
      font-size: 13.5px;
      color: #166534;
      line-height: 1.5;
    }
    .footer {
      padding: 24px 32px;
      background-color: #FAFAFA;
      border-top: 1px solid #F1F3F5;
      font-size: 12px;
      color: #868E96;
      line-height: 1.5;
    }
  </style>
</head>
<body>
  <div class="wrapper">
    <div class="card">
      <div class="header">
        <span class="brand-name">{$appName}</span>
      </div>
      <div class="body">
        <p class="greeting">Hello {$name},</p>
        <p class="paragraph">We are pleased to inform you that your <strong>{$appName}</strong> account has been successfully reactivated by an administrator.</p>
        
        <div class="success-box">
          <strong>Account Status:</strong> Active &bull; All reader services restored
        </div>

        <p class="paragraph">You can now open the EasyRead app, log in to your account, and access your books, reading history, saved vocabulary, and AI reading assistant.</p>
        <p class="paragraph" style="font-size: 13px; color: #6C757D; margin-bottom: 0;">If you have any questions or require support, please feel free to reach out to our team.</p>
      </div>
      <div class="footer">
        &copy; {$year} {$appName}. All rights reserved.
      </div>
    </div>
  </div>
</body>
</html>
HTML;
    }
}
