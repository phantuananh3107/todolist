package com.example.demo.dto;

import lombok.*;
import java.util.List;

@Getter 
@Setter 
@NoArgsConstructor 
@AllArgsConstructor
public class ChatRequest {
    private List<ChatMessage> messages;
}
