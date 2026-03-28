package com.example.demo.dto;

import com.example.demo.entity.Reminder;
import com.example.demo.entity.Tasks;
import lombok.*;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class TaskResponseDTO {
    private Long id;
    private String title;
    private String description;
    private String priority;          // Priority enum
    private String status;            // Status enum
    private LocalDateTime dueDate;
    private LocalDateTime createdAt;
    private Boolean isActive;
    private String categoryName;
    private Long categoryId;
    private String username;          // Người tạo task
    private List<LocalDateTime> reminderTimes; // Thời gian nhắc cho task (nếu có)

    public TaskResponseDTO(Tasks task) {
        this.id = task.getId();
        this.title = task.getTitle();
        this.description = task.getDescription();
        this.priority = task.getPriority() != null ? task.getPriority().toString() : null;
        this.status = task.getStatus() != null ? task.getStatus().toString() : null;
        this.dueDate = task.getDueDate();
        this.createdAt = task.getCreatedAt();
        this.isActive = task.getIsActive();
        this.categoryName = task.getCategory() != null ? task.getCategory().getName() : null;
        this.categoryId = task.getCategory() != null ? task.getCategory().getId() : null;
        this.username = task.getUser() != null ? task.getUser().getUsername() : null;
        this.reminderTimes = task.getReminders() == null ? null
                : task.getReminders().stream()
                .map(Reminder::getRemindTime)
                .filter(t -> t != null)
                .sorted(Comparator.naturalOrder())
                .toList();
    }
}

