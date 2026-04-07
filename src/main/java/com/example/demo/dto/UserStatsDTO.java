package com.example.demo.dto;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class UserStatsDTO {
    private String username;
    private Long totalTasks;
    private Long completedTasks;
    private Long pendingTasks;
}
