package com.example.demo.service;

import com.example.demo.dto.StatsBucketDTO;
import com.example.demo.dto.StatsSummaryDTO;
import com.example.demo.repository.StatsRepository;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class StatsService {

    @Autowired
    private StatsRepository statsRepository;

    public StatsSummaryDTO getSummary(Long userId) {
        List<Object[]> rows = statsRepository.aggregateSummaryForUser(userId);
        Object[] row = rows.isEmpty() ? new Object[] {0L, 0L} : unwrapNativeTuple(rows.get(0));
        long completed = toLong(row[0]);
        long notCompleted = toLong(row.length > 1 ? row[1] : 0L);
        double rate = completionRate(completed, notCompleted);
        return new StatsSummaryDTO(completed, notCompleted, rate);
    }

    /**
     * Hibernate đôi khi trả về {@code Object[]} một phần tử, phần tử đó lại là hàng {@code Object[]} thực sự.
     */
    private static Object[] unwrapNativeTuple(Object[] raw) {
        if (raw != null && raw.length == 1 && raw[0] instanceof Object[] inner) {
            return inner;
        }
        return raw != null ? raw : new Object[] {0L, 0L};
    }

    public List<StatsBucketDTO> getDaily(Long userId, LocalDate from, LocalDate to) {
        validateRange(from, to);
        Range range = toCreatedAtRange(from, to);
        return mapBuckets(statsRepository.aggregateDailyForUser(userId, range.from(), range.to()));
    }

    public List<StatsBucketDTO> getWeekly(Long userId, LocalDate from, LocalDate to) {
        validateRange(from, to);
        Range range = toCreatedAtRange(from, to);
        return mapBuckets(statsRepository.aggregateWeeklyForUser(userId, range.from(), range.to()));
    }

    public List<StatsBucketDTO> getMonthly(Long userId, LocalDate from, LocalDate to) {
        validateRange(from, to);
        Range range = toCreatedAtRange(from, to);
        return mapBuckets(statsRepository.aggregateMonthlyForUser(userId, range.from(), range.to()));
    }

    private static void validateRange(LocalDate from, LocalDate to) {
        if (from != null && to != null && from.isAfter(to)) {
            throw new IllegalArgumentException("from must not be after to");
        }
    }

    /**
     * Lọc theo created_at: [fromDt, toDt) — to là exclusive (cuối ngày {@code to} vẫn được tính).
     */
    private static Range toCreatedAtRange(LocalDate from, LocalDate to) {
        LocalDateTime fromDt = from != null ? from.atStartOfDay() : null;
        LocalDateTime toDt = to != null ? to.plusDays(1).atStartOfDay() : null;
        return new Range(fromDt, toDt);
    }

    private List<StatsBucketDTO> mapBuckets(List<Object[]> rows) {
        List<StatsBucketDTO> out = new ArrayList<>(rows.size());
        for (Object[] row : rows) {
            Object[] tuple = unwrapNativeTuple(row);
            if (tuple.length < 3) {
                continue;
            }
            out.add(new StatsBucketDTO(
                    tuple[0] != null ? tuple[0].toString() : "",
                    toLong(tuple[1]),
                    toLong(tuple[2])));
        }
        return out;
    }

    private static long toLong(Object value) {
        if (value == null) {
            return 0L;
        }
        if (value instanceof Number n) {
            return n.longValue();
        }
        return Long.parseLong(value.toString());
    }

    private static double completionRate(long completed, long notCompleted) {
        long total = completed + notCompleted;
        if (total == 0) {
            return 0.0;
        }
        return BigDecimal.valueOf(completed)
                .multiply(BigDecimal.valueOf(100))
                .divide(BigDecimal.valueOf(total), 2, RoundingMode.HALF_UP)
                .doubleValue();
    }

    private record Range(LocalDateTime from, LocalDateTime to) {}
}
