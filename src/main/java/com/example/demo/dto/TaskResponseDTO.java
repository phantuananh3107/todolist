package com.example.demo.dto;

import com.example.demo.entity.Tasks;
import lombok.*;
import java.time.LocalDateTime;

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
    private Integer orderIndex;       // Thứ tự ưu tiên làm task

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
        this.orderIndex = task.getOrderIndex();
    }
}

