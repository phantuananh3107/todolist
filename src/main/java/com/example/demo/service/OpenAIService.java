package com.example.demo.service;

import com.example.demo.dto.ChatMessage;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.*;

@Service
public class OpenAIService {

    @Value("${openai.api.key}")
    private String apiKey;

    @Value("${openai.model}")
    private String model;

    private final String API_URL = "https://api.openai.com/v1/chat/completions";
    private final RestTemplate restTemplate = new RestTemplate();

    /**
     * Gửi prompt đến OpenAI và nhận phản hồi (cho các chức năng đơn lẻ).
     */
    public String getResponseFromAI(String prompt) {
        ChatMessage message = new ChatMessage("user", prompt);
        return getChatResponse(List.of(message), "Bạn là một trợ lý AI giúp người dùng quản lý công việc.");
    }

    /**
     * Gửi danh sách tin nhắn chat đến OpenAI và nhận phản hồi.
     */
    public String getChatResponse(List<ChatMessage> conversation, String systemInstruction) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        String key = apiKey != null ? apiKey : "";
        headers.setBearerAuth(key);

        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("model", model);
        
        List<Map<String, String>> messages = new ArrayList<>();
        // Thêm chỉ dẫn hệ thống vào đầu nếu có
        if (systemInstruction != null && !systemInstruction.isEmpty()) {
            messages.add(Map.of("role", "system", "content", systemInstruction));
        }

        for (ChatMessage msg : conversation) {
            messages.add(Map.of("role", msg.getRole(), "content", msg.getContent()));
        }
        
        requestBody.put("messages", messages);
        requestBody.put("temperature", 0.7);

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> response = restTemplate.postForObject(API_URL, entity, Map.class);
            if (response != null && response.containsKey("choices")) {
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> choices = (List<Map<String, Object>>) response.get("choices");
                if (choices != null && !choices.isEmpty()) {
                    @SuppressWarnings("unchecked")
                    Map<String, Object> message = (Map<String, Object>) choices.get(0).get("message");
                    if (message != null) {
                        return (String) message.get("content");
                    }
                }
            }
        } catch (Exception e) {
            return "Lỗi chatbot: " + e.getMessage();
        }
        return null;
    }
}
