package com.example.demo.repository;

import com.example.demo.entity.Priority;
import com.example.demo.entity.Status;
import com.example.demo.entity.Tasks;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import com.example.demo.entity.Tasks;

/**
 * =======================================
 * TaskRepository - Data Access Layer
 * =======================================
 * 
 * Chức năng:
 * - CRUD Task trong database
 * - Search tasks
 * - Filter & Validation queries
 * - Custom queries cho business logic
 * 
 * Chủ yếu dùng cho:
 * - TaskService (CRUD)
 * - Search (findByTitleContainingIgnoreCase)
 * - Filter (by status, priority, date)
 * - Duplicate validation (existsByTitle...)
 * 
 * @author Phan Tuấn Anh
 * @version 1.0
 */
@Repository
public interface TaskRepository extends JpaRepository<Tasks, Long> {
    
    // ==================== SEARCH ====================
    
    /**
     * Tìm kiếm task theo title (case-insensitive)
     * Dùng cho feature: Tìm kiếm Task
     * 
     * @param title Từ khóa tìm kiếm
     * @return Danh sách tasks chứa title
     */
    // Tìm kiếm task theo tiêu đề (Phục vụ chức năng Search của Tuấn Anh)
    List<Tasks> findByTitleContainingIgnoreCase(String title);

    // ==================== GET TASKS ====================
    
    /**
     * Lấy danh sách task active của user, sắp xếp theo due date
     * Dùng cho: Get all tasks, Filter
     * 
     * @param userId ID của user
     * @return Danh sách tasks sorted by dueDate ASC
     */
    // Lấy danh sách task active của một user cụ thể và sắp xếp theo ngày (Sort)
    List<Tasks> findByUserIdAndIsActiveTrueOrderByDueDateAsc(Long userId);

    /**
     * Lấy danh sách task của user (cả active và inactive)
     * 
     * @param userId ID của user
     * @return Danh sách all tasks
     */
    // Lấy danh sách task của user (không filter active)
    List<Tasks> findByUserIdOrderByDueDateAsc(Long userId);

    // ==================== COUNT ====================
    
    /**
     * Đếm số task active của user
     * 
     * @param userId ID của user
     * @return Số lượng tasks isActive=true
     */
    // Đếm số task active của một user cụ thể
    long countByUserIdAndIsActiveTrue(Long userId);

    /**
     * Đếm tất cả tasks của user (active + inactive)
     * 
     * @param userId ID của user
     * @return Tổng số tasks
     */
    // Đếm số task của một user (không filter active)
    long countByUserId(Long userId);

    // ==================== VALIDATION ====================
    
    /**
     * Kiểm tra trùng title task trong cùng category
     * Business Rule: Không được tạo 2 task trùng tên trong cùng category
     * 
     * @param title Tiêu đề task
     * @param categoryId ID của category
     * @return true nếu có task trùng, false nếu không
     */
    // Kiểm tra trùng tên Task trong cùng một Category
    boolean existsByTitleAndCategoryIdAndIsActiveTrue(String title, Long categoryId);

    // ==================== CATEGORY ====================
    
    /**
     * Lấy danh sách task active trong một category
     * 
     * @param categoryId ID của category
     * @return Danh sách tasks
     */
    // Lấy tất cả task active của một Category
    List<Tasks> findByCategoryIdAndIsActiveTrue(Long categoryId);

    /**
     * Lấy tất cả tasks (active + inactive) của category
     * 
     * @param categoryId ID của category
     * @return Danh sách all tasks
     */
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


    // Lấy task theo khoảng thời gian createdAt (nửa mở: start <= createdAt < end)
    @Query("""
        select t
        from Tasks t
        where t.user.id = :userId
          and t.isActive = true
          and t.createdAt >= :start
          and t.createdAt < :end
        order by t.createdAt asc
    """)
    List<Tasks> findActiveTasksByUserIdCreatedAtRange(Long userId, LocalDateTime start, LocalDateTime end);

}