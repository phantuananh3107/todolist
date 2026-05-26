package com.example.demo.dto;

import com.example.demo.entity.Notification;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
public class NotificationResponseDTO {
    private Long id;
    private Long taskId;
    private Long reminderId;
    private String message;
    private LocalDateTime remindTime;
    private LocalDateTime createdAt;
    private LocalDateTime readAt;
    private Boolean isRead;

    public NotificationResponseDTO(Notification notification) {
        this.id = notification.getId();
        this.taskId = notification.getTaskId();
        this.reminderId = notification.getReminderId();
        this.message = notification.getMessage();
        this.remindTime = notification.getRemindTime();
        this.createdAt = notification.getCreatedAt();
        this.readAt = notification.getReadAt();
        this.isRead = notification.getReadAt() != null;
    }
}

