package org.gradeedclasses.backend;

import org.springframework.boot.SpringApplication;

public class TestGradeedBackendApplication {

	public static void main(String[] args) {
		SpringApplication.from(GradeedBackendApplication::main).with(TestcontainersConfiguration.class).run(args);
	}

}
