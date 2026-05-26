package com.example.demo.entity;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "Reminder")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class Reminder {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "task_id")
    private Tasks task; // Nhắc cho công việc nào [cite: 142]

    // Cột DB hiện tại là remind_time (NOT NULL)
    @Column(name = "remind_time", nullable = false)
    private LocalDateTime remindTime; // Thời gian sẽ thông báo [cite: 142]

    // Tương thích schema cũ vẫn còn cột reminder_time NOT NULL
    @Column(name = "reminder_time", nullable = false)
    private LocalDateTime legacyReminderTime;

    // Dùng để tránh bắn notification trùng (scheduler sẽ set khi đã gửi)
    private LocalDateTime notifiedAt;

    @PrePersist
    @PreUpdate
    private void syncReminderTimeColumns() {
        if (this.remindTime != null) {
            this.legacyReminderTime = this.remindTime;
        }
    }
}