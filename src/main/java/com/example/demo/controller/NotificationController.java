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
        return notificationService.getUnread(
                Long.parseLong(SecurityContextHolder.getContext().getAuthentication().getName()));
    }

    @GetMapping
    public ResponseEntity<?> getAll() {
        return notificationService.getAll(
                Long.parseLong(SecurityContextHolder.getContext().getAuthentication().getName()));
    }

    @PatchMapping("/{id}/read")
    public ResponseEntity<?> markRead(@PathVariable("id") Long notificationId) {
        return notificationService.markRead(
                Long.parseLong(SecurityContextHolder.getContext().getAuthentication().getName()),
                notificationId);
    }

    @PatchMapping("/{id}/acknowledge")
    public ResponseEntity<?> acknowledgeNotification(@PathVariable("id") Long notificationId) {
        return notificationService.acknowledgeNotification(
                Long.parseLong(SecurityContextHolder.getContext().getAuthentication().getName()),
                notificationId);
    }

    @PatchMapping("/{id}/snooze")
    public ResponseEntity<?> snoozeNotification(
            @PathVariable("id") Long notificationId,
            @RequestBody SnoozeRequestDTO request) {
        return notificationService.snoozeNotification(
                Long.parseLong(SecurityContextHolder.getContext().getAuthentication().getName()),
                notificationId,
                request);
    }
}

