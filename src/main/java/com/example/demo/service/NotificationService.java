package com.example.demo.service;

import com.example.demo.dto.NotificationResponseDTO;
import com.example.demo.entity.Notification;
import com.example.demo.repository.NotificationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class NotificationService {

    @Autowired
    private NotificationRepository notificationRepository;

    public ResponseEntity<?> getUnread(Long userId) {
        List<Notification> notifications = notificationRepository
                .findByUserIdAndReadAtIsNullOrderByCreatedAtDesc(userId);
        return ResponseEntity.ok(notifications.stream()
                .map(NotificationResponseDTO::new)
                .toList());
    }

    public ResponseEntity<?> getAll(Long userId) {
        List<Notification> notifications = notificationRepository
                .findByUserIdOrderByCreatedAtDesc(userId);
        return ResponseEntity.ok(notifications.stream()
                .map(NotificationResponseDTO::new)
                .toList());
    }

    public ResponseEntity<?> markRead(Long userId, Long notificationId) {
        if (notificationId == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("notificationId không hợp lệ!");
        }

        Optional<Notification> opt = notificationRepository.findByIdAndUserId(notificationId, userId);
        if (opt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Notification không tồn tại!");
        }

        Notification notification = opt.get();
        if (notification.getReadAt() == null) {
            notification.setReadAt(LocalDateTime.now());
            notificationRepository.save(notification);
        }

        return ResponseEntity.ok(new NotificationResponseDTO(notification));
    }
}

