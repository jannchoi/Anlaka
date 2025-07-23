//
//  JWTDecoder.swift
//  Anlaka
//
//  Created by 최정안 on 5/24/25.
//

import Foundation
struct JWTDecoder {
    static func decodeExpiration(from token: String) -> Int? {
        let segments = token.split(separator: ".")
        guard segments.count > 1 else { return nil }

        let payloadSegment = segments[1]
        var base64 = String(payloadSegment)
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64 += "="
        }

        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exp = json["exp"] as? Int else {
            return nil
        }

        return exp
    }
}
