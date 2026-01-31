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
    
    init(id: Int? = nil, walletId: Int? = nil, assetId: Int? = nil, fromWalletId: Int? = nil, toWalletId: Int? = nil, fromAssetId: Int? = nil, toAssetId: Int? = nil, title: String, category: String, date: Date, amount: Double, type: TransactionType) {
        self.id = id
        self.walletId = walletId
        self.assetId = assetId
        self.fromWalletId = fromWalletId
        self.toWalletId = toWalletId
        self.fromAssetId = fromAssetId
        self.toAssetId = toAssetId
        self.title = title
        self.category = category
        self.date = date
        self.amount = amount
        self.type = type
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle id as Int or String
        if let idInt = try? container.decode(Int.self, forKey: .id) {
            id = idInt
        } else if let idString = try? container.decode(String.self, forKey: .id), let idInt = Int(idString) {
            id = idInt
        } else {
            id = try? container.decode(Int.self, forKey: .id)
        }
        
        walletId = try container.decodeIfPresent(Int.self, forKey: .walletId)
        assetId = try container.decodeIfPresent(Int.self, forKey: .assetId)
        fromWalletId = try container.decodeIfPresent(Int.self, forKey: .fromWalletId)
        toWalletId = try container.decodeIfPresent(Int.self, forKey: .toWalletId)
        fromAssetId = try container.decodeIfPresent(Int.self, forKey: .fromAssetId)
        toAssetId = try container.decodeIfPresent(Int.self, forKey: .toAssetId)
        title = try container.decode(String.self, forKey: .title)
        category = try container.decode(String.self, forKey: .category)
        date = try container.decode(Date.self, forKey: .date)
        amount = try container.decode(Double.self, forKey: .amount)
        
        // Robust type decoding
        if let typeString = try? container.decode(String.self, forKey: .type) {
            let lowercased = typeString.lowercased()
            if lowercased == "income" {
                type = .income
            } else if lowercased == "transfer" {
                type = .transfer
            } else {
                type = .expense
            }
        } else {
            type = .expense
        }
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

    init(id: Int? = nil, name: String, balance: Double, type: String, color: String, last4: String, sortOrder: Int? = nil) {
        self.id = id
        self.name = name
        self.balance = balance
        self.type = type
        self.color = color
        self.last4 = last4
        self.sortOrder = sortOrder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle id as Int or String
        if let idInt = try? container.decode(Int.self, forKey: .id) {
            id = idInt
        } else if let idString = try? container.decode(String.self, forKey: .id), let idInt = Int(idString) {
            id = idInt
        } else {
            id = try? container.decode(Int.self, forKey: .id)
        }
        
        name = try container.decode(String.self, forKey: .name)
        
        // Handle balance as Double or String
        if let balanceDouble = try? container.decode(Double.self, forKey: .balance) {
            balance = balanceDouble
        } else if let balanceString = try? container.decode(String.self, forKey: .balance), let balanceDouble = Double(balanceString) {
            balance = balanceDouble
        } else {
            balance = 0
        }
        
        type = try container.decode(String.self, forKey: .type)
        color = try container.decode(String.self, forKey: .color)
        last4 = try container.decode(String.self, forKey: .last4)
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder)
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

    init(id: Int? = nil, name: String, symbol: String, value: Double, change: Double, type: String, sortOrder: Int? = nil) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.value = value
        self.change = change
        self.type = type
        self.sortOrder = sortOrder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle id as Int or String
        if let idInt = try? container.decode(Int.self, forKey: .id) {
            id = idInt
        } else if let idString = try? container.decode(String.self, forKey: .id), let idInt = Int(idString) {
            id = idInt
        } else {
            id = try? container.decode(Int.self, forKey: .id)
        }
        
        name = try container.decode(String.self, forKey: .name)
        symbol = try container.decode(String.self, forKey: .symbol)
        
        // Handle value as Double or String
        if let valueDouble = try? container.decode(Double.self, forKey: .value) {
            value = valueDouble
        } else if let valueString = try? container.decode(String.self, forKey: .value), let valueDouble = Double(valueString) {
            value = valueDouble
        } else {
            value = 0
        }
        
        change = (try? container.decode(Double.self, forKey: .change)) ?? 0
        type = try container.decode(String.self, forKey: .type)
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder)
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
        
        // Robust ID decoding (handle Int or String from Supabase)
        if let idString = try? container.decode(String.self, forKey: .id) {
            id = idString
        } else if let idInt = try? container.decode(Int.self, forKey: .id) {
            id = String(idInt)
        } else {
            // If all fails, try normal decoding which will throw a clear error if missing
            id = try container.decode(String.self, forKey: .id)
        }
        
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        group = try container.decodeIfPresent(String.self, forKey: .group)
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder)
        
        // Robust type decoding (case-insensitive and fallback)
        if let typeString = try? container.decode(String.self, forKey: .type) {
            let lowercased = typeString.lowercased()
            if lowercased == "income" {
                type = .income
            } else {
                type = .expense
            }
        } else {
            type = .expense
        }
    }
}
