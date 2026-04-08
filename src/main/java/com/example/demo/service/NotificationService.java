package com.example.demo.service;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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

    public ResponseEntity<?> acknowledgeNotification(Long userId, Long notificationId) {
        if (notificationId == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("notificationId không hợp lệ!");
        }

        Optional<Notification> opt = notificationRepository.findByIdAndUserId(notificationId, userId);
        if (opt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Notification không tồn tại!");
        }

        Notification selected = opt.get();
        int markedCount = markReminderNotificationsRead(userId, selected);

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("message", "Đã ghi nhận: tôi đã nhớ rồi.");
        response.put("notification", new NotificationResponseDTO(selected));
        response.put("reminderId", selected.getReminderId());
        response.put("markedReadCount", markedCount);
        return ResponseEntity.ok(response);
    }

    @Transactional
    public ResponseEntity<?> snoozeNotification(Long userId, Long notificationId, SnoozeRequestDTO request) {
        if (notificationId == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("notificationId không hợp lệ!");
        }

        if (request == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Thiếu dữ liệu snooze!");
        }

        Integer snoozeMinutes = resolveSnoozeMinutes(request);
        if (snoozeMinutes == null || snoozeMinutes <= 0) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body("Snooze không hợp lệ! Dùng snoozeMinutes hoặc { value > 0, unit = MINUTES|HOURS|DAYS }.");
        }

        Optional<Notification> opt = notificationRepository.findByIdAndUserId(notificationId, userId);
        if (opt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Notification không tồn tại!");
        }

        Notification notification = opt.get();
        int markedCount = markReminderNotificationsRead(userId, notification);
        
        // Lấy reminder cũ
        Optional<Reminder> reminderOpt = reminderRepository.findById(notification.getReminderId());
        if (reminderOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Reminder không tồn tại!");
        }

        Reminder oldReminder = reminderOpt.get();

        // Tạo reminder mới với thời gian snooze
        Reminder newReminder = new Reminder();
        newReminder.setTask(oldReminder.getTask());
        LocalDateTime snoozeTime = LocalDateTime.now().plusMinutes(snoozeMinutes);
        newReminder.setRemindTime(snoozeTime);
        newReminder.setLegacyReminderTime(snoozeTime);
        reminderRepository.save(newReminder);

        // Xóa reminder hiện tại, chỉ giữ reminder mới theo thời gian user chọn.
        reminderRepository.delete(oldReminder);

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("message", "Snooze thành công!");
        response.put("nextRemindTime", snoozeTime);
        response.put("snoozedMinutes", snoozeMinutes);
        response.put("previousNotification", new NotificationResponseDTO(notification));
        response.put("deletedReminderId", oldReminder.getId());
        response.put("newReminderId", newReminder.getId());
        response.put("markedReadCount", markedCount);

        return ResponseEntity.ok(response);
    }

    private int markReminderNotificationsRead(Long userId, Notification selected) {
        LocalDateTime now = LocalDateTime.now();
        int markedCount = 0;

        if (selected.getReadAt() == null) {
            selected.setReadAt(now);
            notificationRepository.save(selected);
            markedCount++;
        }

        Long reminderId = selected.getReminderId();
        if (reminderId == null) {
            return markedCount;
        }

        List<Notification> sameReminderUnread = notificationRepository
                .findByUserIdAndReminderIdAndReadAtIsNull(userId, reminderId);

        if (!sameReminderUnread.isEmpty()) {
            for (Notification item : sameReminderUnread) {
                item.setReadAt(now);
            }
            notificationRepository.saveAll(sameReminderUnread);
            markedCount += sameReminderUnread.size();
        }

        return markedCount;
    }

    private Integer resolveSnoozeMinutes(SnoozeRequestDTO request) {
        if (request.getSnoozeMinutes() != null) {
            return request.getSnoozeMinutes();
        }

        if (request.getValue() == null || request.getValue() <= 0 || request.getUnit() == null) {
            return null;
        }

        ChronoUnit unit;
        try {
            unit = ChronoUnit.valueOf(request.getUnit().trim().toUpperCase());
        } catch (IllegalArgumentException ex) {
            return null;
        }

        return switch (unit) {
            case MINUTES -> request.getValue();
            case HOURS -> request.getValue() * 60;
            case DAYS -> request.getValue() * 24 * 60;
            default -> null;
        };
    }
}

