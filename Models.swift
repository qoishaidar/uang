import Foundation
import SwiftUI

struct Transaction: Identifiable, Codable, Hashable {
    let id: Int?
    var walletId: Int?
    var assetId: Int?
    var fromWalletId: Int?
    var toWalletId: Int?
    var fromAssetId: Int?
    var toAssetId: Int?
    var title: String
    var category: String
    var date: Date
    var amount: Double
    var type: TransactionType
    
    enum TransactionType: String, Codable, Hashable {
        case income
        case expense
        case transfer
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case walletId = "wallet_id"
        case assetId = "asset_id"
        case fromWalletId = "from_wallet_id"
        case toWalletId = "to_wallet_id"
        case fromAssetId = "from_asset_id"
        case toAssetId = "to_asset_id"
        case title
        case category
        case date
        case amount
        case type
    }
}

struct Wallet: Identifiable, Codable, Hashable {
    let id: Int?
    var name: String
    var balance: Double
    var type: String
    var color: String
    var last4: String
    var sortOrder: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case balance
        case type
        case color
        case last4
        case sortOrder = "sort_order"
    }
}

struct Asset: Identifiable, Codable, Hashable {
    let id: Int?
    var name: String
    var symbol: String
    var value: Double
    var change: Double
    var type: String
    var sortOrder: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case symbol
        case value
        case change
        case type
        case sortOrder = "sort_order"
    }
}

struct Category: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var type: TransactionType
    var icon: String
    var group: String?
    var sortOrder: Int?
    
    enum TransactionType: String, Codable, Hashable {
        case income
        case expense
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case icon
        case group
        case sortOrder = "sort_order"
    }
    
    init(id: String, name: String, type: TransactionType, icon: String, group: String? = nil, sortOrder: Int? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.icon = icon
        self.group = group
        self.sortOrder = sortOrder
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        group = try container.decodeIfPresent(String.self, forKey: .group)
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder)
        
        // Robust type decoding
        if let typeString = try? container.decode(String.self, forKey: .type),
           let validType = TransactionType(rawValue: typeString) {
            type = validType
        } else {
            // Default to expense if type is invalid/missing/mismatch
            type = .expense
        }
    }
}
