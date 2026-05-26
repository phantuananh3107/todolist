package com.example.demo.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CategorySuggestionsResponse {
    private List<CategorySuggestionDTO> suggestions;
    private String message;
}

