package com.example.demo.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class TaskStatsResponseDTO {
    private String range;
    private String basis;
    private LocalDateTime from;
    private LocalDateTime to;
    private long total;
    private long todo;
    private long doing;
    private long done;
    private long overdue;
    private long incomplete;
    private double completionRate;
}
