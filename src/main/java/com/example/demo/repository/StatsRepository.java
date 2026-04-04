package com.example.demo.repository;

import com.example.demo.dto.UserStatsDTO;
import com.example.demo.entity.Tasks;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

@org.springframework.stereotype.Repository
public interface StatsRepository extends Repository<Tasks, Long> {

    @Query(value = """
        SELECT
          COALESCE(SUM(CASE WHEN t.status = 'DONE' THEN 1 ELSE 0 END), 0),
          COALESCE(SUM(CASE WHEN t.status <> 'DONE' THEN 1 ELSE 0 END), 0)
        FROM Tasks t
        WHERE t.user_id = :userId
          AND t.is_active = 1
        """, nativeQuery = true)
    List<Object[]> aggregateSummaryForUser(@Param("userId") Long userId);

    @Query(value = """
        SELECT
          DATE_FORMAT(d.dd, '%Y-%m-%d') AS label,
          d.completed,
          d.not_completed
        FROM (
          SELECT
            DATE(t.created_at) AS dd,
            COALESCE(SUM(CASE WHEN t.status = 'DONE' THEN 1 ELSE 0 END), 0) AS completed,
            COALESCE(SUM(CASE WHEN t.status <> 'DONE' THEN 1 ELSE 0 END), 0) AS not_completed
          FROM Tasks t
          WHERE t.user_id = :userId
            AND t.is_active = 1
            AND (:fromDt IS NULL OR t.created_at >= :fromDt)
            AND (:toDt IS NULL OR t.created_at < :toDt)
          GROUP BY DATE(t.created_at)
        ) d
        ORDER BY d.dd
        """, nativeQuery = true)
    List<Object[]> aggregateDailyForUser(
            @Param("userId") Long userId,
            @Param("fromDt") LocalDateTime fromDt,
            @Param("toDt") LocalDateTime toDt);

    @Query(value = """
        SELECT
          CONCAT(
            FLOOR(YEARWEEK(t.created_at, 3) / 100),
            '-W',
            LPAD(MOD(YEARWEEK(t.created_at, 3), 100), 2, '0')
          ) AS label,
          COALESCE(SUM(CASE WHEN t.status = 'DONE' THEN 1 ELSE 0 END), 0),
          COALESCE(SUM(CASE WHEN t.status <> 'DONE' THEN 1 ELSE 0 END), 0)
        FROM Tasks t
        WHERE t.user_id = :userId
          AND t.is_active = 1
          AND (:fromDt IS NULL OR t.created_at >= :fromDt)
          AND (:toDt IS NULL OR t.created_at < :toDt)
        GROUP BY 1
        ORDER BY MIN(YEARWEEK(t.created_at, 3))
        """, nativeQuery = true)
    List<Object[]> aggregateWeeklyForUser(
            @Param("userId") Long userId,
            @Param("fromDt") LocalDateTime fromDt,
            @Param("toDt") LocalDateTime toDt);

    @Query(value = """
        SELECT
          CONCAT(m.yy, '-', LPAD(m.mm, 2, '0')) AS label,
          m.completed,
          m.not_completed
        FROM (
          SELECT
            YEAR(t.created_at) AS yy,
            MONTH(t.created_at) AS mm,
            COALESCE(SUM(CASE WHEN t.status = 'DONE' THEN 1 ELSE 0 END), 0) AS completed,
            COALESCE(SUM(CASE WHEN t.status <> 'DONE' THEN 1 ELSE 0 END), 0) AS not_completed
          FROM Tasks t
          WHERE t.user_id = :userId
            AND t.is_active = 1
            AND (:fromDt IS NULL OR t.created_at >= :fromDt)
            AND (:toDt IS NULL OR t.created_at < :toDt)
          GROUP BY YEAR(t.created_at), MONTH(t.created_at)
        ) m
        ORDER BY m.yy, m.mm
        """, nativeQuery = true)
    List<Object[]> aggregateMonthlyForUser(
            @Param("userId") Long userId,
            @Param("fromDt") LocalDateTime fromDt,
            @Param("toDt") LocalDateTime toDt);

    @Query("SELECT new com.example.demo.dto.UserStatsDTO(u.username, COUNT(t.id), " +
           "SUM(CASE WHEN t.status = com.example.demo.entity.Status.DONE THEN 1L ELSE 0L END), " +
           "SUM(CASE WHEN t.status != com.example.demo.entity.Status.DONE AND t.id IS NOT NULL THEN 1L ELSE 0L END)) " +
           "FROM User u LEFT JOIN Tasks t ON t.user.id = u.id " +
           "WHERE (u.isDeleted IS NULL OR u.isDeleted = false) " +
           "GROUP BY u.username")
    List<UserStatsDTO> getUserTaskStats();
}