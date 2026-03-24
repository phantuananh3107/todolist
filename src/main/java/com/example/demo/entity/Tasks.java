package com.example.demo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "Tasks")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class Tasks {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Boolean isActive = true;

    @Column(nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Enumerated(EnumType.STRING)
    private Priority priority; // LOW, MEDIUM, HIGH [cite: 138]

    @Enumerated(EnumType.STRING)
    private Status status; // TODO, DOING, DONE, OVERDUE [cite: 138]

    private LocalDateTime dueDate; // Hạn hoàn thành [cite: 138]

    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user; // Người tạo task [cite: 138]

    @ManyToOne
    @JoinColumn(name = "Category_id")
    private Category category; // Thuộc nhóm nào [cite: 138]

    private LocalDateTime createdAt = LocalDateTime.now();

    @OneToMany(mappedBy = "task", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Reminder> reminders;

    public enum Priority { LOW, MEDIUM, HIGH }
    public enum Status { TODO, DOING, DONE, OVERDUE }
}