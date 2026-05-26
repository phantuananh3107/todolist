package com.example.demo.controller;

import org.springframework.beans.factory.annotation.Autowired;
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

import com.example.demo.dto.CreateReminderRequest;
import com.example.demo.dto.UpdateReminderRequest;
import com.example.demo.service.ReminderService;

@RestController
@RequestMapping("/api/reminders")
@PreAuthorize("isAuthenticated()")
public class ReminderController {

    @Autowired
    private ReminderService reminderService;

    /**
     * Tạo nhắc việc (body chứa taskId)
     * POST /api/reminders
     */
    @PostMapping
    public ResponseEntity<?> createReminder(@RequestBody CreateReminderRequest request) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return reminderService.createReminder(Long.parseLong(userId), request);
    }

    /**
     * Tạo nhắc việc cho một công việc
     * POST /api/reminders/task/{taskId}
     */
    @PostMapping("/task/{taskId}")
    public ResponseEntity<?> createReminderByTaskId(@PathVariable Long taskId, @RequestBody CreateReminderRequest request) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        request.setTaskId(taskId);
        return reminderService.createReminder(Long.parseLong(userId), request);
    }

    /**
     * Cập nhật nhắc việc
     * PATCH /api/reminders/{id}
     */
    @PatchMapping("/{id}")
    public ResponseEntity<?> updateReminder(@PathVariable Long id, @RequestBody UpdateReminderRequest request) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return reminderService.updateReminder(Long.parseLong(userId), id, request);
    }

    /**
     * Xóa nhắc việc
     * DELETE /api/reminders/{id}
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteReminder(@PathVariable Long id) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return reminderService.deleteReminder(Long.parseLong(userId), id);
    }

    /**
     * Lấy danh sách nhắc việc của user hiện tại
     * GET /api/reminders
     */
    @GetMapping
    public ResponseEntity<?> getRemindersByUser() {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return reminderService.getRemindersByUser(Long.parseLong(userId));
    }

    /**
     * Lấy danh sách nhắc việc sắp đến trong X phút
     * GET /api/reminders/upcoming?minutes=30
     */
    @GetMapping("/upcoming")
    public ResponseEntity<?> getUpcomingReminders(@RequestParam Integer minutes) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return reminderService.getUpcomingReminders(Long.parseLong(userId), minutes);
    }
}