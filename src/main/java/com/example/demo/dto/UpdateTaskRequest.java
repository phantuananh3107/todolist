package com.example.demo.dto;

import lombok.*;
import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class UpdateTaskRequest {
    private String title;
    private String description;
    private String priority;           // LOW, MEDIUM, HIGH
    private String status;             // TODO, DOING, DONE, OVERDUE
    private LocalDateTime dueDate;
    private Long categoryId;
}

