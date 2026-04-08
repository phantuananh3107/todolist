package com.example.demo.controller;

import java.time.LocalDate;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.dto.CreateTaskRequest;
import com.example.demo.dto.ReorderTaskRequest;
import com.example.demo.dto.UpdateTaskRequest;
import com.example.demo.service.TaskService;

@RestController
@RequestMapping("/api/tasks")
@PreAuthorize("isAuthenticated()") // Yêu cầu đăng nhập
public class TaskController {

    @Autowired
    private TaskService taskService;

    /**
     * Tạo công việc mới
     * POST /api/tasks
     */
    @PostMapping
    public ResponseEntity<?> createTask(@RequestBody CreateTaskRequest request) {
        return taskService.createTask(Long.parseLong(SecurityContextHolder.getContext().getAuthentication().getName()), request);
    }

    /**
     * Lấy danh sách công việc của user hiện tại
     * GET /api/tasks
     */
    @GetMapping
    public ResponseEntity<?> getTasks() {
        return taskService.getTasksByUserId(Long.parseLong(SecurityContextHolder.getContext().getAuthentication().getName()));
    }

    /**
     * Lấy chi tiết một công việc
     * GET /api/tasks/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> getTaskById(@PathVariable Long id) {
        return taskService.getTaskById(id, Long.parseLong(SecurityContextHolder.getContext().getAuthentication().getName()));
    }

    /**
     * Cập nhật công việc
     * PATCH /api/tasks/{id}
     */
    @PatchMapping("/{id}")
    public ResponseEntity<?> updateTask(
            @PathVariable Long id,
            @RequestBody UpdateTaskRequest request) {
        return taskService.updateTask(id, Long.parseLong(SecurityContextHolder.getContext().getAuthentication().getName()), request);
    }

    /**
     * Xóa công việc
     * DELETE /api/tasks/{id}
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteTask(@PathVariable Long id) {
        return taskService.deleteTask(id, Long.parseLong(SecurityContextHolder.getContext().getAuthentication().getName()));
    }

    /**
     * Tìm kiếm công việc
     * GET /api/tasks/search?keyword=...
     */
    @GetMapping("/search")
    public ResponseEntity<?> searchTasks(@RequestParam String keyword) {
        return taskService.searchTasks(keyword, Long.parseLong(SecurityContextHolder.getContext().getAuthentication().getName()));
    }

    /**
     * Lấy công việc theo trạng thái
     * GET /api/tasks/filter/status?status=TODO
     */
    @GetMapping("/filter/status")
    public ResponseEntity<?> getTasksByStatus(@RequestParam String status) {
        return taskService.getTasksByStatus(Long.parseLong(SecurityContextHolder.getContext().getAuthentication().getName()), status);
    }

    /**
     * Lấy công việc theo ưu tiên
     * GET /api/tasks/filter/priority?priority=HIGH
     */
    @GetMapping("/filter/priority")
    public ResponseEntity<?> getTasksByPriority(@RequestParam String priority) {
        return taskService.getTasksByPriority(Long.parseLong(SecurityContextHolder.getContext().getAuthentication().getName()), priority);
    }

    /**
     * Lấy công việc quá hạn
     * GET /api/tasks/overdue
     */
    @GetMapping("/overdue")
    public ResponseEntity<?> getOverdueTasks() {
        return taskService.getOverdueTasks(Long.parseLong(SecurityContextHolder.getContext().getAuthentication().getName()));
    }

    /**
     * Lấy công việc theo nhóm
     * GET /api/tasks/by-category/{categoryId}
     */
    @GetMapping("/by-category/{categoryId}")
    public ResponseEntity<?> getTasksByCategory(@PathVariable Long categoryId) {
        return taskService.getTasksByCategory(Long.parseLong(SecurityContextHolder.getContext().getAuthentication().getName()), categoryId);
    }

    /**
     * Lấy danh sách công việc được AI gợi ý sắp xếp
     * GET /api/tasks/ai-suggested-order
     */
    @GetMapping("/ai-suggested-order")
    public ResponseEntity<?> getAISuggestedOrder() {
        return taskService.getAISuggestedOrder(Long.parseLong(SecurityContextHolder.getContext().getAuthentication().getName()));
    }

    /**
     * Thống kê task cho màn hình chart
     * GET /api/tasks/stats?range=DAY|WEEK|MONTH&basis=DUE_DATE|CREATED_AT
     */
    @GetMapping("/stats")
    public ResponseEntity<?> getTaskStats(
            @RequestParam(defaultValue = "WEEK") String range,
            @RequestParam(defaultValue = "DUE_DATE") String basis) {
        return taskService.getTaskStats(Long.parseLong(SecurityContextHolder.getContext().getAuthentication().getName()), range, basis);
    }

    /**
     * Lấy công việc theo ngày
     * GET /api/tasks/by-date?date=yyyy-MM-dd
     */
    @GetMapping("/by-date")
    public ResponseEntity<?> getTasksByDate(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return taskService.getTasksByDate(Long.parseLong(SecurityContextHolder.getContext().getAuthentication().getName()), date);
    }

    /**
     * Calendar view theo tháng
     * GET /api/tasks/calendar?month=MM&year=YYYY
     */
    @GetMapping("/calendar")
    public ResponseEntity<?> getTasksCalendar(@RequestParam Integer month, @RequestParam Integer year) {
        LocalDate startDate = LocalDate.of(year, month, 1);
        LocalDate endDate = startDate.plusMonths(1).minusDays(1);
        return taskService.getTasksCalendar(Long.parseLong(SecurityContextHolder.getContext().getAuthentication().getName()), startDate, endDate);
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
        return taskService.searchTasksWithFilters(keyword, priority, status, Long.parseLong(SecurityContextHolder.getContext().getAuthentication().getName()));
    }

    /**
     * Sắp xếp lại thứ tự ưu tiên làm task
     * POST /api/tasks/reorder
     * 
     * Request body: {
     * "tasks": [
     * {"taskId": 3, "orderIndex": 1},
     * {"taskId": 1, "orderIndex": 2},
     * {"taskId": 2, "orderIndex": 3}
     * ]
     * }
     */
    @PostMapping("/reorder")
    public ResponseEntity<?> reorderTasks(@RequestBody ReorderTaskRequest request) {
        return taskService.reorderTasks(Long.parseLong(SecurityContextHolder.getContext().getAuthentication().getName()), request);
    }
}
