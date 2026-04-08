package com.example.demo.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.dto.SnoozeRequestDTO;
import com.example.demo.service.NotificationService;

@RestController
@RequestMapping("/api/notifications")
@PreAuthorize("isAuthenticated()")
public class NotificationController {

    @Autowired
    private NotificationService notificationService;

    @GetMapping("/unread")
    public ResponseEntity<?> getUnread() {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return notificationService.getUnread(Long.parseLong(userId));
    }

    @GetMapping
    public ResponseEntity<?> getAll() {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return notificationService.getAll(Long.parseLong(userId));
    }

    @PatchMapping("/{id}/read")
    public ResponseEntity<?> markRead(@PathVariable("id") Long notificationId) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return notificationService.markRead(Long.parseLong(userId), notificationId);
    }

    @PatchMapping("/{id}/snooze")
    public ResponseEntity<?> snoozeNotification(
            @PathVariable("id") Long notificationId,
            @RequestBody SnoozeRequestDTO request) {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return notificationService.snoozeNotification(Long.parseLong(userId), notificationId, request);
    }
}

