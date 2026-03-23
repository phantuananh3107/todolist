package com.example.demo.service;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

@Service
public class JwtService {

    @Value("${jwt.access.secret}")
    private String accessSecret;

    @Value("${jwt.refresh.secret}")
    private String refreshSecret;

    @Value("${jwt.expires.in}")
    private long accessExpiration;

    @Value("${jwt.refresh.expires.in}")
    private long refreshExpiration;

    public String generateAccessToken(String username) {
        return generateToken(username, accessSecret, accessExpiration);
    }

    public String generateRefreshToken(String username) {
        return generateToken(username, refreshSecret, refreshExpiration);
    }

    private String generateToken(String username, String secret, long expiration) {
        SecretKey key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        return Jwts.builder()
                .subject(username)
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + expiration))
                .signWith(key)
                .compact();
    }
}
