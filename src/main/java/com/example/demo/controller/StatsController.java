package com.example.demo.controller;

import com.example.demo.dto.StatsBucketDTO;
import com.example.demo.dto.StatsSummaryDTO;
import com.example.demo.service.StatsService;
import java.time.LocalDate;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/stats")
@PreAuthorize("isAuthenticated()")
public class StatsController {

    @Autowired
    private StatsService statsService;

    private static Long currentUserId() {
        String userId = SecurityContextHolder.getContext().getAuthentication().getName();
        return Long.parseLong(userId);
    }

    /**
     * GET /api/stats/summary
     */
    @GetMapping("/summary")
    public ResponseEntity<StatsSummaryDTO> summary() {
        StatsSummaryDTO dto = statsService.getSummary(currentUserId());
        return ResponseEntity.ok(dto);
    }

    /**
     * GET /api/stats/daily?from=2026-04-01&to=2026-04-10
     */
    @GetMapping("/daily")
    public ResponseEntity<?> daily(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        try {
            List<StatsBucketDTO> list = statsService.getDaily(currentUserId(), from, to);
            return ResponseEntity.ok(list);
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.badRequest().body(ex.getMessage());
        }
    }

    /**
     * GET /api/stats/weekly?from=&to=
     */
    @GetMapping("/weekly")
    public ResponseEntity<?> weekly(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        try {
            List<StatsBucketDTO> list = statsService.getWeekly(currentUserId(), from, to);
            return ResponseEntity.ok(list);
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.badRequest().body(ex.getMessage());
        }
    }

    /**
     * GET /api/stats/monthly?from=&to=
     */
    @GetMapping("/monthly")
    public ResponseEntity<?> monthly(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        try {
            List<StatsBucketDTO> list = statsService.getMonthly(currentUserId(), from, to);
            return ResponseEntity.ok(list);
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.badRequest().body(ex.getMessage());
        }
    }
}
