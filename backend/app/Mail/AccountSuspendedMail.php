<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class AccountSuspendedMail extends Mailable
{
    use Queueable, SerializesModels;

    public string $userName;
    public string $reason;
    public string $appName;

    public function __construct(string $userName, string $reason = '', string $appName = 'EasyRead')
    {
        $this->userName = $userName;
        $this->reason   = $reason ?: 'Policy violation or administrative action';
        $this->appName  = $appName;
    }

    public function build(): self
    {
        return $this
            ->subject("Important Security Notice: Your {$this->appName} Account has been suspended")
            ->html($this->buildHtml());
    }

    private function buildHtml(): string
    {
        $name    = e($this->userName);
        $reason  = e($this->reason);
        $appName = e($this->appName);
        $year    = date('Y');

        return <<<HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{$appName} Account Suspension Notice</title>
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
    .notice-box {
      background-color: #FEF2F2;
      border: 1px solid #FCA5A5;
      border-radius: 8px;
      padding: 16px;
      margin: 0 0 24px;
      font-size: 13.5px;
      color: #991B1B;
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
        <p class="paragraph">This is an automated notice to inform you that your <strong>{$appName}</strong> account has been temporarily suspended by an administrator.</p>
        
        <div class="notice-box">
          <strong>Reason:</strong> {$reason}
        </div>

        <p class="paragraph">While suspended, you will not be able to log in, access online libraries, use AI assistants, or sync reading data.</p>
        <p class="paragraph" style="font-size: 13px; color: #6C757D; margin-bottom: 0;">If you believe this suspension is in error or wish to appeal, please contact our support team with your registered email.</p>
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
