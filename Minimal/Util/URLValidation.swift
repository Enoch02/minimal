//
//  URLValidationResult.swift
//  Minimal
//
//  Created by Enoch Adesanya on 04/06/2026.
//

import Foundation

enum URLValidationResult: Equatable {
	case valid
	case empty
	case invalidScheme(String?)
	case missingHost
	case invalidHost(String)
	case invalidPath(String)
	case malformed
}

func validateURL(_ string: String) -> URLValidationResult {
	guard !string.isEmpty else { return .empty }
	
	guard let components = URLComponents(string: string) else {
		return .malformed
	}
	
	guard let scheme = components.scheme else {
		return .invalidScheme(nil)
	}
	
	guard ["http", "https"].contains(scheme) else {
		return .invalidScheme(scheme)
	}
	
	guard let host = components.host, !host.isEmpty else {
		return .missingHost
	}
	
	// Check host has at least one dot and a valid TLD
	let hostParts = host.split(separator: ".")
	guard hostParts.count >= 2, hostParts.last!.count >= 2 else {
		return .invalidHost(host)
	}
	
	// Check for illegal characters in path
	let allowedPathCharacters = CharacterSet.urlPathAllowed
	if let path = components.path as String?,
	   !path.isEmpty,
	   path.unicodeScalars.contains(where: { !allowedPathCharacters.contains($0) }) {
		return .invalidPath(path)
	}
	
	return .valid
}

func validationMessage(_ result: URLValidationResult) -> String? {
	switch result {
		case .valid, .empty:
			return nil
		case .malformed:
			return "URL is malformed — check for invalid characters."
		case .invalidScheme(let scheme):
			if let scheme {
				return "'\(scheme)://' is not supported — use http:// or https://."
			} else {
				return "Missing scheme — URL should start with https://."
			}
		case .missingHost:
			return "Missing domain — e.g. https://example.com."
		case .invalidHost(let host):
			return "'\(host)' doesn't look like a valid domain."
		case .invalidPath(let path):
			return "Path '\(path)' contains invalid characters."
	}
}
