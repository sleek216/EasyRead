<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class OtpPasswordResetMail extends Mailable
{
    use Queueable, SerializesModels;

    public string $otp;
    public string $userName;
    public string $appName;

    public function __construct(string $otp, string $userName = 'Reader', string $appName = 'EasyRead')
    {
        $this->otp      = $otp;
        $this->userName = $userName;
        $this->appName  = $appName;
    }

    public function build(): self
    {
        return $this
            ->subject("{$this->otp} is your {$this->appName} verification code")
            ->html($this->buildHtml());
    }

    private function buildHtml(): string
    {
        $otp     = e($this->otp);
        $name    = e($this->userName);
        $appName = e($this->appName);
        $year    = date('Y');

        return <<<HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{$appName} Verification Code</title>
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
      font-size: 15px;
      font-weight: 600;
      color: #212529;
      margin: 0 0 14px;
    }
    .paragraph {
      font-size: 14px;
      line-height: 1.6;
      color: #495057;
      margin: 0 0 24px;
    }
    .code-container {
      background-color: #F8F9FA;
      border: 1px solid #E2E8F0;
      border-radius: 8px;
      padding: 20px;
      text-align: center;
      margin: 24px 0;
    }
    .code-label {
      font-size: 11px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 1px;
      color: #6C757D;
      margin-bottom: 8px;
    }
    .code {
      font-family: 'SF Mono', SFMono-Regular, Consolas, 'Liberation Mono', Menlo, Courier, monospace;
      font-size: 32px;
      font-weight: 700;
      letter-spacing: 8px;
      color: #16241D;
      padding-left: 8px;
      margin: 0;
      line-height: 1.2;
    }
    .expiry-text {
      font-size: 12px;
      color: #6C757D;
      margin-top: 10px;
    }
    .security-note {
      font-size: 13px;
      line-height: 1.5;
      color: #6C757D;
      border-top: 1px solid #F1F3F5;
      padding-top: 20px;
      margin: 20px 0 0;
    }
    .footer {
      padding: 24px 32px 32px;
      background-color: #F8F9FA;
      border-top: 1px solid #E9ECEF;
      text-align: center;
    }
    .footer-text {
      font-size: 12px;
      color: #868E96;
      line-height: 1.5;
      margin: 0;
    }
    @media only screen and (max-width: 520px) {
      .wrapper { padding: 20px 10px; }
      .header { padding: 24px 20px 18px; }
      .body { padding: 24px 20px 20px; }
      .footer { padding: 20px 20px 24px; }
      .code { font-size: 26px; letter-spacing: 6px; }
    }
  </style>
</head>
<body>
  <div class="wrapper">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
      <tr>
        <td align="center">
          <table role="presentation" class="card" width="100%" cellpadding="0" cellspacing="0" style="max-width: 480px; background-color: #ffffff; border: 1px solid #e9ecef; border-radius: 12px;">
            
            <!-- Header -->
            <tr>
              <td style="padding: 28px 32px 20px; border-bottom: 1px solid #f1f3f5;">
                <span style="font-size: 20px; font-weight: 700; color: #16241D; letter-spacing: -0.3px;">
                  {$appName}
                </span>
              </td>
            </tr>

            <!-- Body -->
            <tr>
              <td style="padding: 28px 32px 24px;">
                <p style="font-size: 15px; font-weight: 600; color: #212529; margin: 0 0 12px;">
                  Password Reset Request
                </p>
                <p style="font-size: 14px; line-height: 1.6; color: #495057; margin: 0 0 20px;">
                  Hello {$name},
                </p>
                <p style="font-size: 14px; line-height: 1.6; color: #495057; margin: 0 0 20px;">
                  We received a request to reset the password for your {$appName} account. Enter the verification code below in the app to continue:
                </p>

                <!-- Code Container -->
                <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin: 20px 0 24px;">
                  <tr>
                    <td align="center" style="background-color: #F8F9FA; border: 1px solid #E2E8F0; border-radius: 8px; padding: 20px 16px;">
                      <div style="font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: 1px; color: #6C757D; margin-bottom: 8px;">
                        Verification Code
                      </div>
                      <div style="font-family: 'SF Mono', SFMono-Regular, Consolas, 'Liberation Mono', Menlo, Courier, monospace; font-size: 32px; font-weight: 700; letter-spacing: 8px; color: #16241D; padding-left: 8px; line-height: 1.1;">
                        {$otp}
                      </div>
                      <div style="font-size: 12px; color: #868E96; margin-top: 10px;">
                        Valid for 15 minutes
                      </div>
                    </td>
                  </tr>
                </table>

                <p style="font-size: 13px; line-height: 1.5; color: #6C757D; border-top: 1px solid #F1F3F5; padding-top: 18px; margin: 0;">
                  If you did not request this code, you can safely ignore this email. No changes will be made to your account.
                </p>
              </td>
            </tr>

            <!-- Footer -->
            <tr>
              <td align="center" style="padding: 20px 32px 24px; background-color: #F8F9FA; border-top: 1px solid #E9ECEF;">
                <p style="font-size: 12px; color: #868E96; line-height: 1.5; margin: 0;">
                  &copy; {$year} {$appName}. All rights reserved.<br>
                  This is an automated message. Please do not reply.
                </p>
              </td>
            </tr>

          </table>
        </td>
      </tr>
    </table>
  </div>
</body>
</html>
HTML;
    }
}
