package com.example.demo.dto;

import com.example.demo.entity.Reminder;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
public class ReminderResponseDTO {
    private Long id;
    private Long taskId;
    private String taskTitle;
    private LocalDateTime remindTime;
    private LocalDateTime taskDueDate;

    public ReminderResponseDTO(Reminder reminder) {
        this.id = reminder.getId();
        this.remindTime = reminder.getRemindTime();
        if (reminder.getTask() != null) {
            this.taskId = reminder.getTask().getId();
            this.taskTitle = reminder.getTask().getTitle();
            this.taskDueDate = reminder.getTask().getDueDate();
        }
    }
}

