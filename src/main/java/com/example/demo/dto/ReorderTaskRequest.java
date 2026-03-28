package com.example.demo.dto;

import lombok.*;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class ReorderTaskRequest {
    /**
     * List các task với order mới
     * Ví dụ: [
     *   {"taskId": 3, "orderIndex": 1},
     *   {"taskId": 1, "orderIndex": 2},
     *   {"taskId": 2, "orderIndex": 3}
     * ]
     */
    private List<TaskOrderItem> tasks;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class TaskOrderItem {
        private Long taskId;
        private Integer orderIndex;
    }
}
