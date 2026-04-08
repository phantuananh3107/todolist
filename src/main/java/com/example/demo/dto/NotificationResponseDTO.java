package com.example.demo.dto;

import java.time.LocalDateTime;

import com.example.demo.entity.Notification;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class NotificationResponseDTO {
    private Long id;
    private Long taskId;
    private Long reminderId;
    private String taskTitle;
    private String taskDescription;
    private String message;
    private LocalDateTime remindTime;
    private LocalDateTime createdAt;
    private LocalDateTime readAt;
    private Boolean isRead;
    private Boolean isBanner;

    public NotificationResponseDTO(Notification notification) {
        this.id = notification.getId();
        this.taskId = notification.getTaskId();
        this.reminderId = notification.getReminderId();
        this.taskTitle = notification.getTaskTitle();
        this.taskDescription = notification.getTaskDescription();
        this.message = notification.getMessage();
        this.remindTime = notification.getRemindTime();
        this.createdAt = notification.getCreatedAt();
        this.readAt = notification.getReadAt();
        this.isRead = notification.getReadAt() != null;
        this.isBanner = Boolean.TRUE.equals(notification.getIsBanner());
    }
}

