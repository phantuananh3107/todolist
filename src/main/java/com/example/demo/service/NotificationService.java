package com.example.demo.service;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import com.example.demo.dto.NotificationResponseDTO;
import com.example.demo.dto.SnoozeRequestDTO;
import com.example.demo.entity.Notification;
import com.example.demo.entity.Reminder;
import com.example.demo.repository.NotificationRepository;
import com.example.demo.repository.ReminderRepository;

@Service
public class NotificationService {

    @Autowired
    private NotificationRepository notificationRepository;

    @Autowired
    private ReminderRepository reminderRepository;

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

    public ResponseEntity<?> snoozeNotification(Long userId, Long notificationId, SnoozeRequestDTO request) {
        if (notificationId == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("notificationId không hợp lệ!");
        }

        if (request.getSnoozeMinutes() == null || request.getSnoozeMinutes() <= 0) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("snoozeMinutes phải lớn hơn 0!");
        }

        Optional<Notification> opt = notificationRepository.findByIdAndUserId(notificationId, userId);
        if (opt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Notification không tồn tại!");
        }

        Notification notification = opt.get();
        
        // Lấy reminder cũ
        Optional<Reminder> reminderOpt = reminderRepository.findById(notification.getReminderId());
        if (reminderOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Reminder không tồn tại!");
        }

        Reminder oldReminder = reminderOpt.get();

        // Tạo reminder mới với thời gian snooze
        Reminder newReminder = new Reminder();
        newReminder.setTask(oldReminder.getTask());
        LocalDateTime snoozeTime = LocalDateTime.now().plusMinutes(request.getSnoozeMinutes());
        newReminder.setRemindTime(snoozeTime);
        newReminder.setLegacyReminderTime(snoozeTime);
        reminderRepository.save(newReminder);

        // Đánh dấu notification cũ là đã đọc
        notification.setReadAt(LocalDateTime.now());
        notificationRepository.save(notification);

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("message", "Snooze thành công!");
        response.put("nextRemindTime", snoozeTime);
        response.put("snoozedMinutes", request.getSnoozeMinutes());
        response.put("previousNotification", new NotificationResponseDTO(notification));
        response.put("newReminderId", newReminder.getId());

        return ResponseEntity.ok(response);
    }
}

