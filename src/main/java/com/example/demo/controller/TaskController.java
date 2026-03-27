package com.example.demo.controller;

import com.example.demo.dto.CreateTaskRequest;
import com.example.demo.dto.UpdateTaskRequest;
import com.example.demo.service.TaskService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/tasks")
@PreAuthorize("isAuthenticated()")  // Yêu cầu đăng nhập
public class TaskController {

    @Autowired
    private TaskService taskService;

    /**
     * Tạo công việc mới
     * POST /api/tasks
     */
    @PostMapping
    public ResponseEntity<?> createTask(@RequestBody CreateTaskRequest request) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return taskService.createTask(Long.parseLong(userId), request);
    }

    /**
     * Lấy danh sách công việc của user hiện tại
     * GET /api/tasks
     */
    @GetMapping
    public ResponseEntity<?> getTasks() {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return taskService.getTasksByUserId(Long.parseLong(userId));
    }

    /**
     * Lấy chi tiết một công việc
     * GET /api/tasks/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> getTaskById(@PathVariable Long id) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return taskService.getTaskById(id, Long.parseLong(userId));
    }

    /**
     * Cập nhật công việc
     * PATCH /api/tasks/{id}
     */
    @PatchMapping("/{id}")
    public ResponseEntity<?> updateTask(
            @PathVariable Long id,
            @RequestBody UpdateTaskRequest request) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return taskService.updateTask(id, Long.parseLong(userId), request);
    }

    /**
     * Xóa công việc
     * DELETE /api/tasks/{id}
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteTask(@PathVariable Long id) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return taskService.deleteTask(id, Long.parseLong(userId));
    }

    /**
     * Tìm kiếm công việc
     * GET /api/tasks/search?keyword=...
     */
    @GetMapping("/search")
    public ResponseEntity<?> searchTasks(@RequestParam String keyword) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return taskService.searchTasks(keyword, Long.parseLong(userId));
    }

    /**
     * Lấy công việc theo trạng thái
     * GET /api/tasks/filter/status?status=TODO
     */
    @GetMapping("/filter/status")
    public ResponseEntity<?> getTasksByStatus(@RequestParam String status) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return taskService.getTasksByStatus(Long.parseLong(userId), status);
    }

    /**
     * Lấy công việc theo ưu tiên
     * GET /api/tasks/filter/priority?priority=HIGH
     */
    @GetMapping("/filter/priority")
    public ResponseEntity<?> getTasksByPriority(@RequestParam String priority) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return taskService.getTasksByPriority(Long.parseLong(userId), priority);
    }

    /**
     * Lấy công việc quá hạn
     * GET /api/tasks/overdue
     */
    @GetMapping("/overdue")
    public ResponseEntity<?> getOverdueTasks() {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return taskService.getOverdueTasks(Long.parseLong(userId));
    }

    /**
     * Lấy công việc theo nhóm
     * GET /api/tasks/by-category/{categoryId}
     */
    @GetMapping("/by-category/{categoryId}")
    public ResponseEntity<?> getTasksByCategory(@PathVariable Long categoryId) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return taskService.getTasksByCategory(Long.parseLong(userId), categoryId);
    }

    /**
     * Lấy danh sách công việc được AI gợi ý sắp xếp
     * GET /api/tasks/ai-suggested-order
     */
    @GetMapping("/ai-suggested-order")
    public ResponseEntity<?> getAISuggestedOrder() {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return taskService.getAISuggestedOrder(Long.parseLong(userId));
    }

    /**
     * Tìm kiếm công việc với filter (keyword, priority, status)
     * GET /api/tasks/advanced-search?keyword=...&priority=HIGH&status=TODO
     */
    @GetMapping("/advanced-search")
    public ResponseEntity<?> advancedSearchTasks(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String priority,
            @RequestParam(required = false) String status) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return taskService.searchTasksWithFilters(keyword, priority, status, Long.parseLong(userId));
    }
}

