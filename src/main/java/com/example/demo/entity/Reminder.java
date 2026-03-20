package com.example.demo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

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

    @Column(nullable = false)
    private LocalDateTime remindTime; // Thời gian sẽ thông báo [cite: 142]
}