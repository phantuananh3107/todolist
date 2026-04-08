package com.example.demo.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class SnoozeRequestDTO {
    /**
     * Thời gian snooze theo phút
     * Ví dụ: 5 (5 phút), 60 (1 giờ), 120 (2 giờ)
     */
    private Integer snoozeMinutes;
}
