package org.gradeedclasses.backend.attendance.dto.response;

import java.time.Instant;

public record StudentResponse(
        String id,
        String name,
        String edNo,
        Long overallPointBase,
        Instant lastActivityAt,
        Instant createdAt,
        Instant updatedAt
) {
}