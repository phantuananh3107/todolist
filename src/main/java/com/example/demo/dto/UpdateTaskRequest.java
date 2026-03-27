package com.example.demo.dto;

import com.example.demo.entity.Tasks.Priority;
import com.example.demo.entity.Tasks.Status;
import lombok.*;
import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class UpdateTaskRequest {
    private String title;
    private String description;
    private Priority priority;         // LOW, MEDIUM, HIGH
    private Status status;             // TODO, DOING, DONE, OVERDUE
    private LocalDateTime dueDate;
    private Long categoryId;
}

