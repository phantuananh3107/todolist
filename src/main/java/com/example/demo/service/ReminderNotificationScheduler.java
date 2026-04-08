package com.example.demo.service;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import com.example.demo.entity.Notification;
import com.example.demo.entity.Reminder;
import com.example.demo.repository.NotificationRepository;
import com.example.demo.repository.ReminderRepository;

@Component
public class ReminderNotificationScheduler {

    @Autowired
    private ReminderRepository reminderRepository;

    @Autowired
    private NotificationRepository notificationRepository;

    @Autowired
    private PushNotificationService pushNotificationService;

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
            notification.setIsBanner(true);

            String title = reminder.getTask().getTitle();
            String description = reminder.getTask().getDescription();
            notification.setTaskTitle(title);
            notification.setTaskDescription(description);
            
            String message = (title == null || title.isBlank())
                    ? "Bạn có nhắc nhở công việc."
                    : "Nhắc nhở công việc: " + title;
            notification.setMessage(message);

            notificationRepository.save(notification);

            // Gửi push ra ngoài app (nếu user đã đăng ký FCM token)
            pushNotificationService.sendReminderNotification(reminder.getTask().getUser(), notification);

            // Đánh dấu đã gửi để tránh bắn trùng
            reminder.setNotifiedAt(now);
            reminderRepository.save(reminder);
        }
    }
}

