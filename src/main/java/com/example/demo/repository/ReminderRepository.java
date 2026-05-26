package com.example.demo.repository;

import com.example.demo.entity.Reminder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface ReminderRepository extends JpaRepository<Reminder, Long> {

    @Query("""
        select r
        from Reminder r
        where r.id = :reminderId
          and r.task.user.id = :userId
    """)
    Optional<Reminder> findByIdAndUserId(Long reminderId, Long userId);

    @Query("""
        select r
        from Reminder r
        where r.task.user.id = :userId
          and r.task.isActive = true
        order by r.remindTime asc
    """)
    List<Reminder> findByUserId(Long userId);

    @Query("""
        select r
        from Reminder r
        where r.task.user.id = :userId
          and r.task.isActive = true
          and r.remindTime >= :from
          and r.remindTime < :to
        order by r.remindTime asc
    """)
    List<Reminder> findUpcomingByUserIdAndRemindTimeBetween(Long userId, LocalDateTime from, LocalDateTime to);

    @Query("""
        select r
        from Reminder r
        where r.task.user.id = :userId
          and r.task.isActive = true
          and r.remindTime >= :from
          and r.remindTime < :to
        order by r.remindTime asc
    """)
    List<Reminder> findByUserIdAndRemindTimeBetween(Long userId, LocalDateTime from, LocalDateTime to);

    @Query("""
        select r
        from Reminder r
        where r.task.isActive = true
          and r.remindTime <= :now
          and r.notifiedAt is null
        order by r.remindTime asc
    """)
    List<Reminder> findDueReminders(LocalDateTime now);
}

