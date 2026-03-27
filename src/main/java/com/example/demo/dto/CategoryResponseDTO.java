package com.example.demo.dto;

import com.example.demo.entity.Category;
import lombok.*;
import java.util.List;
import java.util.stream.Collectors;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class CategoryResponseDTO {
    private Long id;
    private String name;
    private Boolean isActive;
    private Long taskCount;
    private List<TaskResponseDTO> tasks;

    public CategoryResponseDTO(Category category) {
        this.id = category.getId();
        this.name = category.getName();
        this.isActive = category.getIsActive();
        
        // Lọc các task chưa xoá (isActive = true)
        if (category.getTasks() != null) {
            this.tasks = category.getTasks().stream()
                    .filter(t -> t.getIsActive() != null && t.getIsActive())
                    .map(TaskResponseDTO::new)
                    .collect(Collectors.toList());
            this.taskCount = (long) this.tasks.size();
        } else {
            this.taskCount = 0L;
        }
    }
}
