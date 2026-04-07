package com.example.demo.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CategorySuggestionDTO {
    private Long categoryId;
    private String categoryName;
    private Double matchPercentage;
    private String reason;
}

