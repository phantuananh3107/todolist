package com.example.demo.service;

import com.example.demo.entity.Notification;
import com.example.demo.entity.Reminder;
import com.example.demo.repository.NotificationRepository;
import com.example.demo.repository.ReminderRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;
import org.springframework.transaction.annotation.Transactional;

@Component
public class ReminderNotificationScheduler {

    @Autowired
    private ReminderRepository reminderRepository;

    @Autowired
    private NotificationRepository notificationRepository;

    /**
     * Chạy định kỳ để tạo in-app notification khi Reminder đến giờ.
     * Default fixedDelay = 10s để FE nhận trong thời gian gần đúng.
     */
    @Transactional
    @Scheduled(fixedDelay = 10000)
    public void sendDueNotifications() {
        LocalDateTime now = LocalDateTime.now();
        List<Reminder> dueReminders = reminderRepository.findDueReminders(now);
        if (dueReminders == null || dueReminders.isEmpty()) {
            return;
        }

        for (Reminder reminder : dueReminders) {
            if (reminder.getTask() == null || reminder.getTask().getUser() == null) {
                continue;
            }

            Notification notification = new Notification();
            notification.setUserId(reminder.getTask().getUser().getId());
            notification.setTaskId(reminder.getTask().getId());
            notification.setReminderId(reminder.getId());
            notification.setRemindTime(reminder.getRemindTime());

            String title = reminder.getTask().getTitle();
            String message = (title == null || title.isBlank())
                    ? "Bạn có nhắc nhở công việc."
                    : "Nhắc nhở công việc: " + title;
            notification.setMessage(message);

            notificationRepository.save(notification);

            // Đánh dấu đã gửi để tránh bắn trùng
            reminder.setNotifiedAt(now);
            reminderRepository.save(reminder);
        }
    }
}

