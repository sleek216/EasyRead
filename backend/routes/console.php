<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use App\Models\Setting;
use App\Mail\OtpPasswordResetMail;
use Illuminate\Support\Facades\Mail;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Artisan::command('mail:send-otp {email} {otp} {name=Reader}', function ($email, $otp, $name) {
    $host       = Setting::get('smtp_host', '');
    $port       = (int)(Setting::get('smtp_port', '') ?: 587);
    $username   = Setting::get('smtp_username', '');
    $password   = Setting::get('smtp_password', '');
    $encryption = Setting::get('smtp_encryption', 'tls');
    $fromAddr   = Setting::get('smtp_from_address', Setting::get('support_email', env('MAIL_FROM_ADDRESS', 'noreply@easyread.com')));
    $fromName   = Setting::get('smtp_from_name', Setting::get('app_name', env('APP_NAME', 'EasyRead')));

    if (!empty($host) && !empty($username)) {
        config([
            'mail.default'                 => 'smtp',
            'mail.mailers.smtp.transport'  => 'smtp',
            'mail.mailers.smtp.host'       => $host,
            'mail.mailers.smtp.port'       => $port,
            'mail.mailers.smtp.username'   => $username,
            'mail.mailers.smtp.password'   => $password,
            'mail.mailers.smtp.encryption' => $encryption,
            'mail.mailers.smtp.scheme'     => null,
            'mail.from.address'            => $fromAddr,
            'mail.from.name'               => $fromName,
        ]);
    }

    $appName = Setting::get('app_name', 'EasyRead');
    try {
        Mail::to($email)->send(new OtpPasswordResetMail($otp, $name, $appName));
        $this->info("OTP sent to $email successfully.");
    } catch (\Exception $e) {
        \Log::error("Async OTP send failed for $email: " . $e->getMessage());
        $this->error($e->getMessage());
    }
})->purpose('Asynchronously send password reset OTP email via SMTP');

Artisan::command('mail:send-receipt {email} {name} {plan} {price?} {expires?}', function ($email, $name, $plan, $price = '', $expires = '') {
    $host       = Setting::get('smtp_host', '');
    $port       = (int)(Setting::get('smtp_port', '') ?: 587);
    $username   = Setting::get('smtp_username', '');
    $password   = Setting::get('smtp_password', '');
    $encryption = Setting::get('smtp_encryption', 'tls');
    $fromAddr   = Setting::get('smtp_from_address', Setting::get('support_email', env('MAIL_FROM_ADDRESS', 'noreply@easyread.com')));
    $fromName   = Setting::get('smtp_from_name', Setting::get('app_name', env('APP_NAME', 'EasyRead')));

    if (!empty($host) && !empty($username)) {
        config([
            'mail.default'                 => 'smtp',
            'mail.mailers.smtp.transport'  => 'smtp',
            'mail.mailers.smtp.host'       => $host,
            'mail.mailers.smtp.port'       => $port,
            'mail.mailers.smtp.username'   => $username,
            'mail.mailers.smtp.password'   => $password,
            'mail.mailers.smtp.encryption' => $encryption,
            'mail.mailers.smtp.scheme'     => null,
            'mail.from.address'            => $fromAddr,
            'mail.from.name'               => $fromName,
        ]);
    }

    $appName = Setting::get('app_name', 'EasyRead');
    try {
        Mail::to($email)->send(new \App\Mail\SubscriptionReceiptMail($name, $plan, $price, $expires, $appName));
        $this->info("Subscription receipt sent to $email.");
    } catch (\Exception $e) {
        \Log::error("Async receipt send failed for $email: " . $e->getMessage());
        $this->error($e->getMessage());
    }
})->purpose('Asynchronously send subscription purchase receipt email');

Artisan::command('mail:send-suspension {email} {name} {reason?}', function ($email, $name, $reason = '') {
    $host       = Setting::get('smtp_host', '');
    $port       = (int)(Setting::get('smtp_port', '') ?: 587);
    $username   = Setting::get('smtp_username', '');
    $password   = Setting::get('smtp_password', '');
    $encryption = Setting::get('smtp_encryption', 'tls');
    $fromAddr   = Setting::get('smtp_from_address', Setting::get('support_email', env('MAIL_FROM_ADDRESS', 'noreply@easyread.com')));
    $fromName   = Setting::get('smtp_from_name', Setting::get('app_name', env('APP_NAME', 'EasyRead')));

    if (!empty($host) && !empty($username)) {
        config([
            'mail.default'                 => 'smtp',
            'mail.mailers.smtp.transport'  => 'smtp',
            'mail.mailers.smtp.host'       => $host,
            'mail.mailers.smtp.port'       => $port,
            'mail.mailers.smtp.username'   => $username,
            'mail.mailers.smtp.password'   => $password,
            'mail.mailers.smtp.encryption' => $encryption,
            'mail.mailers.smtp.scheme'     => null,
            'mail.from.address'            => $fromAddr,
            'mail.from.name'               => $fromName,
        ]);
    }

    $appName = Setting::get('app_name', 'EasyRead');
    try {
        Mail::to($email)->send(new \App\Mail\AccountSuspendedMail($name, $reason, $appName));
        $this->info("Suspension notice sent to $email.");
    } catch (\Exception $e) {
        \Log::error("Async suspension notice send failed for $email: " . $e->getMessage());
        $this->error($e->getMessage());
    }
})->purpose('Asynchronously send account suspension notice email');

Artisan::command('mail:send-activation {email} {name}', function ($email, $name) {
    $host       = Setting::get('smtp_host', '');
    $port       = (int)(Setting::get('smtp_port', '') ?: 587);
    $username   = Setting::get('smtp_username', '');
    $password   = Setting::get('smtp_password', '');
    $encryption = Setting::get('smtp_encryption', 'tls');
    $fromAddr   = Setting::get('smtp_from_address', Setting::get('support_email', env('MAIL_FROM_ADDRESS', 'noreply@easyread.com')));
    $fromName   = Setting::get('smtp_from_name', Setting::get('app_name', env('APP_NAME', 'EasyRead')));

    if (!empty($host) && !empty($username)) {
        config([
            'mail.default'                 => 'smtp',
            'mail.mailers.smtp.transport'  => 'smtp',
            'mail.mailers.smtp.host'       => $host,
            'mail.mailers.smtp.port'       => $port,
            'mail.mailers.smtp.username'   => $username,
            'mail.mailers.smtp.password'   => $password,
            'mail.mailers.smtp.encryption' => $encryption,
            'mail.mailers.smtp.scheme'     => null,
            'mail.from.address'            => $fromAddr,
            'mail.from.name'               => $fromName,
        ]);
    }

    $appName = Setting::get('app_name', 'EasyRead');
    try {
        Mail::to($email)->send(new \App\Mail\AccountReactivatedMail($name, $appName));
        $this->info("Activation notice sent to $email.");
    } catch (\Exception $e) {
        \Log::error("Async activation notice send failed for $email: " . $e->getMessage());
        $this->error($e->getMessage());
    }
})->purpose('Asynchronously send account activation notice email');

