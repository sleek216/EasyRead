<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class SubscriptionReceiptMail extends Mailable
{
    use Queueable, SerializesModels;

    public string $userName;
    public string $planName;
    public string $price;
    public string $expiresAt;
    public string $appName;

    public function __construct(string $userName, string $planName, string $price = '', string $expiresAt = '', string $appName = 'EasyRead')
    {
        $this->userName  = $userName;
        $this->planName  = $planName;
        $this->price     = $price;
        $this->expiresAt = $expiresAt;
        $this->appName   = $appName;
    }

    public function build(): self
    {
        return $this
            ->subject("Receipt: Welcome to {$this->planName} on {$this->appName}")
            ->html($this->buildHtml());
    }

    private function buildHtml(): string
    {
        $name     = e($this->userName);
        $plan     = e($this->planName);
        $price    = e($this->price ?: 'Active');
        $expires  = e($this->expiresAt ?: 'Auto-renewing');
        $appName  = e($this->appName);
        $year     = date('Y');

        return <<<HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{$appName} Subscription Confirmation</title>
  <style>
    body {
      margin: 0;
      padding: 0;
      background-color: #F8F9FA;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      color: #212529;
      -webkit-font-smoothing: antialiased;
    }
    table {
      border-collapse: collapse;
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
    .receipt-box {
      background-color: #F8F9FA;
      border: 1px solid #E2E8F0;
      border-radius: 8px;
      padding: 20px;
      margin: 0 0 24px;
    }
    .receipt-row {
      display: flex;
      justify-content: space-between;
      padding: 6px 0;
      font-size: 13.5px;
      border-bottom: 1px dashed #E2E8F0;
    }
    .receipt-row:last-child {
      border-bottom: none;
    }
    .receipt-label {
      color: #6C757D;
      font-weight: 500;
    }
    .receipt-value {
      color: #16241D;
      font-weight: 600;
      text-align: right;
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
        <p class="paragraph">Thank you for subscribing to <strong>{$plan}</strong>! All premium reading tools, unlimited AI lookups, cross-device sync, and custom collections have been unlocked for your account.</p>
        
        <table width="100%" cellpadding="0" cellspacing="0" class="receipt-box" style="background-color: #F8F9FA; border: 1px solid #E2E8F0; border-radius: 8px; margin-bottom: 24px;">
          <tr>
            <td style="padding: 10px 16px; font-size: 13px; color: #6C757D; border-bottom: 1px solid #E9ECEF;">Plan</td>
            <td style="padding: 10px 16px; font-size: 13px; color: #16241D; font-weight: 600; text-align: right; border-bottom: 1px solid #E9ECEF;">{$plan}</td>
          </tr>
          <tr>
            <td style="padding: 10px 16px; font-size: 13px; color: #6C757D; border-bottom: 1px solid #E9ECEF;">Status</td>
            <td style="padding: 10px 16px; font-size: 13px; color: #2E7D32; font-weight: 600; text-align: right; border-bottom: 1px solid #E9ECEF;">Active</td>
          </tr>
          <tr>
            <td style="padding: 10px 16px; font-size: 13px; color: #6C757D; border-bottom: 1px solid #E9ECEF;">Price</td>
            <td style="padding: 10px 16px; font-size: 13px; color: #16241D; font-weight: 600; text-align: right; border-bottom: 1px solid #E9ECEF;">{$price}</td>
          </tr>
          <tr>
            <td style="padding: 10px 16px; font-size: 13px; color: #6C757D;">Expires / Renews</td>
            <td style="padding: 10px 16px; font-size: 13px; color: #16241D; font-weight: 600; text-align: right;">{$expires}</td>
          </tr>
        </table>

        <p class="paragraph" style="font-size: 13px; color: #6C757D; margin-bottom: 0;">You can manage or modify your subscription at any time from your device's app store or in-app profile settings.</p>
      </div>
      <div class="footer">
        &copy; {$year} {$appName}. All rights reserved.<br>
        If you have any questions, reach out to our support team.
      </div>
    </div>
  </div>
</body>
</html>
HTML;
    }
}
