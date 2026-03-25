package com.example.demo.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestController
public class HealthController {

    // Root endpoint - công khai cho tất cả
    @GetMapping("/")
    public ResponseEntity<?> root() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "UP");
        response.put("message", "TodoApp Backend is running!");
        response.put("version", "1.0.0");
        response.put("timestamp", LocalDateTime.now());
        response.put("availableEndpoints", new String[]{
            "GET /api/health - Health check",
            "POST /api/users/register - Register new user",
            "POST /api/users/login - Login",
            "GET /api/users/profile/{id} - Get profile (need token)",
            "PATCH /api/users/profile/{id} - Update profile (need token)",
            "PATCH /api/users/change-password/{id} - Change password (need token)",
            "POST /api/users/logout - Logout (need token)",
            "POST /api/categories - Create category (need token)",
            "GET /api/categories - Get all categories (need token)",
            "PATCH /api/categories/{id} - Update category (need token)",
            "DELETE /api/categories/{id} - Delete category (need token)",
            "POST /api/tasks - Create task (need token)",
            "GET /api/tasks - Get all tasks (need token)",
            "PATCH /api/tasks/{id} - Update task (need token)",
            "DELETE /api/tasks/{id} - Delete task (need token)",
            "GET /api/tasks/search?keyword=... - Search tasks (need token)",
            "GET /api/tasks/filter/status?status=... - Filter by status (need token)",
            "GET /api/tasks/filter/priority?priority=... - Filter by priority (need token)",
            "GET /api/tasks/overdue - Get overdue tasks (need token)",
            "GET /api/tasks/by-category/{id} - Get tasks by category (need token)"
        });
        return ResponseEntity.ok(response);
    }

    @GetMapping("/api/health")
    public ResponseEntity<?> health() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "UP");
        response.put("message", "Backend is running!");
        response.put("timestamp", LocalDateTime.now());
        response.put("server", "http://localhost:9090");
        return ResponseEntity.ok(response);
    }
}

