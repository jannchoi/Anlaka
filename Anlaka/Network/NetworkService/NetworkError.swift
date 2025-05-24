//
//  NetworkError.swift
//  Anlaka
//
//  Created by 최정안 on 5/12/25.
//

import Foundation
enum NetworkError: LocalizedError {
    // 공통 에러
    case disconnected
    case invalidURL
    case timeout
    case unauthorized                      // 401
    case forbidden                         // 403
    case tokenExpired                      // 419
    case invalidAPIKey                     // 420
    case tooManyRequests                   // 429
    case abnormalRequest                   // 444
    case serverError                       // 500+
    
    // 커스텀 에러
    case badRequest(message: String?)      // 400
    case conflict(message: String?)        // 409
    case authError(message: String?)       // Auth 전용
    case unknown(code: Int, message: String?)
    
    var errorDescription: String? {
        switch self {
        case .disconnected:
            return "인터넷 연결이 없습니다."
        case .invalidURL:
            return "잘못된 URL입니다."
        case .timeout:
            return "요청 시간이 초과되었습니다."
        case .unauthorized:
            return "유효하지 않은 토큰입니다."
        case .forbidden:
            return "접근 권한이 없습니다."
        case .tokenExpired:
            return "토큰이 만료되었습니다."
        case .invalidAPIKey:
            return "API 키가 유효하지 않습니다."
        case .tooManyRequests:
            return "요청 횟수가 초과되었습니다. 잠시 후 다시 시도해주세요."
        case .abnormalRequest:
            return "비정상적인 요청입니다."
        case .serverError:
            return "서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요."
        case .badRequest(let message),
             .conflict(let message),
             .authError(let message),
             .unknown(_, let message):
            return message
        }
    }
    
    static func from(code: Int, router: Any) -> NetworkError {
           switch code {
           case 401: return .unauthorized
           case 403: return .forbidden
           case 419: return .tokenExpired
           case 420: return .invalidAPIKey
           case 429: return .tooManyRequests
           case 444: return .abnormalRequest
           case 500...599: return .serverError
               
           case 400:
               switch router {
               case is UserRouter:
                   return .badRequest(message: "필수값을 채워주세요.")
               case is AuthRouter:
                   return .badRequest(message: "잘못된 요청입니다.")
               default:
                   return .badRequest(message: "요청이 잘못되었습니다.")
               }
           case 409:
               switch router {
               case UserRouter.emailValidation:
                   return .conflict(message: "사용이 불가한 이메일입니다.")
               case UserRouter.signUp:
                   return .conflict(message: "이미 가입된 유저입니다.")
               default:
                   return .conflict(message: "중복된 요청입니다.")
               }
           case 418:
               if router is AuthRouter {
                   return .authError(message: "리프레시 토큰이 만료되었습니다. 다시 로그인 해주세요.")
               }
           default:
               break
           }

           return .unknown(code: code, message: "알 수 없는 오류가 발생했습니다. (code: \(code))")
       }
}
