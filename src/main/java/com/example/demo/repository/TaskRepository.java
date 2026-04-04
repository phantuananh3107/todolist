package com.example.demo.repository;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.Priority;
import com.example.demo.entity.Status;
import com.example.demo.entity.Tasks;

@Repository
public interface TaskRepository extends JpaRepository<Tasks, Long> {
    // Tìm kiếm task theo tiêu đề (Phục vụ chức năng Search của Tuấn Anh)
    List<Tasks> findByTitleContainingIgnoreCase(String title);

    // Lấy danh sách task active của một user cụ thể và sắp xếp theo ngày (Sort)
    List<Tasks> findByUserIdAndIsActiveTrueOrderByDueDateAsc(Long userId);

    // Lấy danh sách task của user (không filter active)
    List<Tasks> findByUserIdOrderByDueDateAsc(Long userId);

    // Đếm số task active của một user
    long countByUserIdAndIsActiveTrue(Long userId);

    // Đếm số task của một user (không filter active)
    long countByUserId(Long userId);

    // Kiểm tra trùng tên Task trong cùng một Category
    boolean existsByTitleAndCategoryIdAndIsActiveTrue(String title, Long categoryId);

    // Lấy tất cả task active của một Category
    List<Tasks> findByCategoryIdAndIsActiveTrue(Long categoryId);

    // Lấy tất cả task (active và inactive) của một Category
    List<Tasks> findByCategoryId(Long categoryId);

    // Lấy danh sách task theo trạng thái (Dùng cho AI)
    List<Tasks> findByUserIdAndStatusAndIsActiveTrue(Long userId, Status status);

    // Tìm kiếm task theo tiêu đề cho user cụ thể
    List<Tasks> findByTitleContainingIgnoreCaseAndUserIdAndIsActiveTrue(String title, Long userId);

    // Tìm task theo priority và user
    List<Tasks> findByUserIdAndIsActiveTrueAndPriority(Long userId, Priority priority);

    // Tìm task theo status và user
    List<Tasks> findByUserIdAndIsActiveTrueAndStatus(Long userId, Status status);

    // Lấy danh sách task sắp xếp theo orderIndex (dùng cho chức năng Priority Ordering)
    List<Tasks> findByUserIdAndIsActiveTrueOrderByOrderIndexAscIdAsc(Long userId);

    // Lấy danh sách task sắp xếp theo ID tăng dần (dùng cho danh sách mặc định)
    List<Tasks> findByUserIdAndIsActiveTrueOrderByIdAsc(Long userId);

    // Tìm task theo ID và user (để verify ownership)
    Tasks findByIdAndUserId(Long id, Long userId);

    // Lấy task theo khoảng thời gian dueDate (nửa mở: start <= dueDate < end)
    @Query("""
        select t
        from Tasks t
        where t.user.id = :userId
          and t.isActive = true
          and t.dueDate is not null
          and t.dueDate >= :start
          and t.dueDate < :end
        order by t.dueDate asc
    """)
    List<Tasks> findActiveTasksByUserIdDueDateRange(Long userId, LocalDateTime start, LocalDateTime end);

}