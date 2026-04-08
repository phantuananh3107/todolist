package com.example.demo.entity;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "Notification")
@Getter
@Setter
@NoArgsConstructor
public class Notification {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Lưu theo ID để giảm phụ thuộc quan hệ entity
    @Column(nullable = false)
    private Long userId;

    @Column(nullable = false)
    private Long taskId;

    @Column(nullable = false)
    private Long reminderId;

    @Column(nullable = false)
    private String taskTitle;

    @Column(columnDefinition = "TEXT")
    private String taskDescription;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String message;

    @Column(nullable = false)
    private LocalDateTime remindTime;

    @Column(columnDefinition = "BOOLEAN DEFAULT 0")
    private Boolean isBanner = false;

    private LocalDateTime createdAt = LocalDateTime.now();

    private LocalDateTime readAt;
}

