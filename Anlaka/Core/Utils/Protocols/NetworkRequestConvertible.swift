//
//  NetworkRequestConvertible.swift
//  Anlaka
//
//  Created by 최정안 on 5/12/25.
//

import Foundation

protocol NetworkRequestConvertible {
    func asURLRequest() throws -> URLRequest
}
extension UserRouter: NetworkRequestConvertible {}
extension AuthRouter: NetworkRequestConvertible {}
extension EstateRouter: NetworkRequestConvertible {}
extension GeoRouter: NetworkRequestConvertible {}
extension ChatRouter: NetworkRequestConvertible {}
extension AdminRouter: NetworkRequestConvertible {}
extension OrderRouter: NetworkRequestConvertible {}
extension PaymentRouter: NetworkRequestConvertible {}
