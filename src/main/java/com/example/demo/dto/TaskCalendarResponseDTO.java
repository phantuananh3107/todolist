package com.example.demo.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class TaskCalendarResponseDTO {
    private LocalDate startDate;
    private LocalDate endDate;
    private List<TaskCalendarDayDTO> days;
}

