package org.gradeedclasses.backend.attendance.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record StudentRequest(

        @NotBlank(message = "Student name is required")
        @Size(
                max = 60,
                message = "Student name cannot exceed 60 characters"
        )
        String name,

        @Size(
                max = 30,
                message = "ED number cannot exceed 30 characters"
        )
        String edNo

) {
}
