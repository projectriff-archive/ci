package com.example;

import java.util.function.Function;

public class UppercaseFunction implements Function<String, String> {

	public String apply(String input) {
		return input.toUpperCase();
	}

}
