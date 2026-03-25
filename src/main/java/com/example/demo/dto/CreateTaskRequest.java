package com.example.demo.dto;

import lombok.*;
import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class CreateTaskRequest {
    private String title;              // Tiêu đề công việc
    private String description;        // Mô tả chi tiết
    private String priority;           // LOW, MEDIUM, HIGH
    private String status;             // TODO, DOING, DONE, OVERDUE
    private LocalDateTime dueDate;     // Hạn hoàn thành
    private Long categoryId;           // ID của nhóm công việc
}

