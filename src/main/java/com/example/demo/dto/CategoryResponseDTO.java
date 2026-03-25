package com.example.demo.dto;

import com.example.demo.entity.Category;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class CategoryResponseDTO {
    private Long id;
    private String name;
    private Boolean isActive;
    private Long taskCount; // Số công việc trong nhóm này

    public CategoryResponseDTO(Category category) {
        this.id = category.getId();
        this.name = category.getName();
        this.isActive = category.getIsActive();
        this.taskCount = category.getTasks() != null ? (long) category.getTasks().size() : 0L;
    }
}

