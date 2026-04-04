package com.example.demo.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class StatsSummaryDTO {

    private long completed;
    private long notCompleted;
    /** Tỷ lệ hoàn thành (%), 2 chữ số thập phân */
    private double completionRate;
}
