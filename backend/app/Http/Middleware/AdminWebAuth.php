<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class AdminWebAuth
{
    /**
     * Handle an incoming request for Admin Panel web routes.
     */
    public function handle(Request $request, Closure $next): Response
    {
        if (!Auth::check()) {
            return redirect()->guest(route('admin.login'));
        }

        $user = Auth::user();

        if ($user->role !== 'admin' || !$user->is_active) {
            Auth::logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();

            return redirect()->route('admin.login')
                ->withErrors(['email' => 'Access Denied: Only active administrator accounts can access this console.']);
        }

        return $next($request);
    }
}
