package com.example.demo.service;

import java.io.ByteArrayInputStream;
import java.io.FileInputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.example.demo.entity.Notification;
import com.example.demo.entity.User;
import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;

@Service
public class PushNotificationService {

    private static final Logger log = LoggerFactory.getLogger(PushNotificationService.class);

    @Value("${fcm.enabled:false}")
    private boolean fcmEnabled;

    @Value("${fcm.service-account-file:}")
    private String serviceAccountFile;

    @Value("${fcm.service-account-json:}")
    private String serviceAccountJson;

    private volatile boolean initialized = false;
    private volatile boolean attemptedInit = false;

    private synchronized void ensureInitialized() {
        if (!fcmEnabled || initialized || attemptedInit) {
            return;
        }

        attemptedInit = true;

        try {
            GoogleCredentials credentials = resolveCredentials();
            if (credentials == null) {
                log.warn("FCM enabled nhưng chưa có credentials. Bỏ qua gửi push notification.");
                return;
            }

            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(credentials)
                        .build();
                FirebaseApp.initializeApp(options);
            }

            initialized = true;
            log.info("FCM initialized thành công.");
        } catch (Exception ex) {
            log.error("Không thể khởi tạo FCM: {}", ex.getMessage());
        }
    }

    private GoogleCredentials resolveCredentials() throws Exception {
        if (serviceAccountJson != null && !serviceAccountJson.isBlank()) {
            try (InputStream is = new ByteArrayInputStream(serviceAccountJson.getBytes(StandardCharsets.UTF_8))) {
                return GoogleCredentials.fromStream(is);
            }
        }

        if (serviceAccountFile != null && !serviceAccountFile.isBlank()) {
            try (InputStream is = new FileInputStream(serviceAccountFile.trim())) {
                return GoogleCredentials.fromStream(is);
            }
        }

        return null;
    }

    public boolean sendReminderNotification(User user, Notification notification) {
        if (!fcmEnabled || user == null || notification == null) {
            return false;
        }

        if (!Boolean.TRUE.equals(user.getPushEnabled())) {
            return false;
        }

        String token = user.getFcmToken();
        if (token == null || token.isBlank()) {
            return false;
        }

        ensureInitialized();
        if (!initialized) {
            return false;
        }

        String title = (notification.getTaskTitle() == null || notification.getTaskTitle().isBlank())
                ? "Nhắc việc"
                : "Nhắc việc: " + notification.getTaskTitle();
        String body = notification.getMessage() == null ? "Bạn có một nhắc việc mới." : notification.getMessage();

        Message message = Message.builder()
                .setToken(token)
                .setNotification(com.google.firebase.messaging.Notification.builder()
                        .setTitle(title)
                        .setBody(body)
                        .build())
                .putData("type", "reminder")
                .putData("notificationId", String.valueOf(notification.getId()))
                .putData("taskId", String.valueOf(notification.getTaskId()))
                .putData("reminderId", String.valueOf(notification.getReminderId()))
                .build();

        try {
            FirebaseMessaging.getInstance().send(message);
            return true;
        } catch (FirebaseMessagingException ex) {
            log.warn("Gửi push thất bại cho userId={}: {}", user.getId(), ex.getMessage());
            return false;
        }
    }
}
