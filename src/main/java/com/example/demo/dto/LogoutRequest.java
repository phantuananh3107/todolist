package com.example.demo.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class LogoutRequest {
    private String refreshToken;

    public LogoutRequest() {}
    public LogoutRequest(String refreshToken) {
        this.refreshToken = refreshToken;
    }
}
