package com.example.demo.service;

import com.example.demo.dto.CreateReminderRequest;
import com.example.demo.dto.ReminderResponseDTO;
import com.example.demo.dto.UpdateReminderRequest;
import com.example.demo.entity.Reminder;
import com.example.demo.entity.Tasks;
import com.example.demo.repository.ReminderRepository;
import com.example.demo.repository.TaskRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class ReminderService {

    @Autowired
    private ReminderRepository reminderRepository;

    @Autowired
    private TaskRepository taskRepository;

    public ResponseEntity<?> createReminder(Long userId, CreateReminderRequest request) {
        if (request == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Thiếu dữ liệu!");
        }
        if (request.getTaskId() == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("taskId không được để trống!");
        }
        if (request.getRemindTime() == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("remindTime không được để trống!");
        }

        Optional<Tasks> taskOpt = taskRepository.findById(request.getTaskId());
        if (taskOpt.isEmpty() || !Boolean.TRUE.equals(taskOpt.get().getIsActive())) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Công việc không tồn tại!");
        }

        Tasks task = taskOpt.get();
        if (task.getUser() == null || !task.getUser().getId().equals(userId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Bạn không có quyền tạo nhắc nhở cho công việc này!");
        }

        Reminder reminder = new Reminder();
        reminder.setTask(task);
        reminder.setRemindTime(request.getRemindTime());

        Reminder saved = reminderRepository.save(reminder);
        return ResponseEntity.status(HttpStatus.CREATED).body(new ReminderResponseDTO(saved));
    }

    public ResponseEntity<?> updateReminder(Long userId, Long reminderId, UpdateReminderRequest request) {
        if (reminderId == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("reminderId không hợp lệ!");
        }
        if (request == null || request.getRemindTime() == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Thiếu remindTime!");
        }

        Optional<Reminder> reminderOpt = reminderRepository.findByIdAndUserId(reminderId, userId);
        if (reminderOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Nhắc nhở không tồn tại!");
        }

        Reminder reminder = reminderOpt.get();
        reminder.setRemindTime(request.getRemindTime());
        Reminder updated = reminderRepository.save(reminder);

        return ResponseEntity.ok(new ReminderResponseDTO(updated));
    }

    public ResponseEntity<?> deleteReminder(Long userId, Long reminderId) {
        if (reminderId == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("reminderId không hợp lệ!");
        }

        Optional<Reminder> reminderOpt = reminderRepository.findByIdAndUserId(reminderId, userId);
        if (reminderOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Nhắc nhở không tồn tại!");
        }

        reminderRepository.deleteById(reminderId);
        return ResponseEntity.ok("Xóa nhắc nhở thành công!");
    }

    public ResponseEntity<?> getRemindersByUser(Long userId) {
        List<Reminder> reminders = reminderRepository.findByUserId(userId);
        List<ReminderResponseDTO> result = reminders.stream()
                .map(ReminderResponseDTO::new)
                .collect(Collectors.toList());
        return ResponseEntity.ok(result);
    }

    public ResponseEntity<?> getUpcomingReminders(Long userId, long minutes) {
        if (minutes <= 0) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("minutes phải > 0!");
        }

        LocalDateTime from = LocalDateTime.now();
        LocalDateTime to = from.plusMinutes(minutes);

        List<Reminder> reminders = reminderRepository.findUpcomingByUserIdAndRemindTimeBetween(userId, from, to);
        List<ReminderResponseDTO> result = reminders.stream()
                .map(ReminderResponseDTO::new)
                .collect(Collectors.toList());

        return ResponseEntity.ok(result);
    }

    public ResponseEntity<?> getRemindersByDate(Long userId, LocalDate date) {
        if (date == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("date không hợp lệ!");
        }

        LocalDateTime from = date.atStartOfDay();
        LocalDateTime to = date.plusDays(1).atStartOfDay();

        List<Reminder> reminders = reminderRepository.findByUserIdAndRemindTimeBetween(userId, from, to);
        List<ReminderResponseDTO> result = reminders.stream()
                .map(ReminderResponseDTO::new)
                .collect(Collectors.toList());

        return ResponseEntity.ok(result);
    }
}

